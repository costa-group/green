// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IToken {

    function deposit() external payable;
    function transfer(address, uint256) external returns(bool);
}

interface IPool {

    function getReserves() external view returns(uint256, uint256);
    function swap(uint256, uint256, address, bytes calldata) external;
}

contract VolumeHyperInflation {

    address POOL;

    IToken PIKA;
    IToken WETH;

    constructor() {

        POOL = 0x132BC4EA9E5282889fDcfE7Bc7A91Ea901a686D6;

        PIKA = IToken(0xa9D54F37EbB99f83B603Cc95fc1a5f3907AacCfd);
        WETH = IToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    function hyperinflate() external payable {

        WETH.deposit{value: msg.value}();

        WETH.transfer(POOL, msg.value);

        (uint256 reservePIKA, uint256 reserveWETH) = IPool(POOL).getReserves();

        IPool(POOL).swap(reservePIKA - 1, reserveWETH - 1, address(this), new bytes(0x69));
    }

    function uniswapV2Call(address, uint256 amountPIKA, uint256 amountWETH, bytes calldata) external {

        PIKA.transfer(POOL, amountPIKA);

        WETH.transfer(POOL, amountWETH);
    }
}