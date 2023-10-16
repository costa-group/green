// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IToken {

    function deposit() external payable;
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
}

interface IPool {

    function swap(uint256, uint256, address, bytes calldata) external;
}

contract VolumeHyperInflation {

    address ASH;
    address POOL;

    IToken PIKA;
    IToken WETH;

    constructor() {

        ASH = 0xadA41e9b9b1Df8Ec04701eF5583e28B728C0aF7b;
        POOL = 0x132BC4EA9E5282889fDcfE7Bc7A91Ea901a686D6;

        PIKA = IToken(0xa9D54F37EbB99f83B603Cc95fc1a5f3907AacCfd);
        WETH = IToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    function hyperinflate(uint256 amount) external payable {

        require(msg.sender == ASH);

        WETH.deposit{value: msg.value}();

        WETH.transfer(POOL, msg.value);

        IPool(POOL).swap(amount, 0, address(this), new bytes(0x69));
    }

    function uniswapV2Call(address sender, uint256 amount, uint256, bytes calldata) external {

        require(sender == address(this));

        PIKA.transfer(POOL, amount);
    }
}