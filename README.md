# Web3 Uniswap DEX Development Book

> 用 Solidity 从零手写 Uniswap V1 / V2 / V3，循序渐进地理解自动做市商（AMM）背后的核心原理。

这是一本面向开发者的**实战型教程**：不堆砌概念，而是像搭积木一样，一个里程碑接一个里程碑地实现一套去中心化交易所（DEX）。每一章都配有可运行的 Solidity 合约源码与说明，最终你将拥有对 Uniswap 三大版本实现机制的完整认知。

## 项目简介

本项目以 [Uniswap](https://uniswap.org/) 这一最经典的 AMM 协议为蓝本，按版本演进顺序拆解其设计：

- **背景知识**：先补齐理解 AMM 所需的数学与合约基础（定点数、ERC4626、闪电贷、价格操纵等）；
- **Uniswap V1**：最朴素的 `工厂 + Exchange` 模型，理解「用公式替代订单簿」的最简形态；
- **Uniswap V2**：引入 `xy=k` 恒定乘积、流动性代币（LP）、协议手续费、时间加权平均价格（TWAP）预言机；
- **Uniswap V3**：本教程的重点。通过 6 个递进的里程碑，从「单价格区间的手动兑换」一路实现到「跨池路由 + 手续费累计 + 价格预言机 + NFT 仓位」。

> 书中所有合约均使用 [Foundry](https://getfoundry.sh/)（`forge`）编写与测试，对应的 UI 示例使用 TypeScript / React。文档本身由 [mdBook](https://rust-lang.github.io/mdBook/) 构建。

## 你将学到什么

- 恒定乘积做市（`x * y = k`）的数学原理与边界情况；
- 集中流动性（Concentrated Liquidity）与 Tick / Tick Bitmap 的索引方式；
- 流动性提供、铸造/销毁 LP（或 NFT 仓位）、Swap 数量与价格的计算；
- 跨流动性区间、跨资金池的路由与滑点保护；
- 协议手续费、闪电贷手续费、TWAP 价格预言机的实现；
- 用 ERC721 表示流动性仓位，并在链上渲染 NFT 元数据。

## 技术栈与前置条件

| 用途 | 工具 |
| --- | --- |
| 合约开发 / 测试 | [Foundry](https://getfoundry.sh/)（`forge`、`anvil`） |
| 前端示例 | Node.js + TypeScript + React |
| 文档构建 | Rust + [mdBook](https://rust-lang.github.io/mdBook/) + `mdbook-katex` |
| 链上交互 | 钱包（如 MetaMask）+ 测试网 |

建议读者具备基础的 Solidity 与 JavaScript/TypeScript 知识。

## 目标读者

- 想**真正读懂 Uniswap 源码**而非只会调用 SDK 的 Solidity / 智能合约开发者；
- 对 AMM、集中流动性、Tick 机制感兴趣，但被官方代码体量劝退的工程师；
- 准备做 DEX / 做市 / 链上衍生品方向，需要吃透底层数学与数据结构的学习者；
- 想用 Foundry 系统化练习合约编写与测试的中高级开发者。

> 如果你还不熟悉 Solidity 或 AMM 的基本概念，建议先读完「背景」章节再进入 V1。

## 本书特色

- **动手优先**：不堆概念，每个里程碑都产出一份可 `forge build` 的合约，边写边理解。
- **版本演进叙事**：从 V1「用公式替代订单簿」的最简形态，到 V3 集中流动性与 NFT 仓位，按历史演进顺序拆解，难点被自然分散。
- **数学讲透**：早期用 Python 预演常数乘积 / 流动性 / Tick 的数学，再落地到 Solidity 定点数（PRBMath 等），避免一上来就被整数运算劝退。
- **完整可运行**：合约用 Foundry 编写测试，UI 用 TypeScript / React 演示，文档由 mdBook + KaTeX 渲染公式。

## 你会亲手构建什么

跟随全书走完，你将拥有一套**自己从零实现的 V3 风格 AMM**，具备以下能力：

- 在任意价格区间提供集中流动性，并精确计算流动性与手续费；
- 单池内自动跨 Tick 的 Swap，以及跨多个资金池的链式路由；
- Swap / 协议 / 闪电贷三层费率模型；
- 基于累积值的 TWAP 时间加权价格预言机，可被其他合约读取；
- 用 ERC721 表示流动性仓位，并在链上渲染 NFT 元数据。

## 建议的阅读路线

```text
背景知识  →  Uniswap V1  →  Uniswap V2  →  Uniswap V3（按 Milestone 1→6 顺序）
```

- **背景**：AMM 数学与合约基础，时间紧可只挑不熟悉的章节。
- **V1 / V2**：强烈建议通读，它们是理解 V3 设计动机的基石。
- **V3**：六个里程碑**必须顺序学习**——后一个依赖前一个的合约。
- 每个里程碑的 `user-interface` 与 `deployment` 为可选项，仅在你打算本地跑前端 / 部署时阅读。

## 范围与约定

为聚焦原理、降低认知负担，本书的实现相比生产级 Uniswap V3 做了**有意的简化**：

- 早期里程碑（如 M1）会**硬编码参数**、用 Python 预计算数学，再逐步替换为链上定点数计算；
- 未做主网部署与安全审计，目标是「理解机制」而非「生产可用」；
- 前端示例为**最小可运行 UI**，用于演示交互，并非完整产品；
- 部分 gas 优化、极限边界与极端情况作了省略，仅在相关章节点出。

> 这些都已在对应章节明确标注；当你准备投入生产，请以 Uniswap 官方审计报告与代码为准。

## 仓库目录结构

```text
uniswap-book/
├── book.toml              # mdBook 构建配置
├── README.md              # 本文件（项目说明）
├── src/                   # 文档源码（即本书内容）
│   ├── SUMMARY.md         # 目录，mdBook 导航的唯一来源
│   ├── README.md          # 本书首页
│   └── uniswap/
│       ├── background/    # 背景知识
│       ├── uniswapV1/     # V1 实现讲解
│       ├── uniswapV2/     # V2 实现讲解
│       └── uniswapV3/
│           ├── introduction/    # V3 框架与开发环境
│           ├── milestone_1/ ... milestone_6/   # 六大里程碑
│           │   ├── *.md          # 章节正文
│           │   ├── contracts/    # 各里程碑 Solidity 源码（Foundry 工程）
│           │   └── images/       # 配图
│           └── reference/        # 术语词典等
└── public/                # 站点静态资源
```

> 每个 `milestone_*/contracts` 都是独立 Foundry 工程；其 `out/`、`cache/`、`artifacts/` 等编译产物已加入 `.gitignore`，不会进版本库。

## 本书结构
- [Solidity 定点数](src/uniswap/background/solidity-fixed-point.md)
- [ERC4626 金库](src/uniswap/background/TokenVaults.md)
- [闪电贷 Flashloan](src/uniswap/background/Flashloan.md)
- [去中心化交易所](src/uniswap/background/introduction-to-markets.md)
- [恒定乘积公式](src/uniswap/background/constant-function-market-maker.md)
- [价格操纵](src/uniswap/background/price-manipulation.md)

### Uniswap V1
- [工厂合约](src/uniswap/uniswapV1/uniswap-v1-factory.md)
- [Exchange 合约](src/uniswap/uniswapV1/uniswap-v1-exchange.md)
- [Uniswap 合约](src/uniswap/uniswapV1/uniswapv1.md)

### Uniswap V2
- [架构](src/uniswap/uniswapV2/architecture.md)
- [兑换函数](src/uniswap/uniswapV2/swap-functions.md)
- [流动性代币](src/uniswap/uniswapV2/mint_burn_lp.md)
- [Uniswap 协议手续费](src/uniswap/uniswapV2/protocal_fee.md)
- [代币价格预言机](src/uniswap/uniswapV2/oracle.md)
- [库 View 函数](src/uniswap/uniswapV2/contracts_library.md)
- [Routes](src/uniswap/uniswapV2/routes.md)

### Uniswap V3
- [框架](src/uniswap/uniswapV3/introduction/uniswap-v3.md)
- [开发环境](src/uniswap/uniswapV3/introduction/dev-environment.md)

**V3 里程碑速览**（六个里程碑须顺序学习，后一个依赖前一个的合约）：

| 里程碑 | 主题 | 你将构建 / 理解的关键点 |
| --- | --- | --- |
| M1 | 手动计算的 Swap | 单个 ETH/USDC 池子；硬编码参数、用 Python 预演数学，得到最小可用产品（单区间、单向交易） |
| M2 | 池子内的自动 Swap | 引入 Tick Bitmap 索引；单池内自动跨 Tick 计算输出量与新 Tick 位置；新增 Quoter 预估 |
| M3 | 跨流动性区间的 Swap | 多价格区间提供流动性、跨 Tick 交易、滑点保护；深入定点数运算与闪电贷 |
| M4 | 跨池子兑换 | 工厂合约 + Path 库；多池子链式路由；理解 Tick 间隔优化 |
| M5 | 累计手续费 + Oracle | Swap / 协议 / 闪电贷三层费率；基于累积值的 TWAP 价格预言机 |
| M6 | NFT Positions | 用 ERC721 表示流动性仓位；NFT Manager 与链上元数据渲染；集成第三方协议 |

**Milestone 1 · 手动计算的 Swap**
- [完整合约代码](src/uniswap/uniswapV3/milestone_1/introduction.md)
- [计算流动性](src/uniswap/uniswapV3/milestone_1/calculating-liquidity.md)
- [添加流动性](src/uniswap/uniswapV3/milestone_1/providing-liquidity.md)
- [兑换代币](src/uniswap/uniswapV3/milestone_1/first-swap.md)
- [管理流动池](src/uniswap/uniswapV3/milestone_1/manager-contract.md)
- [部署合约](src/uniswap/uniswapV3/milestone_1/deployment.md)
- [用户界面](src/uniswap/uniswapV3/milestone_1/user-interface.md)

**Milestone 2 · 池子内的自动 Swap**
- [完整合约代码](src/uniswap/uniswapV3/milestone_2/introduction.md)
- [添加流动性](src/uniswap/uniswapV3/milestone_2/generalize-minting.md)
- [计算 swap 数量](src/uniswap/uniswapV3/milestone_2/output-amount-calculation.md)
- [计算新的 Tick 位置](src/uniswap/uniswapV3/milestone_2/tick-bitmap-index.md)
- [swap 代币](src/uniswap/uniswapV3/milestone_2/generalize-swapping.md)
- [预估 swap 数量](src/uniswap/uniswapV3/milestone_2/quoter-contract.md)
- [用户界面](src/uniswap/uniswapV3/milestone_2/user-interface.md)

**Milestone 3 · 跨流动性区间的 Swap**
- [完整合约代码](src/uniswap/uniswapV3/milestone_3/introduction.md)
- [添加流动性](src/uniswap/uniswapV3/milestone_3/different-ranges.md)
- [swap 代币](src/uniswap/uniswapV3/milestone_3/cross-tick-swaps.md)
- [swap 滑点](src/uniswap/uniswapV3/milestone_3/slippage-protection.md)
- [流动性计算](src/uniswap/uniswapV3/milestone_3/liquidity-calculation.md)
- [定点数进阶](src/uniswap/uniswapV3/milestone_3/more-on-fixed-point-numbers.md)
- [闪电贷](src/uniswap/uniswapV3/milestone_3/flash-loans.md)
- [用户界面](src/uniswap/uniswapV3/milestone_3/user-interface.md)

**Milestone 4 · 跨池子兑换**
- [完整合约代码](src/uniswap/uniswapV3/milestone_4/introduction.md)
- [部署 Pool 的工厂合约](src/uniswap/uniswapV3/milestone_4/factory-contract.md)
- [计算兑换路径](src/uniswap/uniswapV3/milestone_4/path.md)
- [swap 代币](src/uniswap/uniswapV3/milestone_4/multi-pool-swaps.md)
- [用户界面](src/uniswap/uniswapV3/milestone_4/user-interface.md)
- [Tick 取整](src/uniswap/uniswapV3/milestone_4/tick-rounding.md)

**Milestone 5 · 累计手续费用 + Oracle price**
- [完整合约代码](src/uniswap/uniswapV3/milestone_5/introduction.md)
- [swap 手续费](src/uniswap/uniswapV3/milestone_5/swap-fees.md)
- [协议手续费](src/uniswap/uniswapV3/milestone_5/protocol-fees.md)
- [价格预言机](src/uniswap/uniswapV3/milestone_5/price-oracle.md)
- [闪电贷手续费](src/uniswap/uniswapV3/milestone_5/flash-loan-fees.md)
- [用户界面](src/uniswap/uniswapV3/milestone_5/user-interface.md)

**Milestone 6 · NFT Positions**
- [完整合约代码](src/uniswap/uniswapV3/milestone_6/introduction.md)
- [ERC721 概览](src/uniswap/uniswapV3/milestone_6/erc721-overview.md)
- [NFT Manager](src/uniswap/uniswapV3/milestone_6/nft-manager.md)
- [NFT Renderer](src/uniswap/uniswapV3/milestone_6/nft-renderer.md)

### 参考资料
- [术语词典 Dictionary](src/uniswap/uniswapV3/reference/dictionary.md)

## 在线阅读

本书已发布在 GitHub Pages：<https://yuhuajing.github.io/uniswap-book/>

左侧导航（由 `src/SUMMARY.md` 生成）即为完整目录。

## 本地运行

构建并本地预览本书：

1. 安装 [Rust](https://www.rust-lang.org/)。
2. 安装 [mdBook](https://rust-lang.github.io/mdBook/) 及其 KaTeX 预处理插件：
   ```shell
   $ cargo install mdbook
   $ cargo install mdbook-katex
   ```
3. 克隆仓库并进入目录：
   ```shell
   $ git clone https://github.com/yuhuajing/uniswap-book.git
   $ cd uniswap-book
   ```
4. 启动本地服务（默认会自动打开浏览器）：
   ```shell
   $ mdbook serve --open
   ```
5. 访问 <http://localhost:3000/>（以命令输出为准）。

> 若想编译 / 测试书中的 Solidity 合约，另需安装 [Foundry](https://getfoundry.sh/)（`foundryup`），进入各 `milestone_*/contracts` 目录执行 `forge build` 即可。

## 相关链接

- 项目仓库：<https://github.com/yuhuajing/uniswap-book>
- 在线文档：<https://yuhuajing.github.io/uniswap-book/>

## 许可证

详见仓库许可证文件。
