// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: bonds.sol



//pragma solidity ^0.8.0;


contract MiladyBonds {
    IERC20 public token;
    address public treasury;

    struct Bond {
        uint256 amount;
        uint256 pricePaid;
        uint256 purchaseTimestamp;
    }

    mapping(address => Bond[]) public bondInfo;

    event BondPurchase(address indexed buyer, uint256 amount, uint256 pricePaid);

    constructor(address _token, address _treasury) {
        token = IERC20(_token);
        treasury = _treasury;
    }

    function buyBond(uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than zero");

        uint256 price = getCurrentBondPrice(amount);
        require(msg.value >= price, "Insufficient Ether provided");

        token.transferFrom(treasury, msg.sender, amount);

        Bond memory newBond = Bond({
            amount: amount,
            pricePaid: msg.value,
            purchaseTimestamp: block.timestamp
        });

        bondInfo[msg.sender].push(newBond);

        emit BondPurchase(msg.sender, amount, msg.value);
    }

    function getCurrentBondPrice(uint256 amount) public view returns (uint256) {
        // This function should implement the bond pricing logic
        // based on the bonding curve you choose, and return the
        // current price for the specified bond amount.
    }

    // Consider implementing functions like `sellBond`, `redeemBond`, and other
    // related functionalities to allow users to interact with the bonds.
}