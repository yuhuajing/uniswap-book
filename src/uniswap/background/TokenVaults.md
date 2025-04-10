# ERC4626 

## 背景
`ERC4626` 是一种代币化的份额标准，它使用 `ERC20` 代币来代表其他资产的份额。

它的工作原理是，你将一个 `ERC20` 代币（代币 `A`）存入 `ERC4626` 合约，并取回另一个 `ERC20` 代币，称之为代币 `S`。

在这个例子中，代币 `S` 代表你在当前合约所拥有的所有代币 `A` 中的份额（不是 `A` 的总供应量，只是 `ERC4626` 合约中 `A` 的余额）。

稍后，您可以将代币 `S` 放回合约并取回代币 `A`。

如果合约中的代币 `A` 余额增长速度快于代币 `S` 的生产速度，那么您提取的代币 `A` 数量将按比例大于您存入的代币 `A` 数量。

```solidity
abstract contract ERC4626 is ERC20, IERC4626 {
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }
}
```

`ERC4626` 扩展了 `ERC20` 合约，在构建阶段，它将其他 `ERC20` 代币用户将存入的资金作为参数。

因此，`ERC4626` 支持您期望 `ERC20` 具有的所有功能和事件：`
balanceOf
transfer
transferFrom
approve
allowance`

`ERC4626` 发行的代币被称为股份,您拥有的股份越多，您对存入其中的基础资产（其他 `ERC20` 代币）的权利就越大。

每个 `ERC4626` 合约仅支持一种资产，不支持将多种 `ERC20` 代币存入合约并取回份额。

## ERC4626 动机
让我们用一个真实的例子来激发设计。

假设我们每个人都拥有一家公司或一个流动资金池，定期赚取稳定币 `DAI`。在这种情况下，稳定币 `DAI` 就是资产。

分配收益的一种低效方法是按比例将 `DAI` 分发给公司的每个持有人。但这会非常昂贵。

同样，如果我们要在智能合约中更新每个人的余额，那么成本也会很昂贵。

相反，这是工作流程与 `ERC4626` 一起工作的方式。

> 假设您和 `9` 位朋友聚在一起，每人向 `ERC4626` 保险库存入 `10 DAI`（总计 `100 DAI`）。您会获得一份股份。
>
> 到目前为止一切顺利。现在您的公司又赚了 `10 DAI`，因此保险库内的总 `DAI` 现在为 `110 DAI`
>
> 当您将您的份额换回您的那部分 `DAI` 时，您拿回的不是 `10 DAI`，而是 `11 DAI`。
>
> 现在保险库里有 `99 DAI`，但有 9 个人可以分享。如果他们每人提取，每人将获得 `11 DAI`。

请注意这是多么高效。当有人进行交易时，不是逐个更新每个人的股份，而是只有股份的总供应量和合约中的资产数量发生变化。

`ERC4626 不局限于这种方式使用。你可以使用任意数学公式来确定股份和资产之间的关系。例如，你可以说每次有人提取资产时，他们还必须支付某种税款，这取决于区块时间戳或类似的东西。
`
## 接口详解

自然，用户希望知道 `ERC4626` 使用了哪种资产以及合约拥有多少资产，因此 `ERC4626` 规范中有两个solidity函数用于此。

`asset()` 函数返回用于 `Vault` 的底层代币的地址。如果底层资产是 `DAI`，那么该函数将返回 `DAI` 的 `ERC20` 合约地址。

`totalAssets()` 函数用于查询该合约中用于 `Vault` 的代币总量，调用该函数将返回保险库“管理”（拥有）的资产总额，即 `ERC4626` 合约拥有的 `ERC20` 代币数量

```solidity
    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }
```

存入资产，获取股份：`deposit() 和 mint()`

```solidity
// EIP: Mints a calculated number of vault shares to receiver by depositing an exact number of underlying asset tokens, specified by user.

function deposit(uint256 assets, address receiver) public virtual override returns (uint256)

// EIP: Mints exact number of vault shares to receiver, as specified by user, by calculating number of required shares of underlying asset.

function mint(uint256 shares, address receiver) public virtual override returns (uint256)
```
用户存入的是资产，拿回的是份额，那么这两个功能到底有什么区别呢？

- deposit()，指定要投入多少资产，然后该函数将计算要向您发送多少股份。
  - 指定您想要交易的资产，合约会计算您获得多少股份。
- mint()，指定所需的股份数，然后该函数将计算要从您那里转移多少 `ERC20` 资产。
  - 当然，如果您没有足够的资产转入合同，交易将会撤销。
  - 指定想要多少股份，合约会计算从您那里拿走多少资产

预测在理想情况下您存入资产后，将获得多少股份, `previewDeposit` 它将资产作为参数并返回在理想条件下（无滑点或费用）您将获得的股票数量。

```solidity
    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }
```
预测在理想情况下获得预期的股份，需要存入的 `ERC20` 数量, `previewMint` 它将资份额作为参数并返回在理想条件下（无滑点或费用）您需要存入的 `ERC20` 代币数量。
```solidity
    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }
```

预测在理想情况下退款预期份额，将获得多少资产, `previewRedeem` 它将份额作为参数并返回在理想条件下（无滑点或费用）您将获得的 `ERC20` 数量。
```solidity
    /** @dev See {IERC4626-previewRedeem}. */
  function previewRedeem(uint256 shares) public view virtual returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Floor);
  }
```
预测在理想情况下获得预期的 `ERC20` 代币数量，需要退回的份额数量, `previewWithdraw` 它将资份额作为参数并返回在理想条件下（无滑点或费用）您需要存入的 `ERC20` 代币数量。
```solidity
    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }
```

`mint、deposit、redeem 和 withdraw` 函数有第二个参数“`receiver`”，用于接收来自 `ERC4626` 的股票或资产的账户不是的情况 `msg.sender` 。

这意味着我可以将资产存入账户，并指定 `ERC4626` 合约给你股票。

## 滑点
任何代币兑换交换协议都存在一个问题，即用户可能无法取回他们期望的资产数量。

例如，对于自动做市商来说，大额交易可能会耗尽流动性并导致价格大幅波动。

另一个问题是交易被抢先交易或遭遇夹层攻击。在上面的例子中，我们假设 `ERC4626` 合约无论供应量如何，都保持资产和股票之间的一对一关系，但 `ERC4626` 标准并未规定定价算法应如何工作。

例如，假设我们将发行的股票数量设为存入资产的平方根的函数。在这种情况下，谁先存入，谁就能获得更多的股票。这可能会鼓励投机取巧的交易者抢先存入订单，并迫使下一位买家为相同数量的股票支付更多的资产。

对此的防御很简单：与 `ERC4626` 交互的合约应该测量其在存款期间收到的股份数量（以及取款期间的资产数量），如果在一定的滑点容忍度内没有收到预期的数量，则应恢复。

这是处理滑动问题的标准设计模式,防御有三种：

> 如果收到的金额不在滑点容忍范围内（前面已描述），则撤销
>
> 部署者应该向池中存入足够多的资产，这样进行通胀攻击的成本就会太高
>
> 向金库添加“虚拟流动性”，以便定价就像池子里部署了足够的资产一样。`

### 虚拟流动性

在计算存款人收到的股份数量时，总供应量会被人为地夸大（按照程序员在 中指定的比率 `_decimalsOffset()`）。

让我们来看一个例子。提醒一下，上面的变量的含义如下：

- totalSupply() = 已发行股票总数
- totalAssets()= ERC4626 持有资产余额
- 资产 = 用户存入的资产数量

`shares_received = assets_deposited * totalSupply() / totalAssets();`

假设我们有以下数字：
> assets_deposited= 1,000 
> 
> totalSupply()= 1,000 
> 
> totalAssets()= 999,999（公式加 1，因此我们将这样设置以使数字好看）

在这种情况下，用户将获得的份额是`1000 * 1000 / 1000000 = 1`。

这显然是非常脆弱的，如果攻击者抢先押注 1000 股并存入资产，那么受害者将得到 `1000 * 1000 / (1000000+1000) = 0`，因为在整数除法中，100 万除以大于 100 万的数字是零。

```solidity
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }
```
虚拟流动性如何解决这个问题？使用上面的代码，我们将其设置 `_decimalOffset() = 3`，这样就会 `totalSupply()` 将 `1,000` 添加到其中。

实际上，我们将分子放大了 `1,000` 倍。这迫使攻击者捐款 `1,000` 倍，从而打消了他们进行攻击的念头。

## 引用
完整继承 ERC4626 的实现代码：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyVault is ERC4626 {
    constructor(
        IERC20 asserts,
        string memory name,
        string memory symbol
    ) ERC4626(asserts) ERC20(name, symbol) {}
}
```