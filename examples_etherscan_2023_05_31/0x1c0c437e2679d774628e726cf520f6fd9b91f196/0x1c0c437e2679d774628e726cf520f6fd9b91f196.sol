pragma solidity ^0.8.0;

/**
 Mr Mao loves 钱
 老子有钱
 https://twitter.com/qian_token
*/

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @dev This contract allows Mr Mao to lock an ERC721 NFT (in this case a UniswapV3 LP token)
 * and at some point in the future trigger a 7-days timer. After the timer expires, Mr Mao can withdraw the locked NFT.
 * no other action may be taken in the interim, including claiming fees.
 */
contract LOCK_QIAN {
    address public mao;
    address public nftContract;
    uint256 public lockUpEndTime;
    bool public isNFTLocked;
    bool public isWithdrawalTriggered;

    modifier onlyMao() {
        require(msg.sender == mao, "Only Mr Mao can call this function");
        _;
    }

    constructor(address _nftContract) {
        mao = msg.sender;
        nftContract = _nftContract; 
        isNFTLocked = false;
        isWithdrawalTriggered = false;
    }

    function lockNFT(uint256 tokenId) external onlyMao {
        require(!isNFTLocked, "NFT is already locked");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); 

        isNFTLocked = true;
    }

    function triggerWithdrawal() external onlyMao {
        require(isNFTLocked, "NFT is not locked");
        require(lockUpEndTime == 0, "Withdrawal is already triggered");
        lockUpEndTime = block.timestamp + 7 days; 
        isWithdrawalTriggered = true;
    }

    function cancelWithdrawalTrigger() external onlyMao {
        require(isNFTLocked, "NFT is not locked");
        require(lockUpEndTime != 0, "Withdrawal is not triggered");

        lockUpEndTime = 0;
        isWithdrawalTriggered = false;
    }

    function withdrawNFT(uint256 tokenId) external onlyMao {
        require(isNFTLocked, "NFT is not locked");
        require(lockUpEndTime != 0, "Withdrawal is not triggered");
        require(block.timestamp >= lockUpEndTime, "Lock-up period has not ended yet");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        isNFTLocked = false;
        lockUpEndTime = 0;
        isWithdrawalTriggered = false;
    }

    function changeOwner(address newOwner) external onlyMao {
        require(newOwner != address(0), "Invalid new owner address");
        mao = newOwner;
    }
}