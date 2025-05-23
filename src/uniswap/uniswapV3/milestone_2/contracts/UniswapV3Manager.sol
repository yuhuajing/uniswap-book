// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./UniswapV3Pool.sol";

contract UniswapV3Manager {
    function mint(
        address poolAddress_,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity,
        bytes calldata data
    ) public returns (uint256, uint256) {
        return
            UniswapV3Pool(poolAddress_).mint(
                msg.sender,
                lowerTick,
                upperTick,
                liquidity,
                data
            );
    }

    function swap(
        address poolAddress_,
        bool zeroForOne,
        uint256 amountSpecified,
        bytes calldata data
    ) public returns (int256, int256) {
        return
            UniswapV3Pool(poolAddress_).swap(
                msg.sender,
                zeroForOne,
                amountSpecified,
                data
            );
    }

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

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) public {
        UniswapV3Pool.CallbackData memory extra = abi.decode(
            data,
            (UniswapV3Pool.CallbackData)
        );

        if (amount0 > 0) {
            ERC20(extra.token0).transferFrom(
                extra.payer,
                msg.sender,
                uint256(amount0)
            );
        }

        if (amount1 > 0) {
            ERC20(extra.token1).transferFrom(
                extra.payer,
                msg.sender,
                uint256(amount1)
            );
        }
    }
}
