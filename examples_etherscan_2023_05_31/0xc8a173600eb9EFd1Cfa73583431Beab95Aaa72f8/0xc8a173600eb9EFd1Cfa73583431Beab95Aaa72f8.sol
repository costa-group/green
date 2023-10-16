// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/access/AccessControl.sol";
import "openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "openzeppelin/contracts/access/IAccessControl.sol";
import "openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/utils/introspection/IERC165.sol";
import "openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "contracts/common/interfaces/IPriceConsumer.sol";
import "contracts/common/interfaces/IPriceOracleManager.sol";
import "contracts/common/oracles/PriceOracleManagerV1.sol";
