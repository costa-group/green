// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "MARTAROCKS.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/Pausable.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableOperatorFilterer.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin/contracts/interfaces/IERC2981.sol";
import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/introspection/IERC165.sol";
