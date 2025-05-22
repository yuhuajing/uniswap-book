# 跨tick交易

在这个milestone中，会：
1. 更新 `mint` 函数，使得能够在不同的价格区间提供流动性；
2. 更新 `swap` 函数，使得在当前价格区间流动性不足时能够跨价格区间交易；
3. 学习如何在智能合约中计算流动性；
4. 在 `mint` 和 `swap` 函数中实现滑点控制；
5. 增加对于定点数运算的一些了解。
6. 
## 完整合约代码
- [V3Manager](./contracts/UniswapV3Manager.sol)
- [V3Pool](./contracts/UniswapV3Pool.sol)
- [Quoter](./contracts/UniswapV3Quoter.sol)
- [Lib]()
    - [BitMath](./contracts/lib/BitMath.sol)
    - [FixedPoint](./contracts/lib/FixedPoint96.sol)
    - [LiquidityMath](./contracts/lib/LiquidityMath.sol)
    - [Math](./contracts/lib/Math.sol)
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
