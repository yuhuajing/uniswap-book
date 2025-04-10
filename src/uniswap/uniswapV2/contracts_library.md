# UniswapV2Library
## UniswapV2库
`Uniswap V2` 库简化了一些与配对合约的交互，并被路由合约大量使用。

它包含八个不改变状态的函数。它们对于从智能合约集成 `Uniswap V2` 也很方便。

### 根据交易池输入计算输出 getAmountOut()
$$\Delta y = \frac{y r \Delta x}{x + r \Delta x}$$

`UniswapV2` 交易会抽取0.3%的手续费，作为提供流动性的奖励（计算恒定乘积的时候扣除手续费，但是交易池整体的余额增加，导致整体的乘积上涨,每笔交易都会让恒定乘积上涨。)

```solidity
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
```
### 根据交易池输出反推输入 getAmountIn()
$$\Delta x = \frac{x \Delta y}{r(y - \Delta y)}$$

```solidity
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }
```
### 多个池子间连续兑换 getAmountsOut()
如果交易者提供一系列对: `（A，B），（B，C），（C，D）`,预测输入 `A` 代币后输出的 `D` 代币数量

> 在 (A,B) 池中，将 A 代币作为输入，预估 B 代币的输出数量
> 
> 在（B,C) 中，将 B 代币作为输入，预估 C 代币的输出数量
> 
> 在（C，D) 中，将 C 代币作为输入，预估 D 代币的输出数量

```solidity
    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
```


### 多个池子间连续兑换 getAmountsIn()
如果交易者提供一系列对: `（A，B），（B，C），（C，D）`,想要得到 `D` 代币，计算预估需要输入 `A` 代币的数量

> 在 (C,D) 池中，将 D 代币作为输出，预估 C 代币的输入数量
>
> 在（B,C) 中，将 C 代币作为输出，预估 B 代币的输入数量
>
> 在（A,B) 中，将 B 代币作为输出，预估 A 代币的输入数量

```solidity
    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
```
### 获取池子函数 pairFor 和 sortTokens

```solidity
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
```

### quote()
以当前价格为锚点，计算在特定价格的场景下，`A` 代币可以购买得到的 `B` 代币数量
```solidity
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
```


## Reference
- [https://www.rareskills.io/post/uniswap-v2-library](https://www.rareskills.io/post/uniswap-v2-library)
- [https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol](https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol)