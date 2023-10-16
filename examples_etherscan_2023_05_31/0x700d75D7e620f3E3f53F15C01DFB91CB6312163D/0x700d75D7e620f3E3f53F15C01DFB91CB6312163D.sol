// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin/contracts/math/SafeMath.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "contracts/persistent/address-list-registry/AddressListRegistry.sol";
import "contracts/persistent/dispatcher/IDispatcher.sol";
import "contracts/persistent/external-positions/IExternalPosition.sol";
import "contracts/persistent/vault/interfaces/IExternalPositionVault.sol";
import "contracts/persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
import "contracts/persistent/vault/interfaces/IMigratableVault.sol";
import "contracts/persistent/vault/interfaces/IVaultCore.sol";
import "contracts/release/core/fund-deployer/IFundDeployer.sol";
import "contracts/release/core/fund/comptroller/ComptrollerLib.sol";
import "contracts/release/core/fund/comptroller/IComptroller.sol";
import "contracts/release/core/fund/vault/IVault.sol";
import "contracts/release/extensions/IExtension.sol";
import "contracts/release/extensions/fee-manager/IFeeManager.sol";
import "contracts/release/extensions/policy-manager/IPolicy.sol";
import "contracts/release/extensions/policy-manager/IPolicyManager.sol";
import "contracts/release/extensions/policy-manager/policies/new-shareholders/AllowedSharesTransferRecipientsPolicy.sol";
import "contracts/release/extensions/policy-manager/policies/utils/AddressListRegistryPolicyBase.sol";
import "contracts/release/extensions/policy-manager/policies/utils/PolicyBase.sol";
import "contracts/release/infrastructure/gas-relayer/GasRelayRecipientMixin.sol";
import "contracts/release/infrastructure/gas-relayer/IGasRelayPaymaster.sol";
import "contracts/release/infrastructure/gas-relayer/IGasRelayPaymasterDepositor.sol";
import "contracts/release/infrastructure/value-interpreter/IValueInterpreter.sol";
import "contracts/release/interfaces/IGsnForwarder.sol";
import "contracts/release/interfaces/IGsnPaymaster.sol";
import "contracts/release/interfaces/IGsnTypes.sol";
import "contracts/release/utils/AddressArrayLib.sol";
import "contracts/release/utils/beacon-proxy/IBeacon.sol";
import "contracts/release/utils/beacon-proxy/IBeaconProxyFactory.sol";
