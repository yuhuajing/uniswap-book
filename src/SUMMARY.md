# Summary

[Solidity learn books](README.md)

# Uniswap
- [背景]()
  - [Solidity-Fixed-Point](uniswap/background/solidity-fixed-point.md)
  - [ERC4626](uniswap/background/TokenVaults.md)
  - [闪电贷Flashloan](uniswap/background/Flashloan.md)
  - [去中心化交易所](uniswap/background/introduction-to-markets.md)
  - [恒定乘积公式](uniswap/background/constant-function-market-maker.md)
  - [价格操纵](uniswap/background/price-manipulation.md)
- [uniswapV1]()
    - [工厂合约](./uniswap/uniswapV1/uniswap-v1-factory.md)
    - [Exchange合约](./uniswap/uniswapV1/uniswap-v1-exchange.md)
    - [Uniswap合约](./uniswap/uniswapV1/uniswapv1.md)
- [uniswapV2]()
  - [架构](./uniswap/uniswapV2/architecture.md)
  - [兑换函数](./uniswap/uniswapV2/swap-functions.md)
  - [流动性代币](./uniswap/uniswapV2/mint_burn_lp.md)
  - [Uniswap协议手续费](./uniswap/uniswapV2/protocal_fee.md)
  - [代币价格预言机](./uniswap/uniswapV2/oracle.md)
  - [库View函数](./uniswap/uniswapV2/contracts_library.md)
  - [Routes](./uniswap/uniswapV2/routes.md)
- [uniswapV3]()
  - [uniswapV3]()
    - [框架](./uniswap/uniswapV3/introduction/uniswap-v3.md)
    - [开发环境](./uniswap/uniswapV3/introduction/dev-environment.md)
  - [简单的Swap]()
    - [简介](./uniswap/uniswapV3/milestone_1/introduction.md)
    - [计算流动性](./uniswap/uniswapV3/milestone_1/calculating-liquidity.md)
    - [提供流动性](./uniswap/uniswapV3/milestone_1/providing-liquidity.md)
    - [兑换代币](./uniswap/uniswapV3/milestone_1/first-swap.md)
    - [管理流动池](./uniswap/uniswapV3/milestone_1/manager-contract.md)
    - [部署池合约](./uniswap/uniswapV3/milestone_1/deployment.md)
    - [User Interface](./uniswap/uniswapV3/milestone_1/user-interface.md)
  - [Milestone 2. Second Swap]()
    - [Introduction](./uniswap/uniswapV3/milestone_2/introduction.md)
    - [Output Amount Calculation](./uniswap/uniswapV3/milestone_2/output-amount-calculation.md)
    - [Math in Solidity](./uniswap/uniswapV3/milestone_2/math-in-solidity.md)
    - [Tick Bitmap Index](./uniswap/uniswapV3/milestone_2/tick-bitmap-index.md)
    - [Generalized Minting](./uniswap/uniswapV3/milestone_2/generalize-minting.md)
    - [Generalized Swapping](./uniswap/uniswapV3/milestone_2/generalize-swapping.md)
    - [Quoter Contract](./uniswap/uniswapV3/milestone_2/quoter-contract.md)
    - [User Interface](./uniswap/uniswapV3/milestone_2/user-interface.md)
  - [Milestone 3. Cross-Tick Swaps]()
    - [Introduction](./uniswap/uniswapV3/milestone_3/introduction.md)
    - [Different Price Ranges](./uniswap/uniswapV3/milestone_3/different-ranges.md)
    - [Cross-Tick Swaps](./uniswap/uniswapV3/milestone_3/cross-tick-swaps.md)
    - [Slippage Protection](./uniswap/uniswapV3/milestone_3/slippage-protection.md)
    - [Liquidity Calculation](./uniswap/uniswapV3/milestone_3/liquidity-calculation.md)
    - [A Little Bit More on Fixed-Point Numbers](./uniswap/uniswapV3/milestone_3/more-on-fixed-point-numbers.md)
    - [Flash Loans](./uniswap/uniswapV3/milestone_3/flash-loans.md)
    - [User Interface](./uniswap/uniswapV3/milestone_3/user-interface.md)
  - [Milestone 4. Multi-pool Swaps]()
    - [Introduction](./uniswap/uniswapV3/milestone_4/introduction.md)
    - [Factory Contract](./uniswap/uniswapV3/milestone_4/factory-contract.md)
    - [Swap Path](./uniswap/uniswapV3/milestone_4/path.md)
    - [Multi-Pool Swaps](./uniswap/uniswapV3/milestone_4/multi-pool-swaps.md)
    - [User Interface](./uniswap/uniswapV3/milestone_4/user-interface.md)
    - [Tick Rounding](./uniswap/uniswapV3/milestone_4/tick-rounding.md)
  - [Milestone 5. Fees and Price Oracle]()
    - [Introduction](./uniswap/uniswapV3/milestone_5/introduction.md)
    - [Swap Fees](./uniswap/uniswapV3/milestone_5/swap-fees.md)
    - [Flash Loan Fees](./uniswap/uniswapV3/milestone_5/flash-loan-fees.md)
    - [Protocol Fees](./uniswap/uniswapV3/milestone_5/protocol-fees.md)
    - [Price Oracle](./uniswap/uniswapV3/milestone_5/price-oracle.md)
    - [User Interface](./uniswap/uniswapV3/milestone_5/user-interface.md)
  - [Milestone 6: NFT Positions]()
    - [Introduction](./uniswap/uniswapV3/milestone_6/introduction.md)
    - [Overview of ERC721](./uniswap/uniswapV3/milestone_6/erc721-overview.md)
    - [NFT Manager](./uniswap/uniswapV3/milestone_6/nft-manager.md)
    - [NFT Renderer](./uniswap/uniswapV3/milestone_6/nft-renderer.md)