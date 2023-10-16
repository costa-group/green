// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "contracts/external/AccessControlUpgradeable.sol";
import "contracts/interfaces/IAccessControl.sol";
import "contracts/interfaces/IAngleMiddlemanGauge.sol";
import "contracts/interfaces/IGaugeController.sol";
import "contracts/interfaces/ILiquidityGauge.sol";
import "contracts/interfaces/IStakingRewards.sol";
import "contracts/staking/AngleDistributor.sol";
import "contracts/staking/AngleDistributorEvents.sol";
