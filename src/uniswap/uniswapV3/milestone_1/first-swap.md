# 第一笔交易
## 计算交易数量
1. 计算过程中的流动性保持不变
2. 需要根据当前流动性值和当前价格，根据输入的 tokens 数量计算目标价格
3. 根据目标价格和当前价格，计算另一种代币的输入/输出数量
4. 执行 swap 后，更新当前池子的兑换价格和 tick 位置

首先，需要知道如何计算交易出入的数量。
同样，我们在这小节中也会硬编码我们希望交易的 `USDC` 数额，这里我们选择  `42 USDC swap  ETH`。

在决定了我们希望投入的资金量之后，需要计算我们会获得多少 `ETH token`。
在 `UniswapV2` 中，我们会使用当前池子的资产数量来计算，
但是在 V3 中我们有 $L$ 和 $\sqrt{P}$，
并且我们知道在交易过程中，$L$ 保持不变而只有 $\sqrt{P}$ 发生变化
（当在同一区间内进行交易时，`V3` 的表现和 `V2` 一致）。我们还知道如下公式：

$$L = \frac{\Delta y}{\Delta \sqrt{P}}$$

并且，在这里我们知道了$\Delta y$。它正是我们希望投入的 `42 USDC`。
因此，我们可以根据公式得出投入的 `42 USDC` 会对价格造成多少影响：


$$\Delta \sqrt{P} = \frac{\Delta y}{L}$$

在 `V3` 中，我们得到了**我们交易导致的价格变动**（回忆一下，交易使得现价沿着曲线移动）。
知道了目标价格(`target price`)，合约可以计算出投入 `USDC` 的数量和输出 `ETH` 的数量。

注意，$\sqrt{P}$ 用 Q64.96 定点数表示

我们将数字代入上述公式：

$$\Delta \sqrt{P} = \frac{42 \enspace USDC}{1517882343751509868544} * 2^{96} = 2192253463713690532467206957$$

把差价加到现在的 $\sqrt{P}$，我们就能得到目标价格：

`USDC` 兑换 `ETH` 会减少池子中 `ETH` 的数量，因此 `ETH` 的价格会上涨 

$$\sqrt{P_{target}} - \sqrt{P_{current}} = \Delta \sqrt{P}$$

$$\sqrt{P_{target}} = \sqrt{P_{current}} + \Delta \sqrt{P}$$

$$\sqrt{P_{target}} = 5602277097478614198912276234240 + 2192253463713690532467206957 = 5604469350942327889444743441197$$

> 在 Python 中进行相应计算:
> ```python
> amount_in = 42 * eth
> price_diff = (amount_in * q96) // liq
> price_next = sqrtp_cur + price_diff
> print("New price:", (price_next / q96) ** 2)
> print("New sqrtP:", price_next)
> print("New tick:", price_to_tick((price_next / q96) ** 2))
> # New price: 5003.913912782393
> # New sqrtP: 5604469350942327889444743441197
> # New tick: 85184
> ```

知道了目标价格，我们就能计算出投入 `USDC` 的数量和获得 `ETH` 的数量：

$$\Delta x = \Delta \frac{L}{\sqrt{p}} / 2^{96}  = L * (\frac{1}{\sqrt{p_b}} - \frac{1}{\sqrt{p_c}}) / 2 ^{96} = \frac{L(\sqrt{p_b}-\sqrt{p_c})}{\sqrt{p_b}\sqrt{p_c}} / 2 ^ {96}$$
$$\Delta y = L(\sqrt{p_b}-\sqrt{p_c}) / 2 ^{96} $$

> 用Python:
> ```python
> amount_in = calc_amount1(liq, price_next, sqrtp_cur)
> amount_out = calc_amount0(liq, price_next, sqrtp_cur)
> 
> print("USDC in:", amount_in / eth)
> print("ETH out:", amount_out / eth)
> # USDC in: 42.0
> # ETH out: 0.008396714242162444
> ```

我们使用另一个公式验证一下：

$$\Delta x = \Delta \frac{1}{\sqrt{P}} L$$

使用上述公式，在知道价格变动和流动性数量的情况下，我们能求出我们购买了多少 ETH，也即 $\Delta x$。一个需要注意的点是： $\Delta \frac{1}{\sqrt{P}}$ 不等于
$\frac{1}{\Delta \sqrt{P}}$！前者才是 ETH 价格的变动，并且能够用如下公式计算：

$$\Delta \frac{1}{\sqrt{P}} = \frac{1}{\sqrt{P_{target}}} - \frac{1}{\sqrt{P_{current}}}$$

我们知道了公式里面的所有数值，接下来将其带入即可（可能会在显示上有些问题）：

$$\Delta \frac{1}{\sqrt{P}} = \frac{1}{5604469350942327889444743441197} - \frac{1}{5602277097478614198912276234240}$$

$$\Delta \frac{1}{\sqrt{P}} = -0.00000553186106731426$$

接下来计算 $\Delta x$:

$$\Delta x = -0.00000553186106731426 * 1517882343751509868544 = -8396714242162698 $$

即 0.008396714242162698 ETH，这与我们第一次算出来的数量非常接近！注意到这个结果是负数，因为我们是从池子中提出 ETH。

## 实现swap

交易在 `swap` 函数中实现：
```solidity
function swap(address recipient)
    public
    returns (int256 amount0, int256 amount1)
{
```

此时，它仅仅接受一个 `recipient` 参数，即提出 `token` 的接收者。

首先，我们需要计算出目标价格和对应 `tick`，以及 `token` 的数量。
同样，我们将会在这里硬编码我们之前计算出来的值：

```solidity
int24 nextTick = 85184;
uint160 nextPrice = 5604469350942327889444743441197;

amount0 = -0.008396714242162444 ether;
amount1 = 42 ether;
```

接下来，我们需要更新现在的 tick 和对应的 `sqrtP`：

```solidity
(slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);
```

然后，`manager` 合约把对应的 `token` 发送给 `recipient` 并且让调用者将需要的 `token` 转移到本合约：

```solidity
IERC20(token0).transfer(recipient, uint256(-amount0));

uint256 balance1Before = balance1();
IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
    amount0,
    amount1
);
if (balance1Before + uint256(amount1) < balance1())
    revert InsufficientInputAmount();
```

我们使用 `callback` 函数来将控制流转移到调用者，
让它转入 `token`，之后我们需要通过检查确认 `caller` 转入了正确的数额。

最后，合约释放出一个 `swap` 事件，使得该笔交易能够被监听到。这个事件包含了所有有关这笔交易的信息：

```solidity
emit Swap(
    msg.sender,
    recipient,
    amount0,
    amount1,
    slot0.sqrtPriceX96,
    liquidity,
    slot0.tick
);
```
本章中所有用到的 python 计算都在 [unimath.py](https://github.com/Jeiwan/uniswapv3-code/blob/main/unimath.py)。
```python
import math

min_tick = -887272
max_tick = 887272

q96 = 2**96
eth = 10**18


def price_to_tick(p):
    return math.floor(math.log(p, 1.0001))


def price_to_sqrtp(p):
    return int(math.sqrt(p) * q96)


def sqrtp_to_price(sqrtp):
    return (sqrtp / q96) ** 2


def tick_to_sqrtp(t):
    return int((1.0001 ** (t / 2)) * q96)


def liquidity0(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (amount * (pa * pb) / q96) / (pb - pa)


def liquidity1(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return amount * q96 / (pb - pa)


def calc_amount0(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * q96 * (pb - pa) / pb / pa)


def calc_amount1(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return int(liq * (pb - pa) / q96)


# Liquidity provision
price_low = 4545
price_cur = 5000
price_upp = 5500

print(f"Price range: {price_low}-{price_upp}; current price: {price_cur}")

sqrtp_low = price_to_sqrtp(price_low)
sqrtp_cur = price_to_sqrtp(price_cur)
sqrtp_upp = price_to_sqrtp(price_upp)

amount_eth = 1 * eth
amount_usdc = 5000 * eth

liq0 = liquidity0(amount_eth, sqrtp_cur, sqrtp_upp)
liq1 = liquidity1(amount_usdc, sqrtp_cur, sqrtp_low)
liq = int(min(liq0, liq1))

print(f"Deposit: {amount_eth/eth} ETH, {amount_usdc/eth} USDC; liquidity: {liq}")

# Swap USDC for ETH
amount_in = 42 * eth

print(f"\nSelling {amount_in/eth} USDC")

price_diff = (amount_in * q96) // liq
price_next = sqrtp_cur + price_diff

print("New price:", (price_next / q96) ** 2)
print("New sqrtP:", price_next)
print("New tick:", price_to_tick((price_next / q96) ** 2))

amount_in = calc_amount1(liq, price_next, sqrtp_cur)
amount_out = calc_amount0(liq, price_next, sqrtp_cur)

print("USDC in:", amount_in / eth)
print("ETH out:", amount_out / eth)

# Swap ETH for USDC
amount_in = 0.01337 * eth

print(f"\nSelling {amount_in/eth} ETH")

price_next = int((liq * q96 * sqrtp_cur) // (liq * q96 + amount_in * sqrtp_cur))

print("New price:", (price_next / q96) ** 2)
print("New sqrtP:", price_next)
print("New tick:", price_to_tick((price_next / q96) ** 2))

amount_in = calc_amount0(liq, price_next, sqrtp_cur)
amount_out = calc_amount1(liq, price_next, sqrtp_cur)

print("ETH in:", amount_in / eth)
print("USDC out:", amount_out / eth)
```