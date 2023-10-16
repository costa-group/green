// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Queen is ERC20 {
    constructor() ERC20("Queen", "QUEEN") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}