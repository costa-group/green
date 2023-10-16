// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "openzeppelin/contracts/utils/math/Math.sol";
import "contracts/helpers/Mocks/IWETH.sol";
import "contracts/staking/IMYCStakingFactory.sol";
import "contracts/staking/IMYCStakingManager.sol";
import "contracts/staking/IMYCStakingPool.sol";
import "contracts/staking/LockedStaking/LockedStaking.sol";
import "contracts/staking/LockedStaking/LockedStakingFactory.sol";
