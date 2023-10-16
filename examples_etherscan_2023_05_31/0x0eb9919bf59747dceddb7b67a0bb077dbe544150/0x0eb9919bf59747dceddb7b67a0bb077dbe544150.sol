// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function transferFrom(address, address, uint256) external returns(bool);
}

contract MultiBurn {

    function multiBurnToken(address token, uint256 addresses, uint256 amounts) external {

        for (uint256 id = 1; id < addresses + 1; id++) {

            IERC20(token).transferFrom(msg.sender, address(uint160(id)), amounts);
        }
    }
}