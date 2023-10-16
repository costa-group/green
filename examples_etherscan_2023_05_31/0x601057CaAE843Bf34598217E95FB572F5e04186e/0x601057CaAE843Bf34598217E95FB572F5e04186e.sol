// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "contracts/interfaces/IAngleRouterSidechain.sol";
import "contracts/interfaces/ICoreBorrow.sol";
import "contracts/interfaces/ISwapper.sol";
import "contracts/interfaces/external/lido/IWStETH.sol";
import "contracts/interfaces/external/uniswap/IUniswapRouter.sol";
import "contracts/swapper/Swapper.sol";
