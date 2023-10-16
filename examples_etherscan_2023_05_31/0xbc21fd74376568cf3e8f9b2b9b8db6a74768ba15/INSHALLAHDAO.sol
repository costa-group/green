// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Ownable } from "./Ownable.sol";
import { ERC20 } from "./ERC20.sol";

contract INSHALLAHDAO is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address user => bool state) public blacklists;

    constructor(
        uint256 _totalSupply,
        address _lpWallet,
        address _airdropWallet,
        address _cexWallet
    ) ERC20("Inshallah DAO", "INSHALLAH") {
        _mint(_lpWallet, (_totalSupply * 10 ** 18 * 890) / 1000); // 89% for LP
        _mint(_airdropWallet, (_totalSupply * 10 ** 18 * 60) / 1000); // 6% for airdrop
        _mint(_cexWallet, (_totalSupply * 10 ** 18 * 50) / 1000); // 5% for cex listings
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(
        bool _limited,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}