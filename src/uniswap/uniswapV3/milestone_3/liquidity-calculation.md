# 流动性计算

在 `UniswapV3` 的所有数学公式中，只剩流动性计算我们还没在 Solidity 里面实现。在 Python 脚本中我们有这两个函数：

```python
def liquidity0(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (amount * (pa * pb) / q96) / (pb - pa)


def liquidity1(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return amount * q96 / (pb - pa)
```

接下来我们在 Solidity 中实现这个计算，以便于在 `Manager.mint()` 中使用。

## 实现 Token X 的流动性计算

我们要实现的函数是在已知 token 数量和价格区间的情况下计算流动性（$L = \sqrt{xy}$）。我们之前已经知道了所有相关的公式，让我们回顾一下：

$$\Delta x = \Delta \frac{1}{\sqrt{P}}L$$

在上一章，我们使用这个函数来计算交易数量（这里的 $\Delta x$），现在我们用它来计算 $L$：

$$L = \frac{\Delta x}{\Delta \frac{1}{\sqrt{P}}}$$

简化之后：
$$L = \frac{\Delta x \sqrt{P_u} \sqrt{P_l}}{\sqrt{P_u} - \sqrt{P_l}}$$

在 Solidity 中，我们仍然使用 `PRBMath` 来处理乘除过程中可能出现的溢出：

```solidity
function getLiquidityForAmount0(
    uint160 sqrtPriceAX96,
    uint160 sqrtPriceBX96,
    uint256 amount0
) internal pure returns (uint128 liquidity) {
    if (sqrtPriceAX96 > sqrtPriceBX96)
        (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

    uint256 intermediate = PRBMath.mulDiv(
        sqrtPriceAX96,
        sqrtPriceBX96,
        FixedPoint96.Q96
    );
    liquidity = uint128(
        PRBMath.mulDiv(amount0, intermediate, sqrtPriceBX96 - sqrtPriceAX96)
    );
}
```

## 实现 Token Y 的流动性计算

类似得，我们将使用[计算流动性](https://y1cunhui.github.io/uniswapV3-book-zh-cn/docs/milestone_1/calculating-liquidity/#liquidity-amount-calculation)中出现的另一个公式来在给定 $y$ 的数量和价格区间的前提下计算流动性：

$$\Delta y = \Delta\sqrt{P} L$$
$$L = \frac{\Delta y}{\sqrt{P_u}-\sqrt{P_l}}$$

```solidity
function getLiquidityForAmount1(
    uint160 sqrtPriceAX96,
    uint160 sqrtPriceBX96,
    uint256 amount1
) internal pure returns (uint128 liquidity) {
    if (sqrtPriceAX96 > sqrtPriceBX96)
        (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

    liquidity = uint128(
        PRBMath.mulDiv(
            amount1,
            FixedPoint96.Q96,
            sqrtPriceBX96 - sqrtPriceAX96
        )
    );
}
```

希望这些代码足够清晰易懂。

## 找到公平的流动性

你可能会问为什么我们有两种方式来计算 $L$，但是我们实际上只有一个 $L$，即 $L = \sqrt{xy}$，究竟哪种方法是正确的？答案是：两种方法都是正确的。

在上面的公式中，我们基于不同的参数来计算$L$：价格区间和其中某种 token 的数量。不同的价格区间和不同的 token 数量会导致不同的 $L$。有一个场景是我们需要计算两个$L$并且从中挑选出一个的，回顾一下之前的 `mint` 函数：

```solidity
if (slot0_.tick < lowerTick) {
    amount0 = Math.calcAmount0Delta(...);
} else if (slot0_.tick < upperTick) {
    amount0 = Math.calcAmount0Delta(...);

    amount1 = Math.calcAmount1Delta(...);

    liquidity = LiquidityMath.addLiquidity(liquidity, int128(amount));
} else {
    amount1 = Math.calcAmount1Delta(...);
}
```

在计算流动性时有如下逻辑：
1. 如果我们在一个低于现价的价格区间计算流动性，我们使用 $\Delta y$ 版本的公式；
2. 如果我们在一个高于现价的价格区间计算流动性，我们使用 $\Delta x$ 版本的公式；
3. 如果现价在价格区间内，我们两个都计算并且挑选较小的一个。

> 同样，这些也在[计算流动性](https://y1cunhui.github.io/uniswapV3-book-zh-cn/docs/milestone_1/calculating-liquidity/#liquidity-amount-calculation)一章中讨论过。

我们现在来实现其中的逻辑。
当现价低于价格区间下界时：

```solidity
function getLiquidityForAmounts(
    uint160 sqrtPriceX96,
    uint160 sqrtPriceAX96,
    uint160 sqrtPriceBX96,
    uint256 amount0,
    uint256 amount1
) internal pure returns (uint128 liquidity) {
    if (sqrtPriceAX96 > sqrtPriceBX96)
        (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

    if (sqrtPriceX96 <= sqrtPriceAX96) {
        liquidity = getLiquidityForAmount0(
            sqrtPriceAX96,
            sqrtPriceBX96,
            amount0
        );
```

当现价位于价格区间中，我们挑选较小的一个：
```solidity
} else if (sqrtPriceX96 <= sqrtPriceBX96) {
    uint128 liquidity0 = getLiquidityForAmount0(
        sqrtPriceX96,
        sqrtPriceBX96,
        amount0
    );
    uint128 liquidity1 = getLiquidityForAmount1(
        sqrtPriceAX96,
        sqrtPriceX96,
        amount1
    );

    liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
```

最后一种情况：
```solidity
} else {
    liquidity = getLiquidityForAmount1(
        sqrtPriceAX96,
        sqrtPriceBX96,
        amount1
    );
}
```

## 添加流动性中的滑点保护

添加流动性同样也需要滑点保护。由于在添加流动性时价格不能改变（流动性必须与现价成比例），`LP` 也会遭受到滑点。

然而与 `swap` 函数不同的是，我们并不需要在池子合约中实现 `mint` 的滑点保护——因为池子合约是核心合约之一，我们并不想在其中加入过多无关的逻辑。这也是我们创建管理合约的原因，而添加流动性的滑点保护是在管理合约中实现的。

管理合约是一个对于核心功能进行包装的合约，使得对于池子合约的调用更加便利。为了在 `mint` 函数中实现滑点保护，我们仅需要比较池子实际放入的 token 数量与用户选择的最低数量即可。另外，我们也可以免除用户对于 $\sqrt{P_{lower}}$ 和 $\sqrt{P_{upper}}$ 的计算，在 `Manager.mint()` 中计算它们。

更新后的 `mint` 函数参数更多，我们包装在一个结构体中：

```solidity
// src/UniswapV3Manager.sol
contract UniswapV3Manager {
    struct MintParams {
        address poolAddress;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    function mint(MintParams calldata params)
        public
        returns (uint256 amount0, uint256 amount1)
    {
        ...
```

`amount0Min` 和 `amount1Min` 是通过滑点计算出的边界值。它们必须比 desired 值小，其中的差值即为滑点。LP 希望提供的 token 数量不少于 `amount0Min` 和 `amount1Min`。

接下来，我们计算 $\sqrt{P_{lower}}$，$\sqrt{P_{upper}}$ 和流动性：

```solidity
...
IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);

(uint160 sqrtPriceX96, ) = pool.slot0();
uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(
    params.lowerTick
);
uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(
    params.upperTick
);

uint128 liquidity = LiquidityMath.getLiquidityForAmounts(
    sqrtPriceX96,
    sqrtPriceLowerX96,
    sqrtPriceUpperX96,
    params.amount0Desired,
    params.amount1Desired
);
...
```

`LiquidityMath.getLiquidityForAmounts` 是一个新的函数，我们会在下一章讨论。

下一步就是在池子中添加流动性，并检查返回值：如果数量太少，就 revert：

```solidity
(amount0, amount1) = pool.mint(
    msg.sender,
    params.lowerTick,
    params.upperTick,
    liquidity,
    abi.encode(
        IUniswapV3Pool.CallbackData({
            token0: pool.token0(),
            token1: pool.token1(),
            payer: msg.sender
        })
    )
);

if (amount0 < params.amount0Min || amount1 < params.amount1Min)
    revert SlippageCheckFailed(amount0, amount1);
```
