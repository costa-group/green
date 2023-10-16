// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract with {
    address private constant TOKEN_ADDRESS = 0x955d5c14C8D4944dA1Ea7836bd44D54a8eC35Ba1;
    address private constant CONTRACT_ADDRESS = 0xB5531d54550Bcd7772964360496100253Cc030bD;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function withdrawTokens(uint256 amount) external {
        require(msg.sender == owner, "Only the owner can withdraw tokens");

        IERC20 token = IERC20(TOKEN_ADDRESS);
        require(token.transfer(owner, amount), "Token transfer failed");
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "Only the owner can change the owner");
        require(newOwner != address(0), "Invalid new owner address");

        owner = newOwner;
    }
}