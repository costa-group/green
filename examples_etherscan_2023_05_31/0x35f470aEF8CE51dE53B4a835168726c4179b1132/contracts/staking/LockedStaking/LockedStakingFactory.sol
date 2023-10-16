// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./LockedStaking.sol";
import "openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../IMYCStakingManager.sol";
import "../IMYCStakingFactory.sol";
import "../../helpers/Mocks/IWETH.sol";

/// title Locked Staking Factory
/// notice Creates new LockedStaking Contracts
contract LockedStakingFactory is EIP712, IMYCStakingFactory {
    /**
     * dev Emitted when withdawing MYC `reward` fees for `poolAddress`
     */
    event WithdrawnMYCFees(address indexed poolAddress, uint256 reward);

    error SignatureMismatch();
    error TransactionOverdue();
    error DatesSort();
    error IncompleteArray();
    error WrongExecutor();

    IMYCStakingManager internal _mycStakingManager;
    IWETH internal _WETH;

    constructor(
        IMYCStakingManager mycStakingManager_,
        IWETH weth_
    ) EIP712("MyCointainer", "1") {
        _mycStakingManager = mycStakingManager_;
        _WETH = weth_;
    }

    /**
     * dev Returns WETH address
     *
     */
    function WETH() external view returns (address) {
        return address(_WETH);
    }

    /**
     * dev Returns MyCointainer Staking Manager Contract Address
     *
     */
    function mycStakingManager() external view returns (address) {
        return address(_mycStakingManager);
    }

    /**
     * dev Returns signer address
     */
    function signer() external view returns (address) {
        return _mycStakingManager.signer();
    }

    /**
     * dev Returns signer address
     */
    function treasury() external view returns (address) {
        return _mycStakingManager.treasury();
    }

    /**
     * dev Returns main owner address
     */
    function owner() external view returns (address) {
        return _mycStakingManager.owner();
    }

    /**
     * dev Creates {LockedStaking} new smart contract
     *
     */
    function createPool(
        address poolOwner, // pool Owner
        address tokenAddress, // staking token address
        uint256[] memory durations, // for how long user cannot unstake
        uint256[] memory maxTokensBeStaked, // maximum amount that can be staked amoung all stakers for each duration
        uint256[] memory rewardsPool, // reward pool for each duration
        uint256[] memory mycFeesPool, //myc fees pools for each duration
        uint256[] memory maxStakingAmount, //max staking amount
        uint256 dateStart, // start date for all pools
        uint256 dateEnd, // end date for all pools
        uint256 deadline,
        bytes memory signature
    ) external payable{
        //check pool owner
        if (poolOwner != msg.sender && poolOwner != address(0)) {
            revert WrongExecutor();
        }

        // checking dates
        if (dateStart >= dateEnd) {
            revert DatesSort();
        }
        // checking arrays
        if (
            durations.length != maxTokensBeStaked.length ||
            maxTokensBeStaked.length != rewardsPool.length ||
            rewardsPool.length != mycFeesPool.length ||
            maxStakingAmount.length != mycFeesPool.length ||
            durations.length == 0 
        ) {
            revert IncompleteArray();
        }

        if (block.timestamp > deadline) revert TransactionOverdue();
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "AddStakePoolData(address tokenAddress,address owner,uint256[] durations,uint256[] maxTokensBeStaked,uint256[] rewardsPool,uint256[] mycFeesPool,uint256[] maxStakingAmount,uint256 dateStart,uint256 dateEnd,uint256 deadline)"
                    ),
                    tokenAddress,
                    poolOwner == address(0) ? address(0) : msg.sender,
                    keccak256(abi.encodePacked(durations)),
                    keccak256(abi.encodePacked(maxTokensBeStaked)),
                    keccak256(abi.encodePacked(rewardsPool)),
                    keccak256(abi.encodePacked(mycFeesPool)),
                    keccak256(abi.encodePacked(maxStakingAmount)),
                    dateStart,
                    dateEnd,
                    deadline
                )
            )
        );
        if (ECDSA.recover(typedHash, signature) != _mycStakingManager.signer())
            revert SignatureMismatch();

        LockedStaking createdPool = new LockedStaking{salt: bytes32(signature)}(
            tokenAddress,
            msg.sender,
            durations,
            maxTokensBeStaked,
            rewardsPool,
            mycFeesPool,
            maxStakingAmount,
            dateStart,
            dateEnd
        );

        uint256 rewardPoolSum = 0;
        uint256 mycFeeSum = 0;
        for (uint256 i = 0; i < rewardsPool.length; i++) {
            mycFeeSum += mycFeesPool[i];
            rewardPoolSum += rewardsPool[i];
        }

        if(address(_WETH) == tokenAddress){
            require(rewardPoolSum + mycFeeSum == msg.value, "Native currency amount mismatch");
            _WETH.deposit{value: msg.value}();
            _WETH.transfer(address(createdPool),rewardPoolSum);
            if(mycFeeSum>0){
                _WETH.transfer(_mycStakingManager.treasury(),mycFeeSum);
            }
        } 

        else{
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(createdPool),
                rewardPoolSum
            );

            if (mycFeeSum > 0) {
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    _mycStakingManager.treasury(),
                    mycFeeSum
                );
            }
        }

        _mycStakingManager.addStakingPool(
            address(createdPool),
            bytes32(signature)
        );
    }
}
