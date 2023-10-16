// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <councilenzyme.finance>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/PolicyBase.sol";

/// title MinMaxInvestmentPolicy Contract
/// author Enzyme Council <securityenzyme.finance>
/// notice A policy that restricts the amount of the fund's denomination asset that a user can
/// send in a single call to buy shares in a fund
contract MinMaxInvestmentPolicy is PolicyBase {
    event FundSettingsSet(
        address indexed comptrollerProxy,
        uint256 minInvestmentAmount,
        uint256 maxInvestmentAmount
    );

    struct FundSettings {
        uint256 minInvestmentAmount;
        uint256 maxInvestmentAmount;
    }

    mapping(address => FundSettings) private comptrollerProxyToFundSettings;

    constructor(address _policyManager) public PolicyBase(_policyManager) {}

    /// notice Adds the initial policy settings for a fund
    /// param _comptrollerProxy The fund's ComptrollerProxy address
    /// param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __setFundSettings(_comptrollerProxy, _encodedSettings);
    }

    /// notice Whether or not the policy can be disabled
    /// return canDisable_ True if the policy can be disabled
    function canDisable() external pure virtual override returns (bool canDisable_) {
        return true;
    }

    /// notice Provides a constant string identifier for a policy
    /// return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "MIN_MAX_INVESTMENT";
    }

    /// notice Gets the implemented PolicyHooks for a policy
    /// return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        pure
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PostBuyShares;

        return implementedHooks_;
    }

    /// notice Updates the policy settings for a fund
    /// param _comptrollerProxy The fund's ComptrollerProxy address
    /// param _encodedSettings Encoded settings to apply to a fund
    function updateFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __setFundSettings(_comptrollerProxy, _encodedSettings);
    }

    /// notice Checks whether a particular condition passes the rule for a particular fund
    /// param _comptrollerProxy The fund's ComptrollerProxy address
    /// param _investmentAmount The investment amount for which to check the rule
    /// return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, uint256 _investmentAmount)
        public
        view
        returns (bool isValid_)
    {
        uint256 minInvestmentAmount = comptrollerProxyToFundSettings[_comptrollerProxy]
            .minInvestmentAmount;
        uint256 maxInvestmentAmount = comptrollerProxyToFundSettings[_comptrollerProxy]
            .maxInvestmentAmount;

        // Both minInvestmentAmount and maxInvestmentAmount can be 0 in order to close the fund
        // temporarily
        if (minInvestmentAmount == 0) {
            return _investmentAmount <= maxInvestmentAmount;
        } else if (maxInvestmentAmount == 0) {
            return _investmentAmount >= minInvestmentAmount;
        }
        return
            _investmentAmount >= minInvestmentAmount && _investmentAmount <= maxInvestmentAmount;
    }

    /// notice Apply the rule with the specified parameters of a PolicyHook
    /// param _comptrollerProxy The fund's ComptrollerProxy address
    /// param _encodedArgs Encoded args with which to validate the rule
    /// return isValid_ True if the rule passes
    /// dev onlyPolicyManager validation not necessary, as state is not updated and no events are fired
    function validateRule(
        address _comptrollerProxy,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (, uint256 investmentAmount, , ) = __decodePostBuySharesValidationData(_encodedArgs);

        return passesRule(_comptrollerProxy, investmentAmount);
    }

    /// dev Helper to set the policy settings for a fund
    /// param _comptrollerProxy The fund's ComptrollerProxy address
    /// param _encodedSettings Encoded settings to apply to a fund
    function __setFundSettings(address _comptrollerProxy, bytes memory _encodedSettings) private {
        (uint256 minInvestmentAmount, uint256 maxInvestmentAmount) = abi.decode(
            _encodedSettings,
            (uint256, uint256)
        );

        require(
            maxInvestmentAmount == 0 || minInvestmentAmount < maxInvestmentAmount,
            "__setFundSettings: minInvestmentAmount must be less than maxInvestmentAmount"
        );

        comptrollerProxyToFundSettings[_comptrollerProxy]
            .minInvestmentAmount = minInvestmentAmount;
        comptrollerProxyToFundSettings[_comptrollerProxy]
            .maxInvestmentAmount = maxInvestmentAmount;

        emit FundSettingsSet(_comptrollerProxy, minInvestmentAmount, maxInvestmentAmount);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// notice Gets the min and max investment amount for a given fund
    /// param _comptrollerProxy The ComptrollerProxy of the fund
    /// return fundSettings_ The fund settings
    function getFundSettings(address _comptrollerProxy)
        external
        view
        returns (FundSettings memory fundSettings_)
    {
        return comptrollerProxyToFundSettings[_comptrollerProxy];
    }
}
