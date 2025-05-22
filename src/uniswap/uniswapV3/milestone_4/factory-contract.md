# 工厂合约

`Uniswap` 由多个离散的池子合约构成，每个池子负责一对 `token` 的交易。

然而，仍然可以进行中间交易：
- 第一笔交易把一种 token 转换成另一种有交易对的 token
- 然后再把这种 token 转换成目标 token

**_这个路径可以更长并且有更多种的中间 token_**

*工厂(`Factory`)*合约是一个拥有以下功能的合约：
1. 它作为池子合约的中心化注册点。在工厂中，你可以找到所有已部署的池子，对应的 `token` 和地址。
2. 它简化了池子合约的部署流程。EVM允许在智能合约中部署智能合约——工厂合约使用这个性质来让池子合约的部署变得十分简单。
3. 它让池子合约的地址可预测，并且能够在注册池子之前就计算出这个地址。这让池子更容易被发现。

## Tick 间隔
回顾一下我们在 `swap` 函数中的循环：
```solidity
while (
    state.amountSpecifiedRemaining > 0 &&
    state.sqrtPriceX96 != sqrtPriceLimitX96
) {
    ...
    (step.nextTick, ) = tickBitmap.nextInitializedTickWithinOneWord(...);
    (state.sqrtPriceX96, step.amountIn, step.amountOut) = SwapMath.computeSwapStep(...);
    ...
}
```
这个循环通过在一个方向上遍历来寻找拥有流动性的已初始化的 tick。
- 如果一个有流动性的 `tick` 离得很远，代码将会经过两个 `tick` 之间的所有 `tick`，十分消耗 `gas`
- 为了让循环更节约 `gas`，`Uniswap` 的池子有一个叫做 `tickSpacing` 的参数设定
- 正如其名字所示，代表两个 `tick` 之间的距离——距离越大，越节省 gas,同时价格区间越大

然而，**_tick 间隔越大，精度越低_**。
- 价格波动性低的交易对（例如两种稳定币的池子）需要更高的精度，因为在这样的池子中价格移动很小；
- 价格波动性中等和较高的交易对可以有更低的精度，因为在这样的交易对中价格移动会很大。
- 为了处理这样的多样性，`Uniswap` 允许在交易对创建时设定一个 `tick` 间隔。
  - `Uniswap` 允许部署者在下列选项中选择：`10，60，200`, `tick_index` 只能够是 `tickSpacing` 的整数倍
  
因此，一个池子可以由以下参数唯一确定：
```solidity
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        TickSpacingExtraInfo memory info = feeAmountTickSpacingExtraInfo[fee];
        require(tickSpacing != 0 && info.enabled, "fee is not available yet");
        if (info.whitelistRequested) {
            require(_whiteListAddresses[msg.sender], "user should be in the white list for this fee tier");
        }
        require(getPool[token0][token1][fee] == address(0));
        pool = IPancakeV3PoolDeployer(poolDeployer).deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }
```

> 可以有 token 相同但是 `tickSpacing|Fee` 不同的池子存在。

`Factory` 合约 `call Deploy` 合约使用这组参数来作为池子的唯一定位，并且把他们作为 `salt` 来产生池子合约地址。

```solidity
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) external override onlyFactory returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = address(new PancakeV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());
        delete parameters;
    }
```

这段代码看起来很奇怪，因为 `parameters` 在 `Deploy` 合约中并没有用到

`Uniswap Pool` 的构造函数中需要读取该参数，因此这些参数在被使用 `new` 关键字部署的时候，`Pool` 合约会返调 `Deploy` 合约的参数

```solidity
    constructor() {
        int24 _tickSpacing;
        (factory, token0, token1, fee, _tickSpacing) = IPancakeV3PoolDeployer(msg.sender).parameters();
        tickSpacing = _tickSpacing;

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
    }
```

## 池子初始化

正如上面代码所示，不再在池子的构造函数中设置当前价格`sqrtPriceX96` 和 `tick`

而是在在另一个函数 `initialize` 中完成，这个函数在池子部署后调用：

```solidity
// src/UniswapV3Pool.sol
function initialize(uint160 sqrtPriceX96) public {
    if (slot0.sqrtPriceX96 != 0) revert AlreadyInitialized();

    int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

    slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});
}
```

这是我们现在部署池子的方式：

```solidity
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        require(token0 < token1);
        pool = IPancakeV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            pool = IPancakeV3Factory(factory).createPool(token0, token1, fee);
            IPancakeV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IPancakeV3Pool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                IPancakeV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
```
