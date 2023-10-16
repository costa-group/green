// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "contracts/StrategyAuraFactoryClonable.sol";
import "https://github.com/yearn/yearn-vaults/blob/v0.4.6/contracts/BaseStrategy.sol";
import "contracts/interfaces/curve.sol";
import "openzeppelin/contracts/utils/math/Math.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
