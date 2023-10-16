// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin/contracts/math/SafeMath.sol";
import "contracts/release/extensions/fee-manager/IFee.sol";
import "contracts/release/extensions/fee-manager/IFeeManager.sol";
import "contracts/release/extensions/fee-manager/fees/EntranceRateBurnFee.sol";
import "contracts/release/extensions/fee-manager/fees/utils/EntranceRateFeeBase.sol";
import "contracts/release/extensions/fee-manager/fees/utils/FeeBase.sol";
