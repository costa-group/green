/*
     ^          ^^       ^^^^         ^^^^^       ^^^        ^^^^^^
    ^^^        ^^^^     ^^^^^^       ^^^^^^^     ^^^^^      ^^^^^^^^
   ^^^^^      ^^^^^^   ^^^^^^^^     ^^^^^^^^^   ^^^^^^^    ^^^^^^^^^^
  ^^^^^^^    ^^^^^^^^ ^^^^^^^^^^   ^^^^^^^^^^^ ^^^^^^^^^  ^^^^^^^^^^^^
 ^^^^^^^^^  ^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^
     |          ||       |||          ||||        |||          ||||

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

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

/**
 *   Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     *   Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     *   Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     *   Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     *   Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     *   Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     *   Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

//pragma solidity ^0.8.19;

/**
 *   Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     *   Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     *   Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     *   Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     *   Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    /**
     *   Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     *   Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     *   Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

//pragma solidity ^0.8.19;

/**
 *   Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     *   Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     *   Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     *   Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     *   Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     *   Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     *   Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     *   Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     *   See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     *   See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     *   See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     *   See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     *   See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     *   See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     *   Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     *   Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**   Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    /**
     *   Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     *   Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     *   Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     *   Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File contracts/PixelTree.sol

contract PixelTree is Ownable, ERC20 {
    string constant _name = "PixelTree";
    string constant _symbol = "TREE";
    uint8 constant _decimals = 18;
    address public pair;

    mapping(address => bool) public blacklists;
    mapping(address => bool) public tradeExceptions;

    /** Max buy amount per tx */
    uint256 public constant MAX_BUY = 100_0_000 ether;
    /** Number of blocks to count as dead land */
    uint256 public constant DEADBLOCK_COUNT = 5;

    /** Deadblock start blocknum */
    uint256 public deadblockStart;
    /** Block contracts? */
    bool private _blockContracts;
    /** Limit buys? */
    bool private _limitBuys;
    /** Crowd control measures? */
    bool private _unrestricted;

    /** Developer wallet map with super access */
    mapping(address => bool) private whitelist;
    /** Used to watch for sandwiches */
    mapping(address => uint) private _lastBlockTransfer;

    /** Amount must be greater than zero */
    error NoZeroTransfers();
    /** Not allowed */
    error NotAllowed();
    /** Amount exceeds max transaction */
    error LimitExceeded();

    constructor(address _airdropAddress, address _marketingAddress, address _developmentAddress) ERC20(_name, _symbol) {
        // add addresses to exception
        tradeExceptions[msg.sender] = true;
        tradeExceptions[_airdropAddress] = true;
        tradeExceptions[_marketingAddress] = true;
        tradeExceptions[_developmentAddress] = true;

        uint256 _totalSupply = 1_420_000_000 * (10 ** _decimals);
        uint256 _airdropAllocation = (_totalSupply * 400) / 10000;
        uint256 _marketingAllocation = (_totalSupply * 240) / 10000;
        uint256 _developmentAllocation = (_totalSupply * 300) / 10000;

        uint256 _remainingAllocation = _totalSupply - (_airdropAllocation + _marketingAllocation + _developmentAllocation);
        
        _mint(msg.sender, _remainingAllocation);  // Mint tokens for the contract deployer
        
        // Mint additional tokens for airdrop, marketing, and airdrop addresses
        _mint(_airdropAddress, _airdropAllocation);
        _mint(_marketingAddress, _marketingAllocation);
        _mint(_developmentAddress, _developmentAllocation);

        _blockContracts = true;
        _limitBuys = true;
    }

    /**
    * Blacklist an address
    * @param _address Address to blacklist
    */
    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    /**
    * Sets pair, start trading
    * @param _pair Uniswap address
    */
    function setPair(address _pair) external onlyOwner {
        deadblockStart = block.number;
        pair = _pair;
    }

    /**
    * Checks for exception
    * @param _address Address to blacklist
    */
    function _isException(address _address) internal view returns (bool) {
        return tradeExceptions[_address];
    }

    /**
    * Add address to exception
    * @param _address Address to exception
    */
    function addException(address _address) external onlyOwner {
        tradeExceptions[_address] = true;
    }

    /**
    * Checks if address is contract
    * @param _address Address in question
    *   Contract will have codesize
    */
    function _isContract(address _address) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    /**
    * Checks if address has inhuman reflexes or if it's a contract
    * @param _address Address in question
    */
    function _checkIfBot(address _address) internal view returns (bool) {
        return (block.number < DEADBLOCK_COUNT + deadblockStart || _isContract(_address)) && !_isException(_address);
    }

    /**
    * Sets contract blocker
    * @param _val Should we block contracts?
    */
    function setBlockContracts(bool _val) external onlyOwner {
        _blockContracts = _val;
    }

    /**
    * Sets buy limiter
    * @param _val Limited?
    */
    function setLimitBuys(bool _val) external onlyOwner {
        _limitBuys = _val;
    }

    /**
    * Add or remove restrictions
    */
    function setRestrictions(bool _val) external onlyOwner {
        _unrestricted = _val;
    }

    /**
    *   Hook that is called before any transfer of tokens. This includes
    * minting and burning.
    *
    * Checks:
    * - transfer amount is non-zero
    * - address is not blacklisted.
    * - check if trade started, only after adding pair
    * - buy/sell are not executed during the same block to help alleviate sandwiches
    * - buy amount does not exceed max buy during limited period
    * - check for bots to alleviate snipes
    */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (amount == 0) { revert NoZeroTransfers(); }

        super._beforeTokenTransfer(from, to, amount);

        if (_unrestricted) { return; }

        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (pair == address(0)) {
            bool isAllowed = _isException(from) || _isException(to);
            require(isAllowed, "Trade Not Started");
            return;
        }

        // Watch for sandwich
        if (block.number == _lastBlockTransfer[from] || block.number == _lastBlockTransfer[to]) {
            revert NotAllowed();
        }

        bool isBuy = (from == pair);
        bool isSell = (to == pair);

        if (isBuy) {
            // Watch for bots
            if (_blockContracts && _checkIfBot(to)) { revert NotAllowed(); }
            // Watch for buys exceeding max during limited period
            if (_limitBuys && amount > MAX_BUY) { revert LimitExceeded(); }
            _lastBlockTransfer[to] = block.number;
        } else if (isSell) {
            _lastBlockTransfer[from] = block.number;
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

        // This function is executed on every call to the contract that does not match any other function.
    receive() external payable {}
}