// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
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
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                            %%                                                   //
//                                                                          %#*+*%                                                 //
//                                                 #*%                    %*+==+*#                                                 //
//                                                 #*+#%     %%%%%%      #++===+*#                                                 //
//                                                 #+=+*%  %+:::::-******+====+*%                                                  //
//                                                 #+==++*#=.    .::---======++*                                                   //
//                                                 #+======-:     .:---======+*                                                    //
//                                                 #+=====--:      :---======+*                                                    //
//                                                 #*===++=-:.   .:===-======+*                                                    //
//                                                 #*===#%*..    :%%%+======+*%                                                    //
//                                                 #*===*#=  ..  :###=-=====+*                                                     //
//                                                 #*===-:.  :=:  ... .-====+*                                                     //
//                                                 #*===:  .::::::     .:===+*                                                     //
//                                                  #+=:.  ..:..:.       ...-*                                                     //
//                                                  #+.   ....      ...     -#                                                     //
//                                                 %+:.   .............    .-+#                                                    //
//                                                 #=................    ...:=*%         % %*******%                               //
//                                            %%%%%#+:.....................:--=+#%    %%*+++======+**%                             //
//                                         ###*+++++=-:....................:---=+*###*+++========++#                               //
//                                       %*+++=========:::................:---====+++========+++**                                 //
//                                      %*+=============-:...............::----===========+++*#%                                   //
//                                      %*+=============--:.............:::---===========+*%%                                      //
//                                       %*++++=========--:.............:::----=======+**%                                         //
//                                         ###*+++======--::............:::----=====++*%                                           //
//                                             %%*++====--::::..........:::----====+*%                                             //
//                                                 #*+==--::::..........:::----==+*#                                               //
//                                                  %#+=--:::............::----=+*%                                                //
//                                                    *=--:::............::---=+#                                                  //
//                                                    *=--:::............::--=*                                                    //
//                                                    *=--::..............:--=*                                                    //
//                                                    *=--::..............:--=*                                                    //
//                                                    *=--::..............:--=*                                                    //
//                                                    *=--::..............:--=*                                                    //
//                                                    *=--::..............:--=*                                                    //
//                                                     *=-::.............::--=*                                                    //
//                                                     *=--:...........::::--=*                                                    //
//                                                     *=-:::........::::::--=*                                                    //
//                                                     *=-:::........::::::--=*                                                    //
//                                                     %*=::::.......::::::--=*                                                    //
//                                                      *=::::......:::::::--=*%                                                   //
//                                                      *=:::::.....:::::::---=*                                                   //
//                                                      *=::::::.....::::::---=*                                                   //
//                                                      *=:::::::....::::::---=+#                                                  //
//                                                      *=:::........:::::::::-=*#                                                 //
//                                                      *=....................:=+#                                                 //
//                                                      *=.........:-:--:......::+#                                                //
//                                                      *=.......:=#%%%%#=:......-+#                                               //
//                                                      *=.....:-+%      #+-:.....=#                                               //
//                                                      #=:...:+#         %*=-----=#                                               //
//                                                       %*===*%            %%%%%%%%                                               //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// airdrop contract
contract HappyAirdrop is Ownable {
    uint256 public startTimeMeme;
    uint256 public endTimeMeme;

    uint256 public startTimeHappy;
    uint256 public endTimeHappy;

    address public tokenAddress;
    
    uint256 constant public amount = 3140000000000000000000000000;

    uint256 public nonceMeme;
    uint256 public nonceHappy;

    mapping(address => bool) public claimed;

    // pepeTokenAddress;
    address constant public pepeTokenAddress = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;
    
    // ladyTokenAddress;
    address constant public ladyTokenAddress = 0x12970E6868f88f6557B76120662c1B3E50A646bf;

    string private _name ;   
    
    // airdrop event
    event Airdrop(address indexed _to, uint256 _amount);

    // constructor
    constructor(address _token, string memory name) {
        tokenAddress = _token;
        _name = name;
    }

    // set token airdrop time
    function setTimeMeme(uint256 _startTime, uint256 _endTime) external onlyOwner {
        startTimeMeme = _startTime;
        endTimeMeme = _endTime;
    }


    function setTimeHappy(uint256 _startTime, uint256 _endTime) external onlyOwner {
        startTimeHappy = _startTime;
        endTimeHappy = _endTime;
    }

    function airdropMeme(address _to) external {
        // check nonce
        require(nonceMeme <= 100, "airdrop end");

        // check claimed
        require(!claimed[_to], "claimed");

        // check time
        require(block.timestamp >= startTimeMeme && block.timestamp <= endTimeMeme, "invalid time");
        
        // check pepe token or lady token
        require(IERC20(pepeTokenAddress).balanceOf(_to) > 0 || IERC20(ladyTokenAddress).balanceOf(_to) > 0, "invalid pepe lady token");

        // transfer token
        IERC20(tokenAddress).transfer(_to, amount);

        // increase nonce
        nonceMeme++;

        // set claimed
        claimed[_to] = true;

        // emit event
        emit Airdrop(_to, amount);
    }

    function airdropHappy(address _to, string memory _inputname) external {
        // check nonce
        require(nonceHappy <= 100, "airdrop end");

        // check claimed
        require(!claimed[_to], "claimed");

        // check time
        require(block.timestamp >= startTimeHappy && block.timestamp <= endTimeHappy, "invalid time");
        
        // check name
        require(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(_inputname)), "invalid name");

        // transfer token
        IERC20(tokenAddress).transfer(_to, amount);

        // increase nonce
        nonceHappy++;

        // set claimed
        claimed[_to] = true;

        // emit event
        emit Airdrop(_to, amount);
    }

    // withdraw token
    function withdrawToken(address _token, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    // get all airdrop info
    function getAirdropInfo(address _address) external view returns (uint256, uint256, uint256, uint256, uint256, uint256,bool) {
        return (startTimeMeme, endTimeMeme, startTimeHappy, endTimeHappy, nonceMeme, nonceHappy, claimed[_address]);
    }
}