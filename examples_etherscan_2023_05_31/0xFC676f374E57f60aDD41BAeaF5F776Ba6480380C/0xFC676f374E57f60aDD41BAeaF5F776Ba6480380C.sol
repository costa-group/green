// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin/contracts/math/SafeMath.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "contracts/persistent/dispatcher/IDispatcher.sol";
import "contracts/persistent/external-positions/IExternalPosition.sol";
import "contracts/persistent/protocol-fee-reserve/interfaces/IProtocolFeeReserve1.sol";
import "contracts/persistent/vault/VaultLibBase1.sol";
import "contracts/persistent/vault/VaultLibBase2.sol";
import "contracts/persistent/vault/VaultLibBaseCore.sol";
import "contracts/persistent/vault/interfaces/IExternalPositionVault.sol";
import "contracts/persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
import "contracts/persistent/vault/interfaces/IMigratableVault.sol";
import "contracts/persistent/vault/interfaces/IVaultCore.sol";
import "contracts/persistent/vault/utils/ProxiableVaultLib.sol";
import "contracts/persistent/vault/utils/SharesTokenBase.sol";
import "contracts/persistent/vault/utils/VaultLibSafeMath.sol";
import "contracts/release/core/fund/comptroller/IComptroller.sol";
import "contracts/release/core/fund/vault/IVault.sol";
import "contracts/release/core/fund/vault/VaultLib.sol";
import "contracts/release/extensions/external-position-manager/IExternalPositionManager.sol";
import "contracts/release/infrastructure/gas-relayer/GasRelayRecipientMixin.sol";
import "contracts/release/infrastructure/gas-relayer/IGasRelayPaymaster.sol";
import "contracts/release/infrastructure/protocol-fees/IProtocolFeeTracker.sol";
import "contracts/release/interfaces/IGsnForwarder.sol";
import "contracts/release/interfaces/IGsnPaymaster.sol";
import "contracts/release/interfaces/IGsnTypes.sol";
import "contracts/release/interfaces/IWETH.sol";
import "contracts/release/utils/AddressArrayLib.sol";
import "contracts/release/utils/beacon-proxy/IBeacon.sol";
import "contracts/release/utils/beacon-proxy/IBeaconProxyFactory.sol";
