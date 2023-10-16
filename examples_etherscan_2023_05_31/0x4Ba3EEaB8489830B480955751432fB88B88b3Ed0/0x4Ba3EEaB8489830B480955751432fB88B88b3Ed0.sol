// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/GELStaking.sol";
import "contracts/interfaces/IGelato.sol";
import "contracts/vendor/hardhat-deploy/Proxied.sol";
