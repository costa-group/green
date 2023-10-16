// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

import "contracts/persistent/vault/interfaces/IExternalPositionVault.sol";
import "contracts/persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
import "contracts/persistent/vault/interfaces/IMigratableVault.sol";
import "contracts/persistent/vault/interfaces/IVaultCore.sol";
import "contracts/release/core/fund-deployer/IFundDeployer.sol";
import "contracts/release/core/fund/comptroller/IComptroller.sol";
import "contracts/release/core/fund/vault/IVault.sol";
import "contracts/release/extensions/IExtension.sol";
import "contracts/release/extensions/policy-manager/IPolicy.sol";
import "contracts/release/extensions/policy-manager/IPolicyManager.sol";
import "contracts/release/extensions/policy-manager/PolicyManager.sol";
import "contracts/release/extensions/utils/ExtensionBase.sol";
import "contracts/release/infrastructure/gas-relayer/GasRelayRecipientMixin.sol";
import "contracts/release/infrastructure/gas-relayer/IGasRelayPaymaster.sol";
import "contracts/release/interfaces/IGsnForwarder.sol";
import "contracts/release/interfaces/IGsnPaymaster.sol";
import "contracts/release/interfaces/IGsnTypes.sol";
import "contracts/release/utils/AddressArrayLib.sol";
import "contracts/release/utils/FundDeployerOwnerMixin.sol";
import "contracts/release/utils/beacon-proxy/IBeacon.sol";
import "contracts/release/utils/beacon-proxy/IBeaconProxyFactory.sol";
