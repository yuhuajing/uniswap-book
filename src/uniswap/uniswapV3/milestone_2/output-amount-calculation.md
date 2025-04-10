# 输出金额计算

1. 需要在 `Solidity` 中实现数学运算。
但是，由于 `Solidity` 仅支持整数除法，在 `Solidity` 中实现数学运算会比较困难。
将使用第三方库来完成这部分；
2. 需要让用户能够选择交易的方向，并且池子合约需要支持双向的交易。
3. 最后，需要更新 `UI` 来实现双向的交易以及获取金额的计算。

> 你可以在[ Github branch ](https://github.com/Jeiwan/uniswapv3-code/tree/milestone_2) 找到本章完整代码.

 `Uniswap` 数学公式中还缺最后一个组成部分：计算卖出 `ETH` (即 `token` $x$ )时获得的资产数量。在前一章中，我们有一个类似的公式计算购买 ETH(购买 token $x$)的场景：

$$\Delta \sqrt{P} = \frac{\Delta y}{L}$$

这个公式计算卖出 token $y$ 时的价格变化。我们把这个差价加到现价上面，来得到目标价格：

$$\sqrt{P_{target}} = \sqrt{P_{current}} + \Delta \sqrt{P}$$

现在，我们需要一个类似的公式来计算卖出 token $x$（在本案例中为 ETH）买入 token $y$（在本案例中为 USDC）时的目标价格（在本案例中为卖出 ETH）。

回忆一下，token $x$ 的变化可以用如下方式计算：

$$\Delta x = \Delta \frac{1}{\sqrt{P}}L$$

从上面公式，我们可以推导出目标价格：

$$\Delta x = (\frac{1}{\sqrt{P_{target}}} - \frac{1}{\sqrt{P_{current}}}) L$$
$$= \frac{L}{\sqrt{P_{target}}} - \frac{L}{\sqrt{P_{current}}}$$


$$\\ \sqrt{P_{target}} = \frac{\sqrt{P}L}{\Delta x \sqrt{P} + L}$$

知道了目标价格，我们就能够用前一章类似的方式计算出输出的金额

更新一下对应的 Python 脚本
```python
# Swap ETH for USDC
amount_in = 0.01337 * eth

print(f"\nSelling {amount_in/eth} ETH")

price_next = int((liq * q96 * sqrtp_cur) // (liq * q96 + amount_in * sqrtp_cur))

print("New price:", (price_next / q96) ** 2)
print("New sqrtP:", price_next)
print("New tick:", price_to_tick((price_next / q96) ** 2))

amount_in = calc_amount0(liq, price_next, sqrtp_cur)
amount_out = calc_amount1(liq, price_next, sqrtp_cur)

print("ETH in:", amount_in / eth)
print("USDC out:", amount_out / eth)
```

输出：
```shell
Selling 0.01337 ETH
New price: 4993.777388290041
New sqrtP: 5598789932670289186088059666432
New tick: 85163
ETH in: 0.013369999999998142
USDC out: 66.80838889019013
```

上述结果显示，在之前提供流动性的基础上，卖出 0.01337 ETH 可以获得 66.8 USDC。

这看起来还不错，但是我们已经受够了使用 Python！下面我们将会在 Solidity 中实现所有的数学计算。


## Solidity中的数学运算

由于 `Solidity` 不支持浮点数，在其中的运算会有些复杂。`Solidity`
拥有整数(`integer`)和无符号整数(`unsigned integer`)类型，这并不足够让我们实现复杂的数学运算。

另一个困难之处在于 `gas` 消耗：
一个算法越复杂，它消耗的 gas 就越多。
因此，如果我们需要比较高级的数学运算（例如`exp`, `ln`, `sqrt`），我们会希望它们尽可能节省 `gas`。

还有一个很大的问题是溢出。当进行 `uint256` 类型的乘法时，有溢出的风险：结果的数据可能会超出 `256` 位。

上述这些困难让我们不得不选择使用那些实现了高级数学运算并进行了gas优化的第三方库。

### 重用数学库

在 `UniswapV3` 实现中，我们会使用两个第三方数学库：
1. [PRBMath](https://github.com/paulrberg/prb-math)，一个包含了复杂的定点数运算的库。我们会使用其中的` mulDiv` 函数来处理乘除法过程中可能的溢出
2. [TickMath](https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)，来自原始的 Uniswap V3 仓库。这个合约实现了两个函数，`getSqrtRatioAtTick` 和 `getTickAtSqrtRatio`，功能是在 tick 和 $\sqrt{P}$ 之间相互转换。

我们先关注第二个库。在我们的合约中，我们需要将 `tick` 转换成对应的 $\sqrt{P}$，或者反过来。对应的公式为：

$$P(i) = 1.0001^i $$

$$i = log_{1.0001}P(i)$$

这些是非常复杂的数学运算（至少在 `Solidity` 中是这样）并且它们需要很高的精度，因为我们不希望取整的问题干扰我们的价格计算。为了能实现更高的精度和 gas 优化，我们需要采用特定的实现。

[getSqrtRatioAtTick](https://github.com/Uniswap/v3-core/blob/8f3e4645a08850d2335ead3d1a8d0c64fa44f222/contracts/libraries/TickMath.sol#L23-L54) 和 [getTickAtSqrtRatio](https://github.com/Uniswap/v3-core/blob/8f3e4645a08850d2335ead3d1a8d0c64fa44f222/contracts/libraries/TickMath.sol#L61-L204) 的代码：
其中有大量的 `magic number`（像 `0xfffcb933bd6fad37aa2d162d1a594001`）