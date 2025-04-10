# 第一笔交易

在本章中，我们将会搭建一个流动性池合约，它能够接受用户的流动性并且在某个价格区间内做交易。
简单起见，我们仅在一个价格区间内提供流动性，并且仅允许单向的交易。
另外，为了更好地理解其中的数学原理，我们将手动计算其中用到的数学参数，暂不使用 `Solidity` 的数学库进行计算。

我们本章中要搭建的模型如下：
1. 这是一个 `ETH/USDC` 的池子合约。ETH是资产 $x$，USDC是资产 $y$；
2. 现货价格将被设置为一个 `1 ETH, 5000 USDC`；
3. 我们提供流动性的价格区间为一个ETH对 `4545 - 5500 USDC`；
4. 我们将会从池子中购买 `ETH`，并且保证价格在上述价格区间内。

模型的图像大致如下：

![Buy ETH for USDC visualization](../images/milestone_1/buy_eth_model.png)

在开始代码部分之前，我们首先会手动计算模型中用到的所有数学参数。
简单起见，我将使用 `Python` 来进行计算而不是 `Solidity`，因为 `Solidity` 在数学计算上有很多细微之处需要考虑。
因此在这章，我们将会把所有的参数硬编码进池子合约里。这会让我们获得一个最小可用的产品。

本章中所有用到的 python 计算都在 [unimath.py](https://github.com/Jeiwan/uniswapv3-code/blob/main/unimath.py)。
```go
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
