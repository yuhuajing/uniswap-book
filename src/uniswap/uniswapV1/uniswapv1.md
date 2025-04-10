# UniswapV1 In Solidity

## Factory工厂合约
```solidity
pragma solidity ^0.8.0;

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

## Exchange


```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens, address recipient)
    external
    payable;

    function ethToTokenTransfer(uint256 _minTokens, address _recipient)
    external
    payable;
}

interface IFactory {
    function getExchange(address _tokenAddress) external returns (address);

    function getToken(address exchange) external returns (address);
}

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    constructor(address _token) ERC20("Uniswap-V1", "UNI1") {
        require(_token != address(0), "invalid token address");

        tokenAddress = _token;
        factoryAddress = msg.sender;
    }

    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) public payable {
        require(deadline > block.timestamp);
        require(msg.value > 0 && max_tokens > 0);
        uint256 total_liquidity = totalSupply();
        IERC20 token = IERC20(tokenAddress);
        if (total_liquidity == 0) {
            require(
                factoryAddress != address(0) &&
                tokenAddress != address(0) &&
                msg.value > 1 gwei
            );
            address exceptedExchange = IFactory(factoryAddress).getExchange(
                tokenAddress
            );
            require(exceptedExchange == address(this));
            token.transferFrom(msg.sender, address(this), max_tokens);
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
        } else {
            require(min_liquidity > 0);
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 _minTokenAmount = (msg.value * tokenReserve) /
                        ethReserve +
                        1; //向上取整
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            require(
                max_tokens >= _minTokenAmount && liquidity >= min_liquidity,
                "Insufficient token for liquidity"
            );

            token.transferFrom(msg.sender, address(this), _minTokenAmount);
            _mint(msg.sender, liquidity);
        }
    }

    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) public returns (uint256, uint256) {
        require(amount > 0, "Invalid amount");
        require(deadline > block.timestamp);
        uint256 ethAmount = (amount * address(this).balance) / totalSupply();
        uint256 tokenAmount = (amount * getReserve()) / totalSupply();

        require(ethAmount >= min_eth && tokenAmount >= min_tokens);
        _burn(msg.sender, amount);

        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        payable(msg.sender).transfer(ethAmount);

        return (ethAmount, tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // Swap fee: 3%
    // 通过存入的资产计算能够兑换到的资产数量
    function getInputPrice(
        uint256 input_amount,
        uint256 inReserve,
        uint256 outReserve
    ) public pure returns (uint256) {
        require(inReserve > 0 && outReserve > 0);
        uint256 inputAmountWithFee = input_amount * 997;
        uint256 numerator = outReserve * inputAmountWithFee;
        uint256 denominator = inReserve * 1000 + inputAmountWithFee;
        return numerator / denominator;
    }

    // 通过卖出资产计算能够兑换到的资产数量
    function getOutputPrice(
        uint256 output_amount,
        uint256 inReserve,
        uint256 outReserve
    ) public pure returns (uint256) {
        require(inReserve > 0 && outReserve > 0);
        uint256 numerator = inReserve * output_amount * 1000;
        uint256 denominator = 997 * (outReserve - output_amount);
        return numerator / denominator + 1;
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "Invalid Amount");

        return getInputPrice(_ethSold, address(this).balance, getReserve());
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "Invalid Amount");

        return getInputPrice(_tokenSold, getReserve(), address(this).balance);
    }

    function ethToTokenSwap(uint256 _minToken, address recipient)
    public
    payable
    {
        uint256 tokenAmount = getInputPrice(
            msg.value,
            address(this).balance - msg.value,
            getReserve()
        );
        require(tokenAmount >= _minToken, "Insufficient token amount");

        IERC20 token = IERC20(tokenAddress);
        token.transfer(recipient, tokenAmount);
    }

    function tokenToEthSwap(uint256 _minEth, uint256 _tokenSold) public {
        uint256 ethAmount = getEthAmount(_tokenSold);

        require(ethAmount >= _minEth, "Insufficient eth amount");

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenSold
        );
        payable(msg.sender).transfer(ethAmount);
    }

    function tokenToTokenSwap(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 _minBoughtTokenAmount,
        address _anotherToken,
        address recipient
    ) public {
        address exchangeAddress = IFactory(factoryAddress).getExchange(
            _anotherToken
        );
        require(exchangeAddress != address(0), "This token has no exchange.");

        uint256 tokenReserve = getReserve();
        uint256 ethBought = getInputPrice(
            tokens_sold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= min_eth_bought);

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokens_sold
        );

        IExchange(exchangeAddress).ethToTokenSwap{value: ethBought}(
            _minBoughtTokenAmount,
            recipient
        );
    }
}
```
## Tokens
```solidity
pragma solidity ^0.8.0;

contract Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}
```