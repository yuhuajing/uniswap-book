# 多池子交易
在实现了跨 tick 交易之后，已经十分接近真实的 Uniswap V3 交易了。

目前的实现中一个非常重要的限制在于，仅仅允许在同一个池子里的交易——如果某一对 token 没有池子，我们就不能在这两个 token 之间进行交易。在 Uniswap 中并不是如此，因为它允许多池子交易。在这章中，我们将在我们的实现中添加多池子交易的功能。

计划如下：
1. 首先，学习并实现工厂合约；
2. 接下来，将探究链式交易，或者叫做多池子交易如何工作，并实现 Path 库；
4. 将会实现一个基本的路由，来寻找到两个 token 之间的路径；
5. 在上述过程中，也会学到关于 tick 间隔的知识，一种优化交易的方式。

## 完整合约代码
- [V3Factory](./contracts/UniswapV3Factory.sol)
- [V3Manager](./contracts/UniswapV3Manager.sol)
- [V3Pool](./contracts/UniswapV3Pool.sol)
- [Quoter](./contracts/UniswapV3Quoter.sol)
- [Lib]()
    - [BitMath](./contracts/lib/BitMath.sol)
    - [BytesKib](./contracts/lib/BytesLib.sol)
    - [FixedPoint](./contracts/lib/FixedPoint96.sol)
    - [LiquidityMath](./contracts/lib/LiquidityMath.sol)
    - [Math](./contracts/lib/Math.sol)
    - [Path](./contracts/lib/Path.sol)
    - [PoolAddress](./contracts/lib/PoolAddress.sol)
    - [Position](./contracts/lib/Position.sol)
    - [PrbMath](./contracts/lib/PRBMath.sol)
    - [SwapMath](./contracts/lib/SwapMath.sol)
    - [Tick](./contracts/lib/Tick.sol)
    - [TickBitMap](./contracts/lib/TickBitmap.sol)
    - [TickMath](./contracts/lib/TickMath.sol)
- [Interface]()
    - [FlashLoanCall](./contracts/interfaces/IUniswapV3FlashCallback.sol)
    - [Manager](./contracts/interfaces/IUniswapV3Manager.sol)
    - [MintCall](./contracts/interfaces/IUniswapV3MintCallback.sol)
    - [SwapCall](./contracts/interfaces/IUniswapV3SwapCallback.sol)
    - [Pool](./contracts/interfaces/IUniswapV3Pool.sol)
    - [Deployer](./contracts/interfaces/IUniswapV3PoolDeployer.sol)