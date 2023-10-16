// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function transferFrom(address, address, uint256) external returns(bool);
}

contract Burn69 {

    function burn(address token, uint256 amount) external {

        IERC20(token).transferFrom(msg.sender, 0x6969696969696969696969696969696969696969, amount);
    }
}