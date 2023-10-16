// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/Pausable.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "contracts/interfaces/ITransfers.sol";
import "contracts/interfaces/IUniswapRouter.sol";
import "contracts/interfaces/IWrappedNativeCurrency.sol";
import "contracts/permit2/src/interfaces/ISignatureTransfer.sol";
import "contracts/transfers/Transfers.sol";
import "contracts/utils/Sweepable.sol";
import "hardhat/console.sol";
