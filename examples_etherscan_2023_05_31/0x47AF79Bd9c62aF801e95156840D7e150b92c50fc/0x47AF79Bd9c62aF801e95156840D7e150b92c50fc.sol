// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "openzeppelin/contracts/math/SafeMath.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "contracts/release/extensions/integration-manager/IIntegrationManager.sol";
import "contracts/release/extensions/integration-manager/integrations/IIntegrationAdapter.sol";
import "contracts/release/extensions/integration-manager/integrations/adapters/UniswapV3Adapter.sol";
import "contracts/release/extensions/integration-manager/integrations/utils/AdapterBase.sol";
import "contracts/release/extensions/integration-manager/integrations/utils/IntegrationSelectors.sol";
import "contracts/release/extensions/integration-manager/integrations/utils/actions/UniswapV3ActionsMixin.sol";
import "contracts/release/interfaces/IUniswapV3SwapRouter.sol";
import "contracts/release/utils/AssetHelpers.sol";
