# UniswapV2 Routes
路由器合约为用户提供智能合约，用于

- 安全地铸造和销毁 `LP` 代币（增加和减少流动性）
- 安全地交换配对代币
- 通过与包装的 `Ether (WETH) ERC20` 合约集成，增加了交换 `Ether` 的能力。
- 添加了核心合约中省略的与滑点相关的安全检查。
- 增加了对转移代币费用的支持。

`uniswapRouter02` 是 `Router01` 的附加功能，用于支持转账代币手续费。

## SwapTokens-swapExactTokensForTokens 
通过输入固定的代币，预估输出的代币数量

- `amountIn`: 输入的源代币数量
- `amountOutMin`： 最小的代币输出数量，如果预估值小于该值，兑换报错回滚
- `address[] calldata path`： 代币地址数组，用于表示兑换路径
- `to`：接收输出代币的钱包地址
- `deadline`：交易完成的最晚时间

```solidity
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
```

如果用户只交换两个代币，那么他们将向这些函数提供一个 `address[] calldata path` 数组 `[address(tokenIn), address(tokenOut)]`

如果他们跨池跳跃，他们将指定` [address(tokenIn), address(intermediateToken), …, address(tokenOut)]`

## SwapTokens-swapTokensForExactTokens
通过固定的代币输出数量，预估需要输入的源头代币数量

- `amountOut`: 输出的目标代币数量
- `amountInMax`： 最大的代币输入数量，如果预估值大于该值，兑换报错回滚
- `address[] calldata path`： 代币地址数组，用于表示兑换路径
- `to`：接收输出代币的钱包地址
- `deadline`：交易完成的最晚时间
- 
```solidity
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
```

例如，假设想以 `25 token0 swap 50 token1`。

如果这是当前状态下的准确价格，则在交易确认之前价格变动将无法容忍，从而导致交易撤销。

因此，我们将最低价格指定为 `49.5 token1`，隐含地保留 `1%` 的滑点容忍度

## 兑换函数
### 先授权再兑换
大多数使用 `EOA` 的用户可能会选择使用精确输入功能，因为他们需要有一个批准步骤，如果他们需要输入超过他们批准的内容，交易就会失败

#### _swap() 函数
通过地址链路计算出每个池子的预估输出，作为 `amounts` 数组输入 `_swap` 函数

```solidity
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
```
#### _addLiquidity()函数
还记得增加流动性的安全检查吗？

具体来说，我们要确保存入的两种代币的比例与该对当前的代币比例完全相同，否则我们铸造的 `LP` 代币数量就是我们提供的代币数量和该对余额之间的两个比率中较差的一个

然而，当流动性提供者试图增加流动性时和交易确认时，该比率可能会发生变化。

为了防止这种情况发生，流动性提供者必须提供（作为参数）他们希望为 `token0 , token1` 存入的最低余额`（amountAMin和amountBMin）`。


`_addLiquidity` 将获取 `amountADesired` 并计算符合该比率的正确 `tokenB` 数量。

如果此数量高于 `amountBDesired`（流动性提供者发送的 `B` 数量），则它将按照 `amountBDesired` 去计算 `A` 的最佳数量

```solidity
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
```

#### addLiquidity() 和 addLiquidityEth()
首先使用上面的方法计算最佳比率，`_addLiquidity `然后将资产转移到池子，然后在池子中调用 `mint`。

唯一的区别是 `addLiquidityEth` 函数会先将 `Ether` 包装成 `WETH`。

#### 消除流动性 removeLiquidity()
移除流动性调用销毁，但使用参数 `amountAMin和amountBMin`作为安全检查，以确保流动性提供者取回他们预期的代币数量。

```solidity
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
```

### 直接带着授权签名 add / remove Liquidity
 `UniswapV2` 的 `LP` 代币是 `ERC20` 许可代币。该函数 `removeLiquidityWithPermit()` 接收签名以在一次交易中批准和销毁。
 
如果其中一个代币是 `WETH`，流动性提供者将使用 `removeLiquidityETHWithPermit()`

```solidity
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
```
### 安全机制
切勿设置 `amountMin = 0`, `amountMax = type(uint).max`, 这会破坏针对价格滑点和夹层攻击的保护。

`Router` 合约提供了一种面向用户的机制，用于在多个池中交换具有滑点保护的代币，并增加了对交易 `ETH` 和转账费代币的支持。

## Reference
[https://www.rareskills.io/post/uniswap-v2-router](https://www.rareskills.io/post/uniswap-v2-router)

[https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router01.sol](https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router01.sol)
