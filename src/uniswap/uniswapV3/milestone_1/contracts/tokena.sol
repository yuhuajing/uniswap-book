// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

/// @title ERC20MultiTransferOwnable
/// @author Solady (https://github.com/Vectorized/solady/blob/main/src/tokens/ERC20.sol)
contract MyToken is ERC20, Ownable {
    /*               ERC20 METADATA AND CONSTRUCTOR               */
    // Add state variables for name, symbol, and decimals
    string  name_;
    string  symbol_;
    uint8  immutable decimals_;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner
    ) {
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
        _initializeOwner(_owner);
    }

    /// @dev Returns the name of the token
    function name() public view virtual override returns (string memory) {
        return name_;
    }

    /// @dev Returns the symbol of the token
    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    /// @dev Returns the number of decimals used to get its user representation
    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}

