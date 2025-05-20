# 报价合约

用户会输入希望卖出的 `tokena` 数量，
然后就能计算并且展示出它们会获得的 `tokenb` 数量。

由于 `UniswapV3` 中的流动性是分散在多个价格区间中的，我们不能够仅仅通过一个公式计算出对应数量.

`UniswapV3` 的设计需要我们用一种不同的方法：

为了获得交易数量，我们初始化一个真正的交易，
并且在 `callback` 函数中打断它，获取到之前计算出的对应数量。

也就是，我们将会模拟一笔真实的交易来计算输出数量！

```solidity
contract UniswapV3Quoter {
    struct QuoteParams {
        address pool;
        uint256 amountIn;
        bool zeroForOne;
    }

    function quote(QuoteParams memory params)
        public
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            int24 tickAfter
        )
    {
        ...
```

`Quoter` 合约仅实现了一个 `public` 的函数 `quote`。

Quoter是一个对于所有池子的通用合约，
因此它将池子地址作为一个参数。其他参数（`amountIn` 和 `zeroForOne`）都是模拟 `swap` 需要的参数。

```solidity
try
    IUniswapV3Pool(params.pool).swap(
        address(this),
        params.zeroForOne,
        params.amountIn,
        abi.encode(params.pool)
    )
{} catch (bytes memory reason) {
    return abi.decode(reason, (uint256, uint160, int24));
}
```

这个函数唯一实现的功能是调用池子合约的 `swap` 函数。

这个调用应当 `revert` 

```solidity
function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes memory data
) external view {
    address pool = abi.decode(data, (address));

    uint256 amountOut = amount0Delta > 0
        ? uint256(-amount1Delta)
        : uint256(-amount0Delta);

    (uint160 sqrtPriceX96After, int24 tickAfter) = IUniswapV3Pool(pool)
        .slot0();
```

在 swap 的 callback 中，我们收集我们想要的值：输出数量、新的价格以及对应的 tick。

接下来，我们将会把这些值保存下来并且 `revert`：

```solidity
assembly {
    let ptr := mload(0x40)
    mstore(ptr, amountOut)
    mstore(add(ptr, 0x20), sqrtPriceX96After)
    mstore(add(ptr, 0x40), tickAfter)
    revert(ptr, 96)
}
```
为了节约 gas，这部分使用 [Yul](https://docs.soliditylang.org/en/latest/assembly.html) 来实现，这是一个在 Solidity 中写内联汇编的语言。

1. `mload(0x40)` 读取下一个可用 memory slot 的指针（EVM 中的 memory 组织成 32 字节的 slot 形式）；
2. 在这个 memory slot，`mstore(ptr, amountOut)` 写入 `amountOut` 。
3. `mstore(add(ptr, 0x20), sqrtPriceX96After)` 在 `amountOut` 后面写入 `sqrtPriceX96After`。
4. `mstore(add(ptr, 0x40), tickAfter)` 在 `sqrtPriceX96After` 后面写入 `tickAfter`。
5. `revert(ptr, 96)` 会 revert 这个调用，并且返回 ptr 指向位置的 96 字节数据。

所以，我们实际上就是把我们需要的值的字节表示连接起来（也就是 `abi.encode()` 做的事）。

注意到偏移永远是 `32` 字节，即使 `sqrtPriceX96After` 大小只有 `20` 字节(`uint160`)，

`tickAfter` 大小只有 3 字节(`uint24`)。

这也是为什么我们能够使用 `abi.decode()` 来解码数据：

因为 `abi.encode()` 就是把所有的数编码成 `32` 字节。

## 回顾

我们来回顾一下以便于更好地理解这个算法：
1. `quote` 调用一个池子的 `swap` 函数，参数是输入的 token 数量和交易方向。
2. `swap` 进行一个真正的交易，运行一个循环来填满用户需要的数量。
3. 为了从用户那里获得 token，`swap` 会调用 caller 的 callback 函数。
4. 调用者（报价合约）实现了 callback，在其中它 revert 并且附带了输出数量、新的价格、新的 tick 这些信息。
5. revert 一直向上传播到最初的 `quote` 调用
6. 在 `quote` 中，这个 revert 被捕获，reason 被解码并作为了 `quote` 调用的返回值。

希望上面的解释能让你对这个流程更加清晰！

## Quoter 的限制

这样的设计有一个非常明显的限制之处：
由于 `quote` 调用了池子合约的 `swap` 函数，
而 `swap` 函数既不是 `pure` 的也不是 `view` 的（因为它修改了合约状态）;

`quoter` 也同样不能成为一个 `pure` 或者 `view` 的函数，即使它永远都不会修改合约的状态。

