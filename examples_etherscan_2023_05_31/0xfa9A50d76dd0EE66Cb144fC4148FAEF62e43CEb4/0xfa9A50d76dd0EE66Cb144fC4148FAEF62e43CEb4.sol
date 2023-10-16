// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/access/AccessControl.sol";
import "openzeppelin/contracts/access/IAccessControl.sol";
import "openzeppelin/contracts/interfaces/IERC2981.sol";
import "openzeppelin/contracts/token/common/ERC2981.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/utils/introspection/IERC165.sol";
import "openzeppelin/contracts/utils/math/Math.sol";
import "contracts/FlipItBurger.sol";
import "contracts/interfaces/IERC721AMintable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/IERC721ABurnable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "operator-filter-registry/src/lib/Constants.sol";
