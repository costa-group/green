// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin/contracts/math/SafeMath.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "contracts/persistent/vault/interfaces/IExternalPositionVault.sol";
import "contracts/persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
import "contracts/persistent/vault/interfaces/IMigratableVault.sol";
import "contracts/persistent/vault/interfaces/IVaultCore.sol";
import "contracts/release/core/fund-deployer/IFundDeployer.sol";
import "contracts/release/core/fund/comptroller/IComptroller.sol";
import "contracts/release/core/fund/vault/IVault.sol";
import "contracts/release/extensions/IExtension.sol";
import "contracts/release/extensions/integration-manager/IIntegrationManager.sol";
import "contracts/release/extensions/integration-manager/IntegrationManager.sol";
import "contracts/release/extensions/integration-manager/integrations/IIntegrationAdapter.sol";
import "contracts/release/extensions/policy-manager/IPolicyManager.sol";
import "contracts/release/extensions/utils/ExtensionBase.sol";
import "contracts/release/extensions/utils/PermissionedVaultActionMixin.sol";
import "contracts/release/infrastructure/value-interpreter/IValueInterpreter.sol";
import "contracts/release/utils/AddressArrayLib.sol";
import "contracts/release/utils/AssetHelpers.sol";
import "contracts/release/utils/FundDeployerOwnerMixin.sol";
