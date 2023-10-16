// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/interfaces/IERC2981.sol


pragma solidity ^0.8.0;

import "openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
    // The function has been added and changed to support calling IERC2981 in the contract and allow royalties
}
