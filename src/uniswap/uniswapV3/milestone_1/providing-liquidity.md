# 提供流动性
## 池子合约
正如我们在简介中提到的，`Uniswap` 部署了多个池子合约，每一个负责一对 `token` 的交易。
`Uniswap` 的所有合约被分为以下两类：
- 核心合约(`core contracts`)
- 外部合约(`periphery contracts`)
  
正如其名，核心合约实现了核心的逻辑。这些合约是最小的，对用户**不友好**的，底层的合约。
这些合约都只做一件事并且保证这件事尽可能地安全。

在 `UniswapV3` 中，核心合约包含以下两种：
1. 池子(`Pool`)合约，实现了去中心化交易的核心逻辑
2. 工厂(`Factory`)合约，作为池子合约的注册入口，使得部署池子合约更加简单。

我们将会从池子合约开始，这部分实现了 `Uniswap 99%` 的核心功能。

创建 `src/UniswapV3Pool.sol`:

```solidity
pragma solidity ^0.8.14;

contract UniswapV3Pool {}
```
首先我们需要明确的是：
- `UniswapV3` 是基于 `ticks` 对应的价格区间创建的交易对池子
- 每个池子都在自己的 `ticks` 对应的价格区间内提供流动性
- 同样的 `ticks` 价格区间，可能会存在多个池子在提供流动性

设计合约需要存储哪些数据：
1. 存储 `token` 交易对地址。这些地址是静态的，仅设置一次并且保持不变的(因此，这些变量需要被设置为 `immutable`)；
2. 每个池子合约包含了一系列的流动性位置，我们需要用一个 `mapping` 来存储这些信息，`key` 代表不同位置，`value` 是包含这些位置相关的信息；
3. 存储池子 `tick`信息，标识当前池子提供流动性的价格区间；
4. 池子的 `tick` 的范围是固定的，这些范围在合约中存为常数；
5. 需要存储池子流动性的总数 $L$；
6. 跟踪现在的价格和对应的 `tick`，把他们存储在一个 `slot` 中来节省 `gas` 费， [Solidity 变量在存储中的分布特点](https://yuhuajing.github.io/solidity-book/milestone_1/static-slot-storage.html)

总之，合约大概存储了以下这些信息：

```solidity
// src/lib/Tick.sol
library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }
    ...
}

// src/lib/Position.sol
library Position {
    struct Info {
        uint128 liquidity;
    }
    ...
}

// src/UniswapV3Pool.sol
contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    // Pool tokens, immutable
    address public immutable token0;
    address public immutable token1;

    // Packing variables that are read together
    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }
    Slot0 public slot0;

    // Amount of liquidity, L.
    uint128 public liquidity;

    // Ticks info
    mapping(int24 => Tick.Info) public ticks;
    // Positions info
    mapping(bytes32 => Position.Info) public positions;

    ...
```

`UniswapV3` 有很多辅助的合约，`Tick` 和 `Position` 就是其中两个。

接下来，我们在 `constructor` 中初始化其中一些变量：

```solidity
    constructor(
        address token0_,
        address token1_,
        //当前价格
        uint160 sqrtPriceX96,
        int24 tick // 当前价格所对应的 tick index
    ) {
        token0 = token0_;
        token1 = token1_;

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});
    }
}
```
在构造函数中，初始化了不可变的 `token` 交易对地址、现在的价格和对应的 `tick`。

## 铸造(Minting)

在 `UniswapV2` 中，提供流动性被称作 *铸造(`mint`)*，
因为 `UniswapV2` 的池子给予 `LP-token` 作为提供流动性的交换。
`V3` 没有这种行为，但是仍然保留了同样的名字，我们在这里也同样使用这个名字：

```solidity
function mint(
    address owner,
    int24 lowerTick,
    int24 upperTick,
    uint128 amount
) external returns (uint256 amount0, uint256 amount1) {
    ...
```

`mint` 函数会包含以下参数：
1. `token` 所有者的地址，来识别是谁提供的流动性；
2. 上限和下限价格对应的 `tick`，来设置价格区间的边界；
3. 希望提供的流动性的数量

简单描述一下铸造函数如何工作：
1. 用户指定价格区间和流动性的数量；
2. 合约更新 `ticks` 和 `positions` 的 `mapping`；
3. 合约计算出用户需要提供的 `token` 数量（在本节我们用事先计算好的值）；
- 获取 `slot0` 中当前的价格和 `tick index`
- 根据提供的 `tick` 区间值计算价格区间
- 根据当前价格和上下限价格，计算流动性值，取最小值
- 根据最小流动性值计算需要的 `Tokens` 数量
4. 合约从用户处获得 `tokens`，并且验证数量是否正确。

首先来检查 ticks：

```solidity
if (
    lowerTick >= upperTick ||
    lowerTick < MIN_TICK ||
    upperTick > MAX_TICK
) revert InvalidTickRange();
```
并且确保流动性的数量不为零：

```solidity
if (amount == 0) revert ZeroLiquidity();
```

接下来，增加 `tick` 和 `position` 的信息：

```solidity
ticks.update(lowerTick, amount);
ticks.update(upperTick, amount);

Position.Info storage position = positions.get(
    owner,
    lowerTick,
    upperTick
);
position.update(amount);
```

`ticks.update` 函数如下所示：

```solidity
// src/lib/Tick.sol
function update(
    mapping(int24 => Tick.Info) storage self,
    int24 tick,
    uint128 liquidityDelta
) internal {
    Tick.Info storage tickInfo = self[tick];
    uint128 liquidityBefore = tickInfo.liquidity;
    uint128 liquidityAfter = liquidityBefore + liquidityDelta;

    if (liquidityBefore == 0) {
        tickInfo.initialized = true;
    }

    tickInfo.liquidity = liquidityAfter;
}
```
它初始化一个流动性为 `0` 的 `tick`，并且在上面添加新的流动性。
正如上面所示，我们会在下限 `tick` 和上限 `tick` 处均调用此函数，流动性在两边都有添加。

`position.update` 函数如下所示:
```solidity
// src/libs/Position.sol
function update(Info storage self, uint128 liquidityDelta) internal {
    uint128 liquidityBefore = self.liquidity;
    uint128 liquidityAfter = liquidityBefore + liquidityDelta;

    self.liquidity = liquidityAfter;
}
```
与 `tick` 的函数类似，它也在特定的位置上添加流动性。其中的 `get` 函数如下：

```solidity
// src/libs/Position.sol
function get(
    mapping(bytes32 => Info) storage self,
    address owner,
    int24 lowerTick,
    int24 upperTick
) internal view returns (Position.Info storage position) {
    position = self[
        keccak256(abi.encodePacked(owner, lowerTick, upperTick))
    ];
}
...
```
每个位置都由三个变量所确定：拥有流动性的地址，下限 `tick`，上限 `tick` 。

我们将这三个变量哈希来减少数据存储开销：哈希结果只有 `32` 字节，而三个变量分别存储需要 `96` 字节。

让我们继续完成 `mint` 函数。接下来我们需要计算用户需要质押 `token` 的数量，幸运的是，我们在上一章中已经用公式计算出了对应的数值。在这里我们会在代码中硬编码这些数据：

```solidity
amount0 = 0.998976618347425280 ether;
amount1 = 5000 ether;
```

> 在后面的章节中，我们会把这里替换成真正的计算。

现在，我们可以从用户处获得 `token` 了。这部分是通过 `callback` 来实现的：

```solidity
uint256 balance0Before;
uint256 balance1Before;
if (amount0 > 0) balance0Before = balance0();
if (amount1 > 0) balance1Before = balance1();
IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
    amount0,
    amount1
);
if (amount0 > 0 && balance0Before + amount0 > balance0())
    revert InsufficientInputAmount();
if (amount1 > 0 && balance1Before + amount1 > balance1())
    revert InsufficientInputAmount();
```

首先，我们记录下现在的 `token` 余额。接下来我们调用caller的 `uniswapV3MintCallback` 方法。

预期调用者为合约地址，因为普通用户地址无法实现 `callback` 函数。使用 `callback` 函数看起来很不用户友好，但是这能够让合约计算 `token` 的数量——这非常关键，因为我们无法信任用户。

调用者需要实现 `uniswapV3MintCallback` 来将 `token` 转给池子合约。
调用 `callback` 函数后，我们会检查池子合约的对应余额是否发生变化，并且增量应该大于 `amount0` 和 `amount1`：这意味着调用者已经把 `token` 转到了池子。

```solidity
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        UniswapV3Pool.CallbackData memory extra = abi.decode(
            data,
            (UniswapV3Pool.CallbackData)
        );

        ERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        ERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }
```
最后，发出一个 `Mint` 事件：

```solidity
emit Mint(msg.sender, owner, lowerTick, upperTick, amount, amount0, amount1);
```