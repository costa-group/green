// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin/contracts/math/SafeMath.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "contracts/release/core/fund-deployer/IFundDeployer.sol";
import "contracts/release/infrastructure/price-feeds/derivatives/IDerivativePriceFeed.sol";
import "contracts/release/infrastructure/price-feeds/derivatives/feeds/PeggedDerivativesPriceFeed.sol";
import "contracts/release/infrastructure/price-feeds/derivatives/feeds/utils/PeggedDerivativesPriceFeedBase.sol";
import "contracts/release/infrastructure/price-feeds/derivatives/feeds/utils/SingleUnderlyingDerivativeRegistryMixin.sol";
import "contracts/release/utils/FundDeployerOwnerMixin.sol";
