# Web3 Uniswap DEX Development Book

> 用 Solidity 从零手写 Uniswap V1 / V2 / V3，循序渐进地理解自动做市商（AMM）背后的核心原理。

欢迎来到本书！这是一本**实战型教程**：不堆砌概念，而是像搭积木一样，一个里程碑接一个里程碑地实现一套去中心化交易所（DEX）。每一章都配有可运行的 Solidity 合约源码，最终你将拥有对 Uniswap 三大版本实现机制的完整认知。

## 关于本书（About）

这是一本用 **Solidity 从零手写 Uniswap V1 / V2 / V3** 的实战教程。我们按版本演进顺序，把一个去中心化交易所（DEX）拆成一个个递进的里程碑来实现：从 V1「用公式替代订单簿」的最简形态，到 V3 的集中流动性、Tick 索引、跨池路由、三层费率、TWAP 价格预言机，以及用 ERC721 表示的 NFT 流动性仓位。目标不是让你背下官方代码，而是**真正读懂 AMM 背后的数学与设计取舍**——每个里程碑都附带可 `forge build` 的合约，边写边理解。

相关链接：

- 📖 **在线阅读（本书部署版）**：<https://yuhuajing.github.io/uniswap-book/index.html>
- 💻 **项目仓库（含全部源码与本地构建说明）**：<https://github.com/yuhuajing/uniswap-book>
- 🚀 **本地运行**：克隆仓库后执行 `mdbook serve --open` 即可本地预览（详见仓库根目录 `README.md`）
- 🧰 **合约测试**：进入各 `milestone_*/contracts` 目录执行 `forge build` / `forge test`（需先安装 [Foundry](https://getfoundry.sh/)）

左侧导航（由 `SUMMARY.md` 生成）是本教程的完整目录。下面也给出一份总览，方便你快速定位。

## 如何阅读本书

```text
背景知识  →  Uniswap V1  →  Uniswap V2  →  Uniswap V3（Milestone 1 → 6 顺序学习）
```

- **背景**：AMM 数学与合约基础，时间紧可只挑不熟悉的章节。
- **V1 / V2**：强烈建议通读，它们是理解 V3 设计动机的基石。
- **V3 六个里程碑必须顺序学习**——后一个依赖前一个的合约。
- 每个里程碑的 `user-interface` 与 `deployment` 为可选项，仅在你打算本地跑前端 / 部署时阅读。

> 每个里程碑都附带一份可 `forge build` 的 Solidity 源码，跟随全书你将亲手实现一套 V3 风格的 AMM：集中流动性、跨池路由、三层费率、TWAP 预言机，以及用 ERC721 表示的 NFT 流动性仓位。

## 范围与约定

为聚焦原理，本书实现相比生产级 Uniswap V3 做了有意简化：早期里程碑会硬编码参数、用 Python 预演数学；未做主网部署与安全审计；前端示例为最小可运行 UI。相关章节省已标明省略点，投入生产请以 Uniswap 官方审计报告为准。

## V3 里程碑速览

| 里程碑 | 主题 | 你将构建 / 理解的关键点 |
| --- | --- | --- |
| M1 | 手动计算的 Swap | 单个 ETH/USDC 池子；硬编码参数、Python 预演数学，最小可用产品（单区间、单向交易） |
| M2 | 池子内的自动 Swap | Tick Bitmap 索引；单池内自动跨 Tick 计算输出量与新 Tick 位置；Quoter 预估 |
| M3 | 跨流动性区间的 Swap | 多价格区间流动性、跨 Tick 交易、滑点保护；定点数进阶与闪电贷 |
| M4 | 跨池子兑换 | 工厂合约 + Path 库；多池子链式路由；Tick 间隔优化 |
| M5 | 累计手续费 + Oracle | Swap / 协议 / 闪电贷三层费率；TWAP 价格预言机 |
| M6 | NFT Positions | ERC721 流动性仓位；NFT Manager 与链上元数据渲染 |

## 背景

- [Solidity 定点数](uniswap/background/solidity-fixed-point.md)
- [ERC4626 金库](uniswap/background/TokenVaults.md)
- [闪电贷 Flashloan](uniswap/background/Flashloan.md)
- [去中心化交易所](uniswap/background/introduction-to-markets.md)
- [恒定乘积公式](uniswap/background/constant-function-market-maker.md)
- [价格操纵](uniswap/background/price-manipulation.md)

## Uniswap V1

- [工厂合约](./uniswap/uniswapV1/uniswap-v1-factory.md)
- [Exchange 合约](./uniswap/uniswapV1/uniswap-v1-exchange.md)
- [Uniswap 合约](./uniswap/uniswapV1/uniswapv1.md)

## Uniswap V2

- [架构](./uniswap/uniswapV2/architecture.md)
- [兑换函数](./uniswap/uniswapV2/swap-functions.md)
- [流动性代币](./uniswap/uniswapV2/mint_burn_lp.md)
- [Uniswap 协议手续费](./uniswap/uniswapV2/protocal_fee.md)
- [代币价格预言机](./uniswap/uniswapV2/oracle.md)
- [库 View 函数](./uniswap/uniswapV2/contracts_library.md)
- [Routes](./uniswap/uniswapV2/routes.md)

## Uniswap V3

- [框架](./uniswap/uniswapV3/introduction/uniswap-v3.md)
- [开发环境](./uniswap/uniswapV3/introduction/dev-environment.md)

### Milestone 1 · 手动计算的 Swap

- [完整合约代码](./uniswap/uniswapV3/milestone_1/introduction.md)
- [计算流动性](./uniswap/uniswapV3/milestone_1/calculating-liquidity.md)
- [添加流动性](./uniswap/uniswapV3/milestone_1/providing-liquidity.md)
- [兑换代币](./uniswap/uniswapV3/milestone_1/first-swap.md)
- [管理流动池](./uniswap/uniswapV3/milestone_1/manager-contract.md)
- [部署合约](./uniswap/uniswapV3/milestone_1/deployment.md)
- [用户界面](./uniswap/uniswapV3/milestone_1/user-interface.md)

### Milestone 2 · 池子内的自动 Swap

- [完整合约代码](./uniswap/uniswapV3/milestone_2/introduction.md)
- [添加流动性](./uniswap/uniswapV3/milestone_2/generalize-minting.md)
- [计算 swap 数量](./uniswap/uniswapV3/milestone_2/output-amount-calculation.md)
- [计算新的 Tick 位置](./uniswap/uniswapV3/milestone_2/tick-bitmap-index.md)
- [swap 代币](./uniswap/uniswapV3/milestone_2/generalize-swapping.md)
- [预估 swap 数量](./uniswap/uniswapV3/milestone_2/quoter-contract.md)
- [用户界面](./uniswap/uniswapV3/milestone_2/user-interface.md)

### Milestone 3 · 跨流动性区间的 Swap

- [完整合约代码](./uniswap/uniswapV3/milestone_3/introduction.md)
- [添加流动性](./uniswap/uniswapV3/milestone_3/different-ranges.md)
- [swap 代币](./uniswap/uniswapV3/milestone_3/cross-tick-swaps.md)
- [swap 滑点](./uniswap/uniswapV3/milestone_3/slippage-protection.md)
- [流动性计算](./uniswap/uniswapV3/milestone_3/liquidity-calculation.md)
- [定点数进阶](./uniswap/uniswapV3/milestone_3/more-on-fixed-point-numbers.md)
- [闪电贷](./uniswap/uniswapV3/milestone_3/flash-loans.md)
- [用户界面](./uniswap/uniswapV3/milestone_3/user-interface.md)

### Milestone 4 · 跨池子兑换

- [完整合约代码](./uniswap/uniswapV3/milestone_4/introduction.md)
- [部署 Pool 的工厂合约](./uniswap/uniswapV3/milestone_4/factory-contract.md)
- [计算兑换路径](./uniswap/uniswapV3/milestone_4/path.md)
- [swap 代币](./uniswap/uniswapV3/milestone_4/multi-pool-swaps.md)
- [用户界面](./uniswap/uniswapV3/milestone_4/user-interface.md)
- [Tick 取整](./uniswap/uniswapV3/milestone_4/tick-rounding.md)

### Milestone 5 · 累计手续费用 + Oracle price

- [完整合约代码](./uniswap/uniswapV3/milestone_5/introduction.md)
- [swap 手续费](./uniswap/uniswapV3/milestone_5/swap-fees.md)
- [协议手续费](./uniswap/uniswapV3/milestone_5/protocol-fees.md)
- [价格预言机](./uniswap/uniswapV3/milestone_5/price-oracle.md)
- [闪电贷手续费](./uniswap/uniswapV3/milestone_5/flash-loan-fees.md)
- [用户界面](./uniswap/uniswapV3/milestone_5/user-interface.md)

### Milestone 6 · NFT Positions

- [完整合约代码](./uniswap/uniswapV3/milestone_6/introduction.md)
- [ERC721 概览](./uniswap/uniswapV3/milestone_6/erc721-overview.md)
- [NFT Manager](./uniswap/uniswapV3/milestone_6/nft-manager.md)
- [NFT Renderer](./uniswap/uniswapV3/milestone_6/nft-renderer.md)

## 参考资料

- [术语词典 Dictionary](./uniswap/uniswapV3/reference/dictionary.md)
