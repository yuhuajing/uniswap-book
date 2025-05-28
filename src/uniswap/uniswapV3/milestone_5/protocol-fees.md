# 协议费率
“Uniswap 如何盈利？”。事实上，它并不盈利（至少到 2022 年 9 月为止还没有）。

在已经完成的实现中，`swap` 会给 `LP` 支付一定手续费

每个 `Uniswap` 池子都有一个*协议费率*的机制。

协议费用从交易费用中收取：一小部分的交易费用会被用来作为协议的费用，之后会被工厂合约的所有者（ Uniswap Labs ）提取。

协议费率的大小是由 `UNI` 币的持有者来决定的，但是它必须在交易费率的 $1/4$ 到 $1/10$（包含） 之间。

协议费率大小存储在 `slot0` 中：

```solidity
// UniswapV3Pool.sol
struct Slot0 {
    ...
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    ...
}
```

需要一个全局变量来追踪已经获得的协议收入：
```solidity
    function initialize(uint160 sqrtPriceX96) external override {
        require(slot0.sqrtPriceX96 == 0, 'AI');

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 209718400, // default value for all pools, 3200:3200, store 2 uint32 inside
            unlocked: true
        });

        if (fee == 100) {
            slot0.feeProtocol = 216272100; // value for 3300:3300, store 2 uint32 inside
        } else if (fee == 500) {
            slot0.feeProtocol = 222825800; // value for 3400:3400, store 2 uint32 inside
        } else if (fee == 2500) {
            slot0.feeProtocol = 209718400; // value for 3200:3200, store 2 uint32 inside
        } else if (fee == 10000) {
            slot0.feeProtocol = 209718400; // value for 3200:3200, store 2 uint32 inside
        }

        emit Initialize(sqrtPriceX96, tick);
    }
```

协议费率在 `setFeeProtocol` 函数中设置：

```solidity
    function setFeeProtocol(uint32 feeProtocol0, uint32 feeProtocol1) external override lock onlyFactoryOrFactoryOwner {
        require(
            (feeProtocol0 == 0 || (feeProtocol0 >= 1000 && feeProtocol0 <= 4000)) &&
            (feeProtocol1 == 0 || (feeProtocol1 >= 1000 && feeProtocol1 <= 4000))
        );

        uint32 feeProtocolOld = slot0.feeProtocol;
        slot0.feeProtocol = feeProtocol0 + (feeProtocol1 << 16);
        emit SetFeeProtocol(feeProtocolOld % PROTOCOL_FEE_SP, feeProtocolOld >> 16, feeProtocol0, feeProtocol1);
    }
```

最后，工厂合约的拥有者可以通过调用 `collectProtocol` 来收集累积的协议费用：

```solidity
function collectProtocol(
    address recipient,
    uint128 amount0Requested,
    uint128 amount1Requested
) external override lock onlyFactoryOwner returns (uint128 amount0, uint128 amount1) {
    amount0 = amount0Requested > protocolFees.token0 ? protocolFees.token0 : amount0Requested;
    amount1 = amount1Requested > protocolFees.token1 ? protocolFees.token1 : amount1Requested;

    if (amount0 > 0) {
        if (amount0 == protocolFees.token0) amount0--;
        protocolFees.token0 -= amount0;
        TransferHelper.safeTransfer(token0, recipient, amount0);
    }
    if (amount1 > 0) {
        if (amount1 == protocolFees.token1) amount1--;
        protocolFees.token1 -= amount1;
        TransferHelper.safeTransfer(token1, recipient, amount1);
    }

    emit CollectProtocol(msg.sender, recipient, amount0, amount1);
}
```