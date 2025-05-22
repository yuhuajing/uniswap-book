# 费率和价格预言机
本章添加交易费率(`swap fees`) 和一个价格预言机(`price oracle`)：
- 交易费率是我们实现的 DEX 中一个关键的机制。它能够使一切事情联合起来共同运作。交易费率能够激励 LP 提供流动性，没有流动性就无法进行交易。
- 一个价格预言机，这只是 DEX 的一个可选功能。一个 DEX 除了能够执行交易之外，也能够作为一个价格预言机——向其他服务提供 token 的价格。这实际上并不影响我们交易的执行，但是它对于其他链上应用来说是一个很有用的服务。

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
    - [Oracle](./contracts/lib/Oracle.sol)
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