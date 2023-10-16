// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./FlexibleStaking.sol";
import "openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../IMYCStakingManager.sol";
import "../IMYCStakingFactory.sol";
import "../../helpers/Mocks/IWETH.sol";

/// title Flexible Staking Factory
/// notice Creates new FlexibleStaking Contracts
contract FlexibleStakingFactory is EIP712, IMYCStakingFactory {
    error TransactionOverdue();
    error DatesSort();
    error WrongExecutor();
    error SignatureMismatch();

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
     * dev Returns MyCointainer Staking Manager Contract Address
     *
     */
    function mycStakingManager() external view returns (address) {
        return address(_mycStakingManager);
    }

    /**
     * dev Returns WETH address
     *
     */
    function WETH() external view returns (address) {
        return address(_WETH);
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
     * dev Creates {FlexibleStaking} new smart contract
     *
     */
    function createPool(
        address poolOwner, // pool Owner
        address tokenAddress, // staking token address
        uint256 rewardTokensPerSecond, //reward per second
        uint256 feeForMyc, //fee for mycointainer
        uint256 dateStart, // start date for all pools
        uint256 dateEnd, // end date for all pools
        uint256 deadline,
        bytes memory signature
    ) payable external {
        //check pool owner
        if (poolOwner != msg.sender && poolOwner != address(0)) {
            revert WrongExecutor();
        }

        // checking dates
        if (dateStart > dateEnd) {
            revert DatesSort();
        }

        if (block.timestamp > deadline) revert TransactionOverdue();
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "AddStakePoolData(address tokenAddress,address owner,uint256 rewardTokensPerSecond,uint256 feeForMyc,uint256 dateStart,uint256 dateEnd,uint256 deadline)"
                    ),
                    tokenAddress,
                    poolOwner == address(0) ? address(0) : msg.sender,
                    rewardTokensPerSecond,
                    feeForMyc,
                    dateStart,
                    dateEnd,
                    deadline
                )
            )
        );
        if (ECDSA.recover(typedHash, signature) != _mycStakingManager.signer())
            revert SignatureMismatch();

        FlexibleStaking createdPool = new FlexibleStaking{
            salt: bytes32(signature)
        }(tokenAddress, msg.sender, rewardTokensPerSecond, dateStart, dateEnd);

        uint256 tokenAmount = ((dateEnd - dateStart) * rewardTokensPerSecond);
        uint256 totalTokensRequired = tokenAmount + feeForMyc;

        if(address(_WETH) == tokenAddress){
            require(totalTokensRequired == msg.value, "Native currency amount mismatch");
            _WETH.deposit{value: msg.value}();
            _WETH.transfer(address(createdPool),tokenAmount);
            if(feeForMyc>0){
                _WETH.transfer(_mycStakingManager.treasury(),feeForMyc);
            }
        } 

        else{
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(createdPool),
                tokenAmount
            );

            if (feeForMyc > 0) {
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    _mycStakingManager.treasury(),
                    feeForMyc
                );
            }
        }



        _mycStakingManager.addStakingPool(
            address(createdPool),
            bytes32(signature)
        );
    }
}
