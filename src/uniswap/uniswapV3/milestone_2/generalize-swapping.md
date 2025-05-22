# 通用 swap
一笔交易可以看作是满足一个订单：

一个用户提交了一个订单，需要从池子中购买一定数量的某种 `token`。

池子会使用可用的流动性来将投入的 `token0` 数量“转换”成输出的 `token1` 数量。

如果在当前价格区间中没有足够的流动性，它将会尝试在其他价格区间中寻找流动性。

现在，我们要实现 `swap` 函数内部的逻辑，

但仍然保证交易可以在当前价格区间内完成——跨 `tick` 的交易将会在下一个 `milestone` 中实现。

```solidity
function swap(
    address recipient,
    bool zeroForOne,
    uint256 amountSpecified,
    bytes calldata data
) public returns (int256 amount0, int256 amount1) {
    ...
```

在 `swap` 函数中，我们新增了两个参数：`zeroForOne` 和 `amountSpecified`。

`zeroForOne` 是用来控制交易方向的 `flag`：
 - `true`，表示卖出 `Token0`， 用 `token0` 兑换 `token1`；
 - `false` 则相反。

`amountSpecified` 是用户希望兑换到的 `token` 数量。

## 完成兑换订单
由于在 `UniswapV3` 中，流动性存储在不同的价格区间中，池子合约需要找到“填满当前订单”所需要的所有流动性。
这个操作是通过沿着某个方向遍历所有初始化的 `tick` 来实现的。

在继续之前，我们需要定义两个新的结构体：

```solidity
struct SwapState {
    uint256 amountSpecifiedRemaining;
    uint256 amountCalculated;
    uint160 sqrtPriceX96;
    int24 tick;
}

struct StepState {
    uint160 sqrtPriceStartX96;
    int24 nextTick;
    uint160 sqrtPriceNextX96;
    uint256 amountIn;
    uint256 amountOut;
}
```

`SwapState` 维护了当前 swap 的状态。
- `amoutSpecifiedRemaining` 跟踪了还需要从池子中获取的 `token` 数量：当这个数量为 0 时，这笔订单就被填满了。
- `amountCalculated` 是由合约计算出的输出数量。
- `sqrtPriceX96` 和 `tick` 是交易结束后的价格和 `tick`。

`StepState` 维护了当前交易“一步”的状态。这个结构体跟踪“填满订单”过程中**一个循环**的状态。
- `sqrtPriceStartX96` 跟踪循环开始时的价格。
- `nextTick` 是能够为交易提供流动性的下一个已初始化的`tick`， 
- `sqrtPriceNextX96` 是下一个 `tick` 的价格。
- `amountIn` 和 `amountOut` 是当前循环中流动性能够提供的数量。

> 在我们实现跨 tick 的交易后（也即不发生在一个价格区间中的交易），关于循环方面会有更清晰的了解。

```solidity
        Slot0 memory slot0_ = slot0;

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: slot0_.sqrtPriceX96,
            tick: slot0_.tick
        });
```

在填满一个订单之前，我们首先获取当前池子中的价格和tick Index， 然后初始化 `SwapState` 的实例。

我们将会循环直到 `amoutSpecified == 0`，也即池子拥有足够的流动性来买用户的 `amountSpecified` 数量的token。

```solidity
        while (state.amountSpecifiedRemaining > 0) {
            .....
        }
```
### 计算兑换的价格区间
#### 初始化 step 变量
在循环中，每次初始化新的 step 变量
- `sqrtPriceStartX96`
  - 第一次循环的值为当前池子内部的价格
  - 之后的每次循环，该值都是执行完当前一定数量代币 `swap` 后的价格
- `nextTick`
  - 根据循环外的 `state` 变量记录的 `Tick_Index` 和方向寻找到的下一个有流动性代币的 `Tick_Index`
- `sqrtPriceNextX96`
  - `nextTick` 对应的价格
- `amountIn`， `amountOut` 
  - 按照 当前的流动性 和 `sqrtPriceStartX96 ~ sqrtPriceNextX96`价格区间，计算得出的最大可 swap 的代币数量
    - 大于等于当前需要的代币数量的话，按照实际兑换数量计算新的价格
    - 小于的话，在当前区间内执行部分兑换并更新 `tick = nextTick，sqrtPriceStartX96 = sqrtPriceNextX96`，进入下一个循环

```solidity
        while (state.amountSpecifiedRemaining > 0) {
            StepState memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.nextTick, ) = tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                1,
                zeroForOne
            );

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.nextTick);

            (state.sqrtPriceX96, step.amountIn, step.amountOut) = SwapMath
                .computeSwapStep(
                    step.sqrtPriceStartX96,
                    step.sqrtPriceNextX96,
                    liquidity,
                    state.amountSpecifiedRemaining
                );
```

#### SwapMath.computeSwapStep 合约

**_本章介绍的是在同一个价格区间内可以完成的兑换，不考虑进入下次循环。_**

首先根据输入的代币数量和当前池子的价格计算出兑换后的最新价格：
计算公式：

$$\sqrt{P_{target}} = \frac{\sqrt{P}L}{\Delta x \sqrt{P} + L}$$

当它可能产生溢出时，我们使用另一个替代的公式，精确度会更低但是不会溢出：

$$\sqrt{P_{target}} = \frac{L}{\Delta x + \frac{L}{\sqrt{P}}}$$

$$\\ \sqrt{P_{target}} = \frac{\Delta y}{L } + \sqrt{P}$$
```solidity
    function computeSwapStep(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceTargetX96,
        uint128 liquidity,
        uint256 amountRemaining
    )
        internal
        pure
        returns (
            uint160 sqrtPriceNextX96,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;

        sqrtPriceNextX96 = Math.getNextSqrtPriceFromInput(
            sqrtPriceCurrentX96,
            liquidity,
            amountRemaining,
            zeroForOne
        );
```
根据  `sqrtPriceCurrentX96 ~ sqrtPriceNextX96` 计算代币对的预期输入和输出数量

计算公式：

$$\Delta x = \Delta \frac{1}{\sqrt{P}}L$$

$$\Delta y = \Delta {\sqrt{P}} L$$

```solidity
amountIn = Math.calcAmount0Delta(
    sqrtPriceCurrentX96,
    sqrtPriceNextX96,
    liquidity
);
amountOut = Math.calcAmount1Delta(
    sqrtPriceCurrentX96,
    sqrtPriceNextX96,
    liquidity
);
```

#### 更新 state变量
```solidity
if (state.tick != slot0_.tick) {
            (slot0.sqrtPriceX96, slot0.tick) = (state.sqrtPriceX96, state.tick);
        }

        (amount0, amount1) = zeroForOne
            ? (
                int256(amountSpecified - state.amountSpecifiedRemaining),
                -int256(state.amountCalculated)
            )
            : (
                -int256(state.amountCalculated),
                int256(amountSpecified - state.amountSpecifiedRemaining)
            );
```
#### 执行兑换
到目前为止，已经能够沿着下一个初始化过的tick进行循环;

填满用户指定的 `amoutSpecified`、计算输入和输出数量，
并且找到新的价格和 tick。

根据交易方向与用户交换 `token`
- 先将一定数量的目标代币转到接收地址
- 收取一定数量的输入代币，通过 `IUniswapV3SwapCallback` 实现

```solidity
        if (zeroForOne) {
            ERC20(token1).transfer(recipient, uint256(-amount1));

            uint256 balance0Before = balance0();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
                amount0,
                amount1,
                data
            );
            if (balance0Before + uint256(amount0) > balance0())
                revert InsufficientInputAmount();
        } else {
            ERC20(token0).transfer(recipient, uint256(-amount0));

            uint256 balance1Before = balance1();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
                amount0,
                amount1,
                data
            );
            if (balance1Before + uint256(amount1) > balance1())
                revert InsufficientInputAmount();
        }
```
