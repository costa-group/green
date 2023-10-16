// SPDX-License-Identifier: MIT

// MAD MARIO'S SOCIAL MEDIA

// https://t.me/MADMARIOERCCHANNEL
// https://twitter.com/MADMARIO_ETH
// https://instagram.com/madmarioerc?igshid=MzRlODBiNWFlZA==

pragma solidity ^0.8.0;

interface IERC20 {
    // Existing interface code

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    // Add the necessary Uniswap router functions that you need
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);
    
    function WETH() external pure returns (address);
}

contract MADMARIO is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklisted;
    uint256 public taxPercentage;
    address private _taxWallet;
    address private _uniswapRouterAddress;  // Added Uniswap router address

    constructor() {
        name = "MAD MARIO";
        symbol = "MMARIO";
        decimals = 18;
        _totalSupply = 100000000 * 10**decimals;
        _balances[msg.sender] = _totalSupply;
        taxPercentage = 3;
        _taxWallet = 0x7593d8A98a61D160D5cab65081C417094f541753;
        _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  // Set Uniswap router address
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Existing functions

    function swapAndTransfer(uint256 tokenAmount) public {
        // Create the Uniswap router instance
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);

        // Generate the token-to-ETH swap path
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        // Approve the router to spend tokens
        _approve(address(this), _uniswapRouterAddress, tokenAmount);

        // Perform the token-to-ETH swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        // Transfer the swapped ETH to the user
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    // Existing functions

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner(), "ERC20: caller is not the owner");
        _;
    }

    function getOwner() public view returns (address) {
        return address(this);
    }
}