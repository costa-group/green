// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin/contracts/math/SafeMath.sol";
import "contracts/persistent/vault/interfaces/IExternalPositionVault.sol";
import "contracts/persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
import "contracts/persistent/vault/interfaces/IMigratableVault.sol";
import "contracts/persistent/vault/interfaces/IVaultCore.sol";
import "contracts/release/core/fund-deployer/IFundDeployer.sol";
import "contracts/release/core/fund/comptroller/IComptroller.sol";
import "contracts/release/core/fund/vault/IVault.sol";
import "contracts/release/extensions/IExtension.sol";
import "contracts/release/extensions/fee-manager/FeeManager.sol";
import "contracts/release/extensions/fee-manager/IFee.sol";
import "contracts/release/extensions/fee-manager/IFeeManager.sol";
import "contracts/release/extensions/utils/ExtensionBase.sol";
import "contracts/release/extensions/utils/PermissionedVaultActionMixin.sol";
import "contracts/release/utils/AddressArrayLib.sol";
import "contracts/release/utils/FundDeployerOwnerMixin.sol";
