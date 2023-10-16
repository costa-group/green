// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/utils/introspection/IERC165.sol";
import "openzeppelin/contracts/utils/math/Math.sol";
import "contracts/utils/ForjClaimLogic.sol";
import "contracts/utils/ForjCustomErrors.sol";
import "contracts/utils/ForjERC1155.sol";
import "contracts/utils/ForjModifiers.sol";
import "contracts/utils/ForjSoulboundERC1155.sol";
import "contracts/utils/ForjTreasuryLogic.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "operator-filter-registry/src/lib/Constants.sol";
