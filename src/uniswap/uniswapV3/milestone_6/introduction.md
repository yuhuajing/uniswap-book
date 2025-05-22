# NFT Positions
将学习如何扩展 `Uniswap` 合约，以及将它集成到第三方的协议中。

`Uniswap V3` 的一个额外特性是能够把流动性位置转换成 `NFT`。这是其中一个的例子：

![Uniswap V3 NFT example](../images/milestone_6/nft_example.png)

它展示了 `token` 的信息：
```text
[ positions(uint256) method Response ]
  nonce   uint96 :  0
  operator   address :  0x0000000000000000000000000000000000000000
  token0   address :  0xB035723D62e0e2ea7499D76355c9D560f13ba404
  token1   address :  0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
  fee   uint24 :  10000
  tickLower   int24 :  -96600
  tickUpper   int24 :  -82800
  liquidity   uint128 :  0
  feeGrowthInside0LastX128   uint256 :  19275342891285237278050788030132407641
  feeGrowthInside1LastX128   uint256 :  151805030514340226583840194092093
  tokensOwed0   uint128 :  0
  tokensOwed1   uint128 :  0
 ]
```

## 完整合约代码
- [V3Factory](./contracts/UniswapV3Factory.sol)
- [V3Manager](./contracts/UniswapV3Manager.sol)
- [V3NFTManager](./contracts/UniswapV3NFTManager.sol)
- [V3Pool](./contracts/UniswapV3Pool.sol)
- [Quoter](./contracts/UniswapV3Quoter.sol)
- [Lib]()
    - [BitMath](./contracts/lib/BitMath.sol)
    - [BytesKib](./contracts/lib/BytesLib.sol)
    - [FixedPoint](./contracts/lib/FixedPoint96.sol)
    - [LiquidityMath](./contracts/lib/LiquidityMath.sol)
    - [Math](./contracts/lib/Math.sol)
    - [NFTRender](./contracts/lib/NFTRenderer.sol)
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
    - [Deployer](./contracts/interfaces/IUniswapV3PoolDeployer.sol)ub Discussion 中提问和交流](https://github.com/Jeiwan/uniswapv3-book/discussions/categories/milestone-6-nft-positions)!