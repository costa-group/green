// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/access/AccessControl.sol";
import "openzeppelin/contracts/access/IAccessControl.sol";
import "openzeppelin/contracts/interfaces/IERC1155.sol";
import "openzeppelin/contracts/interfaces/IERC2981.sol";
import "openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "openzeppelin/contracts/token/common/ERC2981.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/utils/introspection/IERC165.sol";
import "openzeppelin/contracts/utils/math/Math.sol";
import "contracts/FlipItBurgerIngredient.sol";
import "contracts/interfaces/IERC1155Mintable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "operator-filter-registry/src/lib/Constants.sol";
