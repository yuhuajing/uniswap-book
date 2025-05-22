# 多池子交易
在合约中实现多池子交易。
## 更新管理员合约
### 单池和多池交易

```solidity
struct SwapSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 tickSpacing;
    uint256 amountIn;
    uint160 sqrtPriceLimitX96;
}

struct SwapParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 minAmountOut;
}
```

1. `SwapSingleParams` 的参数为池子参数、输入数量，以及一个限制价格——这与我们之前的基本一致。
2. `SwapParams` 的参数为路径、输出金额接受方、输入数量，以及最小输出数量。
最后一个参数替代了 `sqrtPriceLimitX96`，因为在多池子交易中不再能使用池子合约中的滑点保护
（使用限价机制实现）
3. 我们需要另实现一个滑点保护，检查最终的输出数量并且与 `minAmountOut` 对比：
当最终输出数量小于 `minAmountOut` 的时候交易会失败。

### 核心交易逻辑

我们现在实现一个内部的 `_swap` 函数，会被单池交易和多池交易的函数调用。它的功能就是准备参数并且调用 `Pool.swap`：

```solidity
function _swap(
    uint256 amountIn,
    address recipient,
    uint160 sqrtPriceLimitX96,
    SwapCallbackData memory data
) internal returns (uint256 amountOut) {
```

`SwapCallbackData` 是一个新的数据结构，
包含需要在 `swap` 函数和 `UniswapV3Callback` 之间传递的数据：

```solidity
struct SwapCallbackData {
    bytes path;
    address payer;
}
```

`path` 是交易路径，`payer` 是在这笔交易中付出 `token` 的地址——在多池交易中这个付款者会有所不同。

在 `_swap` 中要做的第一件事就是使用 `Path` 库来提取池子参数：

```solidity
// function _swap(...) {
(address tokenIn, address tokenOut, uint24 tickSpacing) = data
    .path
    .decodeFirstPool();
```

然后确认交易方向：

```solidity
bool zeroForOne = tokenIn < tokenOut;
```

接下来执行真正的交易：

在这里调用 `getPool` 来找到池子,调用池子的 `swap` 函数
```solidity
// function _swap(...) {
(int256 amount0, int256 amount1) = getPool(
    tokenIn,
    tokenOut,
    tickSpacing
).swap(
        recipient,
        zeroForOne,
        amountIn,
        sqrtPriceLimitX96 == 0
            ? (
                zeroForOne
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1
            )
            : sqrtPriceLimitX96,
        abi.encode(data)
    );
```

### 单池交易

`swapSingle` 仅仅是 `_swap` 包装起来而已：

```solidity
function swapSingle(SwapSingleParams calldata params)
    public
    returns (uint256 amountOut)
{
    amountOut = _swap(
        params.amountIn,
        msg.sender,
        params.sqrtPriceLimitX96,
        SwapCallbackData({
            path: abi.encodePacked(
                params.tokenIn,
                params.tickSpacing,
                params.tokenOut
            ),
            payer: msg.sender
        })
    );
}
```

注意到在这里构造了一个单池的路径：单池交易是仅有一个池子的多池交易。

### 多池交易

多池交易仅仅比单池交易复杂一点

```solidity
function swap(SwapParams memory params) public returns (uint256 amountOut) {
    address payer = msg.sender;
    bool hasMultiplePools;
    ...
```

第一笔交易是由用户付费，因为用户提供最开始输入的 `token`。

接下来，开始遍历路径中的池子：

```solidity
while (true) {
    hasMultiplePools = params.path.hasMultiplePools();

    params.amountIn = _swap(
        params.amountIn,
        hasMultiplePools ? address(this) : params.recipient,
        0,
        SwapCallbackData({
            path: params.path.getFirstPool(),
            payer: payer
        })
    );
    ...
```

在每一次循环中，用这些参数调用 `_swap` 函数：
- `params.amountIn` 跟踪输入的数量。 
  - 在第一笔交易中这个数量由用户提供
  - 在后面的交易中这个数量是来自于前一笔交易的输出数量。
- `hasMultiplePools ? address(this) : params.recipient`
  - 如果路径中有多个池子，收款方是管理合约，它存储中间交易得到的 `token`。
  - 如果在路径中仅剩一个交易（最后一笔），收款人应该是之前参数中设定的地址（通常是创建交易的人）。
- `sqrtPriceLimitX96` 设置为 0，来禁用池子合约中的滑点保护 
- 最后一个参数是传递给 `uniswapV3SwapCallback` 

在完成一笔交易后，需要前往路径中的下一个池子，或者返回.

在这里修改付款人并且从路径中移除已处理的池子:

```solidity
    ...

    if (hasMultiplePools) {
        payer = address(this);
        params.path = params.path.skipToken();
    } else {
        amountOut = params.amountIn;
        break;
    }
}
```

最后，新的滑点保护：

```solidity
if (amountOut < params.minAmountOut)
    revert TooLittleReceived(amountOut);
```

### Swap Callback

```solidity
function uniswapV3SwapCallback(
    int256 amount0,
    int256 amount1,
    bytes calldata data_
) public {
    SwapCallbackData memory data = abi.decode(data_, (SwapCallbackData));
    (address tokenIn, address tokenOut, ) = data.path.decodeFirstPool();

    bool zeroForOne = tokenIn < tokenOut;

    int256 amount = zeroForOne ? amount0 : amount1;

    if (data.payer == address(this)) {
        IERC20(tokenIn).transfer(msg.sender, uint256(amount));
    } else {
        IERC20(tokenIn).transferFrom(
            data.payer,
            msg.sender,
            uint256(amount)
        );
    }
}
```

`callback` 函数在 `data_` 段获得包含路径和付款人地址的 `SwapCallbackData`。

它从路径中提取 `token` 地址，识别交易方向，以及该合约需要转出的金额。

接下来，它根据付款人的不同而进行不同行为：
1. 如果付款人是当前合约（在连续交易时，当前合约作为中间人），它直接将本合约账户下的 `token` 转到下一个池子（调用这个 `callback` 的池子）。
2. 如果付款人是一个不同的地址（创建交易的用户），它从用户那里把 `token` 转给池子。
