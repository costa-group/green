// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/access/AccessControl.sol";
import "openzeppelin/contracts/access/IAccessControl.sol";
import "openzeppelin/contracts/interfaces/IERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/utils/introspection/IERC165.sol";
import "openzeppelin/contracts/utils/math/Math.sol";
import "contracts/FlipItMinter.sol";
import "contracts/IFlipItMinter.sol";
import "contracts/interfaces/IERC1155Mintable.sol";
import "contracts/interfaces/IERC721AMintable.sol";
import "contracts/libraries/Random.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
