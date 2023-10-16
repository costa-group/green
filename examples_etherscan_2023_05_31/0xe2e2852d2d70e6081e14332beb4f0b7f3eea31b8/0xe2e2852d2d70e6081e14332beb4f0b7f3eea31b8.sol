// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol@v4.8.3


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol@v4.8.3


// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

//pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}


// File contracts/OracleRegistry.sol



//pragma solidity ^0.8.17;

/// @title IStablecoin
/// @notice An interface for Stablecoin interactions
interface IStablecoin {
    function mint(address recipient, uint256 amount) external;

    function burn(uint256 amount) external returns (bool);

    // ERC20 functions
    function transferWithoutFee(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFromWithoutFee(address sender, address recipient, uint256 amount) external returns (bool);
}

/// @title OracleRegistry
/// @notice A smart contract for managing the mint and burn processes of a stablecoin using oracle service.
contract OracleRegistry is Initializable {
    IStablecoin public stableContract; // stablecoin contract
    address public oracleAddress; // oracle contract address
    address public everstableAdminAddress; // everstable admin multisig address

    mapping(bytes32 => Update) public updates; // oracle service will store updates here
    bytes32 public latestUpdate; // latest update hash

    // lockId => BurnRequest
    uint public burnCounter; // counter for burn requests
    mapping(uint => BurnRequest) public burnRequests; // burn requests will be stored here

    uint public burnLimit; // 1 token = 1e6

    struct Update {
        uint id; // id of the update
        string date; // date of the update
        bool isSubscription; // type of update, subscription or redemption
        uint256 updateAmount; // set by oracle service used to mint tokens
        string amount; // set by oracle service for informational purposes
        uint256 timestamp; // update timestamp
        bool isLinked; // true if everstable admin has linked the update with customer
        bool isSettled; // true if client has minted tokens
        bytes32 hashedClientAddress; // hashed client address
        bool isCanceled; // true if everstable admin has canceled the update
        string cancellationReason; // reason of cancellation
    }

    struct BurnRequest {
        address from; // address of the client who initiated the burn request
        uint256 amount; // amount of tokens to be burned
        uint256 timestamp; // burn request timestamp
        bool isBurned; // true if everstableAdminAddress has burned the tokens
        bool isCanceled; // true if everstableAdminAddress has canceled the burn request
    }

    /// @notice Emitted when an update is added by the oracle.
    /// @param updateId The ID of the added update
    /// @param amount The amount of tokens involved in the update
    /// @param timestamp Timestamp when the update was added
    /// @param isSubscription True if the update is a subscription, false if it's a redemption
    event FundsUpdate(bytes32 indexed updateId, uint256 indexed amount, uint256 timestamp, bool isSubscription);

    /// @notice Emitted when an update is linked to a customer by everstable admin.
    /// @param updateId The ID of the linked update
    /// @param hashedData The hashed client address linked with the update
    event UpdateLinked(bytes32 indexed updateId, bytes32 hashedData);

    /// @notice Emitted when a burn request is created.
    /// @param burnId The ID of the created burn request
    /// @param from The address initiating the burn request
    /// @param amount The amount of tokens involved in the burn request
    event BurnRequestCreated(uint256 indexed burnId, address indexed from, uint256 amount);

    /// @notice Emitted when tokens are minted after an update is settled.
    /// @param updateId The ID of the settled update
    /// @param recepient The address receiving the minted tokens
    /// @param amount The amount of tokens minted
    event TokensMinted(bytes32 indexed updateId, address indexed recepient, uint256 amount);

    /// @notice Emitted when an update is canceled by everstable admin.
    /// @param updateId The ID of the canceled update
    /// @param reason The reason for cancellation
    event UpdateCanceled(bytes32 indexed updateId, string reason);
    event BurnCanceled(uint256 indexed burnId, string reason);
    event BurnLimitChanged(uint256 limitAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with necessary parameters.
    /// @param _stableAddress Stablecoin contract address
    /// @param _oracleAddress Oracle contract address
    /// @param _everstableAdminAddress everstableAdminAddress multisig address
    function initialize(address _stableAddress, address _everstableAdminAddress, address _oracleAddress) public initializer {
        require(_stableAddress != address(0), "OracleRegistry: Stablecoin address is zero");
        require(_everstableAdminAddress != address(0), "OracleRegistry: everstable admin address is zero");
        require(_oracleAddress != address(0), "OracleRegistry: Oracle address is zero");
        stableContract = IStablecoin(_stableAddress);
        oracleAddress = _oracleAddress;
        everstableAdminAddress = _everstableAdminAddress;
        burnLimit = 100000 * 1e6;
        // 1 token = 1e6
    }

    /// @notice Oracle writes NAV changes to the contract.
    /// @param _id ID of the update
    /// @param _date Date of the update
    /// @param _isSubscription Type of update, subscription or redemption
    /// @param _updateAmount Amount set by oracle service used to mint tokens
    /// @param _amount Amount set by oracle service for informational purposes
    function setUpdate(uint _id, string calldata _date, bool _isSubscription, uint256 _updateAmount, string calldata _amount) external {
        require(msg.sender == oracleAddress, "Only oracle can add updates");
        bytes32 hashKey = keccak256(abi.encodePacked(_id, _date, _isSubscription, _updateAmount, _amount));
        require(updates[hashKey].timestamp == 0, "Update already exists");
        updates[hashKey] = Update(_id, _date, _isSubscription, _updateAmount, _amount, block.timestamp, false, false, 0, false, "");
        latestUpdate = hashKey;
        emit FundsUpdate(hashKey, _updateAmount, block.timestamp, _isSubscription);
    }

    /// @notice everstable admin links update changes with customer.
    /// @param _updateId ID of the update to be linked
    /// @param _hashedClientAddress Hashed client address to be linked with the update
    function linkDepositWithCustomer(bytes32 _updateId, bytes32 _hashedClientAddress) external {
        require(msg.sender == everstableAdminAddress, "Only everstable admin can link NAV with customer");
        require(updates[_updateId].timestamp != 0, "Update does not exist");
        require(!updates[_updateId].isCanceled, "Update is canceled");
        require(!updates[_updateId].isSettled, "Update already settled");
        require(updates[_updateId].isSubscription, "Only subscription updates can be linked");

        updates[_updateId].isLinked = true;
        updates[_updateId].hashedClientAddress = _hashedClientAddress;
        emit UpdateLinked(_updateId, _hashedClientAddress);
    }

    /// @notice Client with secret finalize mint process.
    /// @param _updateId ID of the update to be minted
    /// @param _recipient Recipient address to receive minted tokens
    function mint(bytes32 _updateId, address _recipient) external {
        require(updates[_updateId].timestamp != 0, "Update does not exist");
        require(_recipient != address(0), "Recipient address is zero");
        require(!updates[_updateId].isSettled, "Update already settled");
        require(!updates[_updateId].isCanceled, "Update is canceled");
        require(updates[_updateId].isLinked, "Update not linked with customer");
        // check if sender is authorized
        require(keccak256(abi.encodePacked(msg.sender)) == updates[_updateId].hashedClientAddress, "Address is not authorized");
        // mark update as settled
        updates[_updateId].isSettled = true;
        // mint tokens
        stableContract.mint(_recipient, updates[_updateId].updateAmount);
        emit TokensMinted(_updateId, _recipient, updates[_updateId].updateAmount);
    }

    /// @notice customer locks tokens in the contract for burning.
    /// @param _amount Amount of tokens to be locked for burning
    function initiateBurn(uint256 _amount) external {
        require(_amount >= burnLimit, "Amount is less than burn limit");
        require(stableContract.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance");
        require(stableContract.transferFromWithoutFee(msg.sender, address(this), _amount));
        burnCounter++;
        burnRequests[burnCounter] = BurnRequest(msg.sender, _amount, block.timestamp, false, false);
        emit BurnRequestCreated(burnCounter, msg.sender, _amount);
    }

    /// @notice Only everstable admin can burn tokens.
    /// @param _burnId ID of the burn request
    /// @param _updateId ID of the update to be burned
    function finalizeBurn(uint256 _burnId, bytes32 _updateId) external {
        require(updates[_updateId].timestamp != 0, "Update does not exist");
        require(burnRequests[_burnId].timestamp != 0, "Burn does not exist");
        require(msg.sender == everstableAdminAddress, "Only everstable admin can finalize burn process");

        require(!updates[_updateId].isSubscription, "Only withdrawal can be burned");
        require(!updates[_updateId].isCanceled, "Update is canceled");

        require(!burnRequests[_burnId].isBurned, "Already burned tokens");
        require(!burnRequests[_burnId].isCanceled, "Burn request is canceled");
        // burn tokens
        updates[_updateId].isSettled = true;
        burnRequests[_burnId].isBurned = true;
        require(stableContract.burn(burnRequests[_burnId].amount), "Failed to burn tokens");
    }

    /// @notice everstable admin can cancel update.
    /// @param _updateId ID of the update to be canceled
    /// @param _reason Reason of cancellation
    function cancelUpdate(bytes32 _updateId, string calldata _reason) external {
        require(msg.sender == everstableAdminAddress, "Only everstable admin can cancel update");
        require(updates[_updateId].timestamp != 0, "Update does not exist");
        require(!updates[_updateId].isSettled, "Update already settled");
        require(!updates[_updateId].isCanceled, "Update already canceled");
        updates[_updateId].isCanceled = true;
        updates[_updateId].cancellationReason = _reason;
        emit UpdateCanceled(_updateId, _reason);
    }

    /// @notice everstable admin can cancel burn request.
    /// @param _burnId ID of the burn request to be canceled
    /// @param _reason Reason of cancellation
    function cancelBurnRequest(uint256 _burnId, string calldata _reason) external {
        require(msg.sender == everstableAdminAddress, "Only everstable admin can cancel burn request");
        require(burnRequests[_burnId].timestamp != 0, "Burn request does not exist");
        require(!burnRequests[_burnId].isCanceled, "Burn request already canceled");
        require(!burnRequests[_burnId].isBurned, "Already burned tokens");
        burnRequests[_burnId].isCanceled = true;
        require(stableContract.transferWithoutFee(burnRequests[_burnId].from, burnRequests[_burnId].amount), "Failed to transfer tokens");
        emit BurnCanceled(_burnId, _reason);
    }

    /// @notice limit amount to be set
    /// @param _newBurnLimit New burn limit to be set
    function setNewBurnLimit(uint256 _newBurnLimit) external {
        require(msg.sender == everstableAdminAddress, "Only everstable admin can change burn limit");
        burnLimit = _newBurnLimit;
        emit BurnLimitChanged(_newBurnLimit);
    }

    /// @notice Set new oracle address.
    /// @param _newOracleAddress New oracle address to be set
    function setNewOracle(address _newOracleAddress) external {
        require(_newOracleAddress != address(0), "New oracle address cannot be 0");
        require(msg.sender == everstableAdminAddress, "Only everstableAdminAddress can change oracle address");
        oracleAddress = _newOracleAddress;
    }

    /// @notice Check if updateId exists by update hash.
    /// @param _hash Hash of the update
    /// @return True if update exists, False otherwise
    function updateExistsByHash(bytes32 _hash) external view returns (bool) {
        return updates[_hash].timestamp != 0;
    }

    /// @notice Check if updateId exists by update data.
    /// @param _id ID of the update
    /// @param _date Date of the update
    /// @param _isSubscription Type of update, subscription or redemption
    /// @param _updateAmount Amount set by oracle service used to mint tokens
    /// @param _amount Amount set by oracle service for informational purposes
    /// @return True if update exists, False otherwise
    function updateExists(
        uint _id,
        string calldata _date,
        bool _isSubscription,
        uint256 _updateAmount,
        string calldata _amount
    ) external view returns (bool) {
        bytes32 calcHash = keccak256(abi.encodePacked(_id, _date, _isSubscription, _updateAmount, _amount));
        return updates[calcHash].timestamp != 0;
    }

    /// @notice Hashing function to create unique updateId.
    /// @param _id ID of the update
    /// @param _date Date of the update
    /// @param _isSubscription Type of update, subscription or redemption
    /// @param _updateAmount Amount set by oracle service used to mint tokens
    /// @param _amount Amount set by oracle service for informational purposes
    /// @return bytes32 Hashed update data
    function hash(
        uint _id,
        string calldata _date,
        bool _isSubscription,
        uint256 _updateAmount,
        string calldata _amount
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_id, _date, _isSubscription, _updateAmount, _amount));
    }
}