// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <councilenzyme.finance>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.6.12;

import "../../../../../persistent/address-list-registry/AddressListRegistry.sol";
import "../../../../core/fund/comptroller/ComptrollerLib.sol";
import "../utils/PolicyBase.sol";

/// title AddressListRegistryPolicyBase Contract
/// author Enzyme Council <securityenzyme.finance>
/// notice Base contract inheritable by any policy that uses the AddressListRegistry
abstract contract AddressListRegistryPolicyBase is PolicyBase {
    event ListsSetForFund(address indexed comptrollerProxy, uint256[] listIds);

    address private immutable ADDRESS_LIST_REGISTRY;

    mapping(address => uint256[]) private comptrollerProxyToListIds;

    constructor(address _policyManager, address _addressListRegistry)
        public
        PolicyBase(_policyManager)
    {
        ADDRESS_LIST_REGISTRY = _addressListRegistry;
    }

    // EXTERNAL FUNCTIONS

    /// notice Adds the initial policy settings for a fund
    /// param _comptrollerProxy The fund's ComptrollerProxy address
    /// param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        virtual
        override
        onlyPolicyManager
    {
        __updateListsForFund(_comptrollerProxy, _encodedSettings);
    }

    // INTERNAL FUNCTIONS

    /// dev Helper to create new list from encoded data
    function __createAddressListFromData(address _vaultProxy, bytes memory _newListData)
        internal
        returns (uint256 listId_)
    {
        (
            AddressListRegistry.UpdateType updateType,
            address[] memory initialItems
        ) = __decodeNewListData(_newListData);

        return
            AddressListRegistry(getAddressListRegistry()).createList(
                _vaultProxy,
                updateType,
                initialItems
            );
    }

    /// dev Helper to decode new list data
    function __decodeNewListData(bytes memory _newListData)
        internal
        pure
        returns (AddressListRegistry.UpdateType updateType_, address[] memory initialItems_)
    {
        return abi.decode(_newListData, (AddressListRegistry.UpdateType, address[]));
    }

    /// dev Helper to set the lists to be used by a given fund.
    /// This is done in a simple manner rather than the most gas-efficient way possible
    /// (e.g., comparing already-stored items with an updated list would save on storage operations during updates).
    function __updateListsForFund(address _comptrollerProxy, bytes calldata _encodedSettings)
        internal
    {
        (uint256[] memory existingListIds, bytes[] memory newListsData) = abi.decode(
            _encodedSettings,
            (uint256[], bytes[])
        );

        uint256[] memory nextListIds = new uint256[](existingListIds.length + newListsData.length);
        require(nextListIds.length != 0, "__updateListsForFund: No lists specified");

        // Clear the previously stored list ids as needed
        if (comptrollerProxyToListIds[_comptrollerProxy].length > 0) {
            delete comptrollerProxyToListIds[_comptrollerProxy];
        }

        // Add existing list ids.
        // No need to validate existence, policy will just fail if out-of-bounds index.
        for (uint256 i; i < existingListIds.length; i++) {
            nextListIds[i] = existingListIds[i];
            comptrollerProxyToListIds[_comptrollerProxy].push(existingListIds[i]);
        }

        // Create and add any new lists
        if (newListsData.length > 0) {
            address vaultProxy = ComptrollerLib(_comptrollerProxy).getVaultProxy();
            for (uint256 i; i < newListsData.length; i++) {
                uint256 nextListIdsIndex = existingListIds.length + i;
                nextListIds[nextListIdsIndex] = __createAddressListFromData(
                    vaultProxy,
                    newListsData[i]
                );
                comptrollerProxyToListIds[_comptrollerProxy].push(nextListIds[nextListIdsIndex]);
            }
        }

        emit ListsSetForFund(_comptrollerProxy, nextListIds);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// notice Gets the `ADDRESS_LIST_REGISTRY` variable value
    /// return addressListRegistry_ The `ADDRESS_LIST_REGISTRY` variable value
    function getAddressListRegistry() public view returns (address addressListRegistry_) {
        return ADDRESS_LIST_REGISTRY;
    }

    /// notice Gets the list ids used by a given fund
    /// param _comptrollerProxy The ComptrollerProxy of the fund
    /// return listIds_ The list ids
    function getListIdsForFund(address _comptrollerProxy)
        public
        view
        returns (uint256[] memory listIds_)
    {
        return comptrollerProxyToListIds[_comptrollerProxy];
    }
}
