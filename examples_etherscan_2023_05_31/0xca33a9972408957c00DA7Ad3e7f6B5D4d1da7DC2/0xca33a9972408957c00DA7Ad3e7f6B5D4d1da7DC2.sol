// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/introspection/IERC165.sol";
import "contracts/common/interfaces/IVaultKey.sol";
import "contracts/locker/interfaces/IDepositHandler.sol";
import "contracts/locker/interfaces/IVault.sol";
import "contracts/locker/interfaces/IVaultFactory.sol";
import "contracts/locker/vault/FungibleVestingVault.sol";
import "contracts/locker/vault/Vault.sol";
