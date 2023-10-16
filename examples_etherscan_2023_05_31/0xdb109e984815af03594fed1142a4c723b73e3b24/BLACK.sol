// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Black is ERC20 {
    constructor() ERC20("BLACK", "BLACK") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}