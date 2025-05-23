# 关于定点数的拓展

在这个额外章节，我们将会展示在 `Solidity` 中如何将价格转换成 `tick`。
我们不会在主要合约中实现这部分，但是在测试合约中有这样的函数会很有帮助，
这样我们就不需要把 `tick` 硬编码进代码，并且可以写类似 `tick(5000)` 这样的代码——来使得代码的可读性更强，
因为价格比 `tick` 对于读者更直观。

回忆一下，为了找到 `tick`，我们使用 `TickMath.getTickAtSqrtRatio` 函数，
把 $\sqrt{P}$ 作为参数，这里的 $\sqrt{P}$ 是一个 Q64.96 定点数。

问题主要在于，`Solidity` 不支持开根号运算，这意味着我们需要第三方库来解决这个问题。

另一个问题是价格通常来说都是比较小的数，比如10，5000，0.01等等，我们不希望在求根号时失去太多的精度。

或许你还记得我们在前面章节中用到了 `PRBMath` 库来实现乘法和除法的操作，来避免溢出。如果你看一下 `PRBMath.sol` 合约，你会发现其中有 `sqrt` 函数。然而正如注释中所说，这个函数并不支持定点数。你可以尝试一下，求`PRBMath.sqrt(5000)` 的结果是 `70`，这事一个整数并且失去了很大精度。

如果你查看 [prb-math](https://github.com/paulrberg/prb-math) 仓库，你会看到这些合约：`PRBMathSD59x18.sol` 和 `PRBMathUD60x18.sol`。这些正是定点数相关的运算！我们来选择后者看一看它运行情况如何：`PRBMathUD60x18.sqrt(5000 * PRBMathUD60x18.SCALE)` 返回 `70710678118654752440`。这看起来很有趣！`PRBMathUD60x18` 是一个实现了小数部分有18个十进制位的定点数运算的库。所以我们实际上得到的数值是70.710678118654752440（使用 `cast --from-wei 70710678118654752440`）。

然而，我们并不能直接使用这个数！

有很多种不同种类的定点数的实现方式。在 Uniswap V3 中使用的 Q64.96 定点数是一个**二进制**数字——分别是指64位和96位的*二进制位*。而 `PRBMathUD60x18` 实现的是基于*十进制*的定点数（UD值得就是 "unsigned, decimal"，即无符号十进制），其中的60和18都是指的*十进制位*。这两者的区别非常大。

让我们看一下我们如何把任意一个数字（例如42）转换成上述的两种定点数：
1. Q64.96: $42 * 2^{96}$ 或者使用左移运算， `2 << 96`。结果为 3327582825599102178928845914112.
2. UD60.18: $42 * 10^{18}$。结果是 42000000000000000000.

再看一下如何转换带小数部分的数字（42.1337）：
1. Q64.96: $421337 * 2^{92}$ 或者 `421337 << 92`。结果是 2086359769329537075540689212669952.
2. UD60.18: $421337 * 10^{14}$ 结果是 42133700000000000000.

第二个变量对我们来说更清晰，因为它使用的是十进制表示。第一个用的是二进制所以对我们来说读起来更困难。

但是实际上，最大的问题在于我们很难在这两种定点数之间进行转换。

这些原因都决定了我们需要一个不同的库，一个实现了二进制定点数运算和开根号函数的库。幸运地是，的确有这样的库：[abdk-libraries-solidity](https://github.com/abdk-consulting/abdk-libraries-solidity)。这个库实现了 Q64.64，并完全和我们的需求相符（小数部分不是 96 位）但是这个问题不大。

这里我们可以使用这个新的库来实现价格到 tick 的转换函数：

```solidity
function tick(uint256 price) internal pure returns (int24 tick_) {
    tick_ = TickMath.getTickAtSqrtRatio(
        uint160(
            int160(
                ABDKMath64x64.sqrt(int128(int256(price << 64))) <<
                    (FixedPoint96.RESOLUTION - 64)
            )
        )
    );
}
```

`ABDKMath64x64.sqrt` 用一个 Q64.64 的数字作为参数，所以我们需要把 `price` 转换成对应格式。由于价格没有小数部分，我们直接左移64位并转换类型，完成到 Q64.64 的转换；`sqrt` 函数的返回值也是 Q64.64 类型，但是 `TickMath.getTickAtSqrtRatio` 的参数为 Q64.96 类型——因此我们还需要把结果左移 `96 - 64` 位来进行这个转换。
