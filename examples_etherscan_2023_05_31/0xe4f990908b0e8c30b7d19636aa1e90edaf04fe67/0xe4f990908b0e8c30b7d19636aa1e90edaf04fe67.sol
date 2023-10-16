// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// Importing required libraries and contracts

contract Logger {
    event Log(string action, bytes data);

    function log(string calldata _action, bytes calldata _data) external {
        emit Log(_action, _data);
    }
}

interface IWETH {
    function allowance(address, address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;
}

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @title BaseModule
/// @notice BaseModule contract.
/// @author @Mutative_
abstract contract BaseModule is Owned(msg.sender) {
    /// @notice Logger contract.
    Logger immutable LOGGER;

    /// @notice BaseModule constructor.
    constructor(Logger logger) {
        LOGGER = Logger(logger);
    }
}

interface ILido {
    function wrap(uint256 _amount) external returns (uint256);
    function unwrap(uint256 _amount) external returns (uint256);

    function submit(address _referral) external payable;

    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
}

/// @notice Constants used in Morphous.
library Constants {
    /// @notice ETH address.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice sETH address.
    address internal constant _stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @notice wstETH address.
    address internal constant _wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /// @notice cETH address.
    address internal constant _cETHER = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    /// @notice WETH address.
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice DAI address.
    address internal constant _DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /// @notice The address of Morpho Aave markets.
    address public constant _MORPHO_AAVE = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0;

    /// @notice The address of Morpho Aave markets.
    /// TODO: Replace this address with the correct one.
    address public constant _MORPHO_AAVE_V3 = 0x33333aea097c193e66081E930c33020272b33333;

    /// @notice Address of Aave Lending Pool contract.
    address internal constant _AAVE_LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    /// @notice Address of Balancer contract.
    address internal constant _BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice The address of Morpho Compound markets.
    address public constant _MORPHO_COMPOUND = 0x8888882f8f843896699869179fB6E4f7e3B58888;

    /// @notice Address of Factory Guard contract.
    address internal constant _FACTORY_GUARD_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ////////////////////////////////////////////////////////////////

    /// @dev Error message when the caller is not allowed to call the function.
    error NOT_ALLOWED();

    /// @dev Error message when array length is invalid.
    error INVALID_LENGTH();

    /// @dev Error message when the caller is not allowed to call the function.
    error INVALID_LENDER();

    /// @dev Error message when the caller is not allowed to call the function.
    error INVALID_INITIATOR();

    /// @dev Error message when the market is invalid.
    error INVALID_MARKET();

    /// @dev Error message when the market is invalid.
    error INVALID_AGGREGATOR();

    /// @dev Error message when the deadline has passed.
    error DEADLINE_EXCEEDED();

    /// @dev Error message for when the amount of received tokens is less than the minimum amount.
    error NOT_ENOUGH_RECEIVED();
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

library TokenUtils {
    using SafeTransferLib for ERC20;

    function _approve(address _token, address _to, uint256 _amount) internal {
        if (_token == Constants._ETH) return;

        if (ERC20(_token).allowance(address(this), _to) < _amount || _amount == 0) {
            ERC20(_token).safeApprove(_to, _amount);
        }
    }

    function _transferFrom(address _token, address _from, uint256 _amount) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = _balanceInOf(_token, _from);
        }

        if (_from != address(0) && _from != address(this) && _token != Constants._ETH && _amount != 0) {
            ERC20(_token).safeTransferFrom(_from, address(this), _amount);

            return _amount;
        }

        return 0;
    }

    function _transfer(address _token, address _to, uint256 _amount) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = _balanceInOf(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != Constants._ETH) {
                ERC20(_token).safeTransfer(_to, _amount);
            } else {
                SafeTransferLib.safeTransferETH(_to, _amount);
            }

            return _amount;
        }

        return 0;
    }

    function _depositSTETH(uint256 _amount) internal {
        ILido(Constants._stETH).submit{value: _amount}(address(this));
    }

    function _wrapstETH(uint256 _amount) internal returns (uint256) {
        _approve(Constants._stETH, Constants._wstETH, _amount);
        return ILido(Constants._wstETH).wrap(_amount);
    }

    function _unwrapstETH(uint256 _amount) internal returns (uint256) {
        return ILido(Constants._wstETH).unwrap(_amount);
    }

    function _depositWETH(uint256 _amount) internal {
        IWETH(Constants._WETH).deposit{value: _amount}();
    }

    function _withdrawWETH(uint256 _amount) internal {
        uint256 _balance = _balanceInOf(Constants._WETH, address(this));

        if (_amount > _balance) {
            _amount = _balance;
        }

        IWETH(Constants._WETH).withdraw(_amount);
    }

    function _balanceInOf(address _token, address _acc) internal view returns (uint256) {
        if (_token == Constants._ETH) {
            return _acc.balance;
        } else {
            return ERC20(_token).balanceOf(_acc);
        }
    }
}

/// @title TokenActionsModule
/// @notice This contract contains functions related to token actions such as transfer and approval
contract TokenActionsModule is BaseModule {
    using SafeTransferLib for ERC20;

    /// @notice Constructs the TokenActionsModule contract
    /// @param logger The logger contract
    constructor(Logger logger) BaseModule(logger) {}

    /// @notice Approves a certain amount of token for a recipient
    /// @param _token The token to approve
    /// @param _to The address to approve the tokens for
    /// @param _amount The amount of tokens to approve
    function approveToken(address _token, address _to, uint256 _amount) external {
        TokenUtils._approve(_token, _to, _amount);
    }

    /// @notice Transfers a certain amount of tokens from one address to another
    /// @param _token The token to transfer
    /// @param _from The address to transfer the tokens from
    /// @param _amount The amount of tokens to transfer
    /// @return The actual amount transferred
    function transferFrom(address _token, address _from, uint256 _amount) external returns (uint256) {
        return TokenUtils._transferFrom(_token, _from, _amount);
    }

    /// @notice Transfers a certain amount of tokens to a recipient
    /// @param _token The token to transfer
    /// @param _to The address to transfer the tokens to
    /// @param _amount The amount of tokens to transfer
    /// @return The actual amount transferred
    function transfer(address _token, address _to, uint256 _amount) external returns (uint256) {
        return TokenUtils._transfer(_token, _to, _amount);
    }

    /// @notice Deposits a certain amount of stETH
    /// @param _amount The amount of stETH to deposit
    function depositSTETH(uint256 _amount) external {
        TokenUtils._depositSTETH(_amount);
    }

    /// @notice Deposits a certain amount of WETH
    /// @param _amount The amount of WETH to deposit
    function depositWETH(uint256 _amount) external {
        TokenUtils._depositWETH(_amount);
    }

    /// @notice Wraps a certain amount of stETH
    /// @param _amount The amount of stETH to wrap
    function wrapstETH(uint256 _amount) external returns (uint256) {
        return TokenUtils._wrapstETH(_amount);
    }

    /// @notice Unwraps a certain amount of stETH
    /// @param _amount The amount of stETH to unwrap
    function unwrapstETH(uint256 _amount) external returns (uint256) {
        return TokenUtils._unwrapstETH(_amount);
    }

    /// @notice Withdraws a certain amount of WETH
    /// @param _amount The amount of WETH to withdraw
    function withdrawWETH(uint256 _amount) external {
        TokenUtils._withdrawWETH(_amount);
    }

    /// @notice Gets the balance of an account for a specific token
    /// @param _token The token to check the balance for
    /// @param _acc The address to check the balance of
    /// @return The balance of the account in the token
    function balanceInOf(address _token, address _acc) public view returns (uint256) {
        return TokenUtils._balanceInOf(_token, _acc);
    }
}