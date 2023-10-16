// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/FeeProvider.sol";
import "contracts/dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "contracts/dependencies/openzeppelin/token/ERC20/IERC20.sol";
import "contracts/dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/interfaces/IDebtToken.sol";
import "contracts/interfaces/IFeeProvider.sol";
import "contracts/interfaces/IGovernable.sol";
import "contracts/interfaces/IPauseable.sol";
import "contracts/interfaces/IPoolRegistry.sol";
import "contracts/interfaces/ISyntheticToken.sol";
import "contracts/interfaces/external/IESMET.sol";
import "contracts/interfaces/external/IMasterOracle.sol";
import "contracts/lib/WadRayMath.sol";
import "contracts/storage/FeeProviderStorage.sol";
