// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <councilenzyme.finance>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.6.12;

import "../../../utils/NonUpgradableProxy.sol";

/// title ComptrollerProxy Contract
/// author Enzyme Council <securityenzyme.finance>
/// notice A proxy contract for all ComptrollerProxy instances
contract ComptrollerProxy is NonUpgradableProxy {
    constructor(bytes memory _constructData, address _comptrollerLib)
        public
        NonUpgradableProxy(_constructData, _comptrollerLib)
    {}
}
