// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/NativeTokenGateway.sol";
import "contracts/dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "contracts/dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "contracts/dependencies/openzeppelin/token/ERC20/IERC20.sol";
import "contracts/dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/dependencies/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "contracts/dependencies/openzeppelin/utils/Address.sol";
import "contracts/interfaces/IDebtToken.sol";
import "contracts/interfaces/IDepositToken.sol";
import "contracts/interfaces/IFeeProvider.sol";
import "contracts/interfaces/IGovernable.sol";
import "contracts/interfaces/INativeTokenGateway.sol";
import "contracts/interfaces/IPauseable.sol";
import "contracts/interfaces/IPool.sol";
import "contracts/interfaces/IPoolRegistry.sol";
import "contracts/interfaces/IRewardsDistributor.sol";
import "contracts/interfaces/ISyntheticToken.sol";
import "contracts/interfaces/ITreasury.sol";
import "contracts/interfaces/external/IMasterOracle.sol";
import "contracts/interfaces/external/ISwapper.sol";
import "contracts/interfaces/external/IWETH.sol";
import "contracts/utils/TokenHolder.sol";
