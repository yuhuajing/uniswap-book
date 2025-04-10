# UniswapV2 架构
`Uniswap` 是一款 `DeFi` 应用，允许交易者以无需信任的方式将一种代币兑换成另一种代币。

它是早期的自动交易做市商之一。

自动化做市商是订单簿的替代品，我们假设读者已经熟悉它。

## 恒定函数做市商 (Constant Function Market Makers)
一个自动做市商在池子（智能合约）中持有两种代币（代币 `X` 和代币 `Y`）。

它允许任何人从池子中取出代币 `X`，但必须存入一定数量的代币 `Y`，以使池子中的资产“总额”不会减少，我们认为“总额”是两种资产金额的乘积

同时使用代币兑换另一种代币，需要付出一定手续费，因此 (x + r $\Delta x$)(y - $\Delta y$)  = xy

xy <= x’y’ ,其中 xy表示兑换前的代币数量乘积，x'y'表示兑换完成后的代币数量乘积

这保证了资产池的资产持有量只能保持不变或增加。大多数资产池都会收取某种费用。余额的乘积不仅应该增加，而且应该至少增加一定数额以抵消费用。

资产由流动性提供者提供给资金池，流动性提供者会收到所谓的 `LP` 代币来代表其在资金池中的份额。流动性提供者余额的跟踪方式与[ERC 4626](../background/TokenVaults.md) 的工作方式类似。
- 自动做市商 `AMM` 和 `ERC4626` 之间的区别在于，`ERC4626` 仅支持一种资产，而 `AMM` 有两种代币

## AMM 优势
### 价格预言机
AMM 基于公式 `x * y = k` 运行交易池，通过内部代币的数量决定兑换价格

![](images/token_price1.png)

价格总是跟内部代币的数量相关，当单一交易池的代币价格脱锚后，其它 `DEX` 可以通过套利平衡每个交易池的价格

`DEX` 的代币价格总是和池子中的代币数量相关，因此可以作为链上代币价格的语言机。

但是，`DEX` 的价格容易受到链上交易的影响，[flash_loan](../background/Flashloan.md) 的大量代币的涌入/涌出 会造成代币瞬时的巨额波动，因此使用 `AMM` 去中心化交易池子作为价格 `oracle` 需要谨慎考虑价格的波动性

### 比订单薄更节省gas
订单簿需要大量的记账工作。`AMM` 只需要持有两个代币并按照简单的规则进行转移,这使得它们实施起来更有效率。

## AMM 劣势
自动化做市商有两个主要缺点：1）价格总是变动；2）流动性提供者的无常损失。
### 价格波动
即使是小额订单也会影响 `AMM` 中的价格
如果您下单购买 `100 股 Apple` 股票，您的订单不会导致价格变动，因为有数千股股票可以按照您指定的价格出售。自动做市商则不会出现这种情况。每笔交易，无论多小，都会影响价格。

`AMM DEX` 中任意交易都会引起兑换价格的波动，买入或卖出订单通常会比订单簿模型遇到更多的滑点，而交换机制会引发三明治攻击。

### MEV 
在 `AMM` 中，三明治攻击基本上是不可避免的
由于每笔订单都会影响价格，`MEV`（最大可提取价值）交易者会等待足够大的买单，然后在受害者的订单之前下达买单，并在受害者的订单之后下达卖单。领先的买单会推高原始交易者的价格，从而导致他们的执行情况更差。这被称为三明治攻击，因为受害者的交易被“夹”在攻击者之间。

> 1）攻击者的首次购买（抢先交易）：为受害者推高价格 
> 
> 2）受害者的购买：进一步推高价格
> 
> 3）攻击者的卖出：卖出首次购买的股票并获利

### 无常损失
无常损失表示在池子币价下跌时造成的损失，因为在 `AMM` 等去中心化的交易所中，流动性提供者自动成为代币对的买方和卖方，一旦有人发起交易，就会改变池子币价。

无常损失的公式为：

`（Value_pool - Value_hold）/Value_hold * 100%`

比如，在` 1ETH=10U `的背景下，`ETH` 涨到 `1 ETH = 1000U` 时的无常损失为：
- 正常持有：
  - 原本价值（`1ETH+10U = 10U+10U = 20U`）
  - ETH上涨后的价值（`1ETH+10U = 1000U+10U = 1010U`）
  - 利润为（`1010U-20u=990U`）
- 用户创建 `DEX`
  - `DEX` 中一共有 (`1ETH，10U`) 的代币对，此时 `ETH/U` 的价格为 `1ETH=10U`
  - 由于不停有人购入 `ETH`，最终 `ETH` 上涨至 `1000U`，此时池子剩余 (`0.1ETH，100U`)
  - 上涨后，`DEX` 创建者的剩余代币的价值为（`0.1ETH+100U = 0.1*1000U+100U = 100U + 100U = 200U`）
  - 利润为 （`200U-20U=180`U）
- 此时的无常损失率为 （`990-180/990*100% = 81.82% `）

## Uniswap V2 的架构
`UniswapV2` 的架构出奇地简单。其核心是 `UniswapV2Pair` 合约，该合约持有两个 `ERC20` 代币，交易者可以互换，或者流动性提供者可以为其提供流动性。

如果所需的 `UniswapV2Pair` 合约不存在，则可以从 `UniswapV2Factory` 合约中无需许可地创建一个新的合约。

`UniswapV2Pair` 合约也是 `ERC20` 代币，代币表示流动性份额，类似于 `ERC4626` 的工作方式。

虽然高级交易者或智能合约可以直接与货币对合约进行交互，但大多数用户还是会通过路由器合约与货币对进行交互，路由器合约具有多种便利功能，例如可以在一次交易中在货币对之间进行交易，如果货币对不存在，则创建一个“合成”货币对。

工厂合约，用于创建池子：[https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol](https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol)

Pair 交易池合约： [https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol](https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol)

Route： [https://github.com/Uniswap/v2-periphery/tree/master/contracts](https://github.com/Uniswap/v2-periphery/tree/master/contracts)

### 找到交易对
智能合约不是访问从代币对到池地址的映射，而是通过预测 `create2` 地址作为代币地址和工厂地址的函数来计算池的地址。

由于没有存储访问，因此这非常节省 `gas`。下面是 `UniswapV2Library` 提供的用于计算 `Pair` 合约地址的辅助函数。

```solidity
function pairFor(
  address factory,
  address tokenA,
  address tokenB
) public pure returns (address pair) {
  require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
  (address token0, address token1) = tokenA < tokenB
    ? (tokenA, tokenB)
    : (tokenB, tokenA);
  require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");

  bytes memory bytecode = getPairCodes();

  pair = address(
    uint256(
      keccak256(
        abi.encodePacked(
          hex"ff",
          factory,
          keccak256(abi.encodePacked(token0, token1)),
          keccak256(bytecode) // init code hash
        )
      )
    )
  );
}
```

### 每个交易对不使用代理模式
`EIP1167` 最小代理模式用于创建类似合约的集合，那么为什么不在这里使用它呢？

虽然部署成本更低，但由于 `delegatecall` ，每笔交易将额外增加 `2,600 gas` 。

由于池子旨在频繁使用，部署节省的成本最终会在几百笔交易后消失，因此值得将池子部署为新合约。

## Reference
[https://www.rareskills.io/uniswap-v2-book](https://www.rareskills.io/uniswap-v2-book)

[https://www.rareskills.io/post/eip-1167-minimal-proxy-standard-with-initialization-clone-pattern](https://www.rareskills.io/post/eip-1167-minimal-proxy-standard-with-initialization-clone-pattern)

[https://www.rareskills.io/post/uniswap-v2-tutorial](https://www.rareskills.io/post/uniswap-v2-tutorial)