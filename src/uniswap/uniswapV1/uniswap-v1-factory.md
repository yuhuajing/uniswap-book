# Uniswap V1
- 仅支持创建 `ETH-Token` 的交易对
- 同个交易池中只能进行 `ETH/Token` 的兑换
- 不同 `Token` 的兑换，需要不同交易池的参与
```solidity
@public
def createExchange(token: address) -> address:
    assert token != ZERO_ADDRESS
    assert self.exchangeTemplate != ZERO_ADDRESS
// 当前Token未创建过交易池
    assert self.token_to_exchange[token] == ZERO_ADDRESS
// 创建交易池
    exchange: address = create_with_code_of(self.exchangeTemplate)
// 记录交易对合约地址
    Exchange(exchange).setup(token)
    self.token_to_exchange[token] = exchange
    self.exchange_to_token[exchange] = token
    token_id: uint256 = self.tokenCount + 1
    self.tokenCount = token_id
    self.id_to_token[token_id] = token
    log.NewExchange(token, exchange)
    return exchange
```
## Solidity
1. 兑换池和 `Token` 绑定, 池子和 `Token` 双向映射
2. 相同的代币只能创建一个池子
3. 采用 `new` 关键字 `create` 新的池子合约
```solidity
contract Factory {
    mapping(address => address) tokenToExchange;
    mapping(address => address) exchange_to_token;

    function createExchange(address _token) public returns (address) {
        require(_token != address(0), "Invalid token address");
        require(
            tokenToExchange[_token] == address(0),
            "Exchange already registered."
        );
        Exchange exchange = new Exchange(_token);

        tokenToExchange[_token] = address(exchange);
        exchange_to_token[address(exchange)] = _token;

        return address(exchange);
    }

    function getExchange(address _token) public view returns (address) {
        return tokenToExchange[_token];
    }

    function getToken(address exchange) public view returns (address) {
        return exchange_to_token[exchange];
    }
}
```