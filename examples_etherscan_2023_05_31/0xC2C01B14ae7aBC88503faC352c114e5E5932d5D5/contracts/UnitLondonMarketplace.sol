// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Proxy.sol";
import "./utils/RoyaltySplitter.sol";
import "./utils/Vault.sol";
import "./utils/IOwnable.sol";

interface INFT {
  function mint(uint256 tokenId, string calldata metadata, address user) external;

  function mint(uint256 tokenId, uint256 amount, string calldata metadata, address user) external;

  function transferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

  function ownerOf(uint256 tokenId) external view returns (address);

  function balanceOf(address account, uint256 id) external view returns (uint256);

  function initialize(string calldata _name, string calldata _symbol) external;

  function transferOwnership(address newOwner) external;
}

contract UnitLondonMarketplace is Vault, IOwnable {
  struct CollectionData {
    address artist;
    address splitter;
    uint32 mintFeePlatform;
    uint32 royaltyCollection;
    uint32 royaltyPlatform;
    uint32 logicIndex;
    string contractURI;
  }

  struct TokenData {
    uint256 price;
    uint256 amount;
    uint256 startDate;
    string metadata;
  }

  event PlatformUpdated(address oldPlatform, address newPlatform);
  event CollectionRegistered(address collection, CollectionData data);
  event TokenUpdated(address collection, uint256 tokenId, TokenData data);
  event TokenSold(address collection, uint256 tokenId, uint256 amount, uint256 value);
  event TokenAirdropped(address collection, uint256 tokenId, address[] redeemers);
  event TokenRedeemed(address collection, uint256 tokenId, address[] redeemers, uint256[] prices);

  uint256 constant RATIO = 10000;

  address implementation_;
  address public override owner;
  bool public initialized;

  address[2] public logics;

  uint32 public mintFeePlatform;
  uint32 public royaltyPlatform;

  mapping(address => bool) public artists;

  mapping(address => CollectionData) public collections;
  mapping(address => mapping(uint256 => TokenData)) public tokens;

  address public platform;
  address public trdparty;

  function onlyOwner() internal view returns (bool) {
    return msg.sender == owner;
  }

  function onlyTrdparty() internal view returns (bool) {
    return msg.sender == owner || msg.sender == trdparty;
  }

  function onlyGrant() internal view returns (bool) {
    return msg.sender == owner || msg.sender == platform;
  }

  function initialize(address[2] memory _logics) external {
    require(!initialized && onlyOwner());
    initialized = true;

    logics = _logics;
    mintFeePlatform = 3000; // 30.00%
    royaltyPlatform = 200; // 2.00%

    emit OwnershipTransferred(address(0), msg.sender);
  }

  function setPlatform(address newPlatform) external {
    if (platform == address(0)) {
      require(onlyOwner());
    } else {
      require(onlyGrant());
    }

    emit PlatformUpdated(platform, newPlatform);
    platform = newPlatform;
  }

  function setTrdparty(address newTrdparty) external {
    require(onlyOwner());

    trdparty = newTrdparty;
  }

  function setMintFeePlatform(uint32 newMintFeePlatform) external {
    require(onlyGrant());
    mintFeePlatform = newMintFeePlatform;
  }

  function setRoyaltyPlatform(uint32 newRoyaltyPlatform) external {
    require(onlyGrant());
    royaltyPlatform = newRoyaltyPlatform;
  }

  function setArtists(address[] calldata _artists) external {
    require(onlyGrant());
    for (uint256 i = 0; i < _artists.length; i++) {
      artists[_artists[i]] = true;
    }
  }

  function removeArtist(address artist) external {
    require(onlyGrant());
    delete artists[artist];
  }

  function withdraw() external {
    require(onlyGrant());
    payable(platform).transfer(address(this).balance);
  }

  function onlyArtist(address artist) internal view returns (bool) {
    require(artists[artist], "Invalid artist");
    return onlyGrant() || msg.sender == artist;
  }

  function registerCollection(
    uint32 logicIndex,
    string calldata name,
    string calldata symbol,
    address artist,
    uint32 royaltyArtist,
    string calldata contractURI
  ) external {
    require(onlyArtist(artist), "Invalid permission");
    Proxy proxy = new Proxy();
    proxy.setImplementation(logics[logicIndex]);

    address collection = address(proxy);
    CollectionData storage data = collections[collection];
    data.artist = artist;
    data.splitter = address(new RoyaltySplitter());
    data.mintFeePlatform = mintFeePlatform;
    data.royaltyCollection = royaltyArtist + royaltyPlatform;
    data.royaltyPlatform = royaltyPlatform;
    data.logicIndex = logicIndex;
    data.contractURI = contractURI;

    INFT(collection).initialize(name, symbol);
    INFT(collection).transferOwnership(artist);

    emit CollectionRegistered(collection, data);
  }

  function collectionURI(address collection) external view returns (string memory) {
    return collections[collection].contractURI;
  }

  function syncLogic(Proxy collection) external {
    collection.setImplementation(logics[collections[address(collection)].logicIndex]);
  }

  function registerManifold(uint32 logicIndex, address manifold, address artist, string calldata contractURI) external {
    require(onlyArtist(artist), "Invalid permission");

    CollectionData storage data = collections[manifold];
    require(data.artist == address(0), "Invalid collection");
    data.artist = artist;
    data.logicIndex = logicIndex;
    data.mintFeePlatform = mintFeePlatform;
    data.contractURI = contractURI;

    emit CollectionRegistered(manifold, data);
  }

  function updateCollectionMintFeePlatform(address collection, uint32 newMintFeePlatform) external {
    CollectionData storage data = collections[collection];

    require(onlyGrant(), "Invalid permission");
    data.mintFeePlatform = newMintFeePlatform;
    emit CollectionRegistered(collection, data);
  }

  function updateCollectionRoyaltyArtist(address collection, uint32 royaltyArtist) external {
    CollectionData storage data = collections[collection];

    require(onlyGrant(), "Invalid permission");
    data.royaltyCollection = royaltyArtist + royaltyPlatform;
    emit CollectionRegistered(collection, data);
  }

  function updateCollectionURI(address collection, string calldata contractURI) external {
    CollectionData storage data = collections[collection];

    require(onlyGrant(), "Invalid permission");
    data.contractURI = contractURI;
    emit CollectionRegistered(collection, data);
  }

  function emitCollectionRegistered(address[] calldata registers) external {
    require(onlyGrant(), "Invalid permission");

    for (uint256 i = 0; i < registers.length; i++) {
      address collection = registers[i];
      emit CollectionRegistered(collection, collections[collection]);
    }
  }

  function addToken(
    address collection,
    uint256 tokenId,
    uint256 tokenLogic, // amount - 0 for 721, N for 1155
    uint256 price,
    uint256 startDate,
    string calldata metadata
  ) external {
    require(onlyGrant() || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.price == 0, "Invalid token");

    if (collections[collection].splitter == address(0)) {
      // Manifolds
      if (tokenLogic == 0) {
        // ERC721
        require(INFT(collection).ownerOf(tokenId) == address(this), "Invalid owner");
      } else {
        // ERC1155
        require(INFT(collection).balanceOf(address(this), tokenId) == tokenLogic, "Invalid owner");
      }
    } else {
      data.metadata = metadata;
    }

    data.amount = tokenLogic;
    data.price = price;
    data.startDate = startDate;

    emit TokenUpdated(collection, tokenId, data);
  }

  function updateTokenPrice(address collection, uint256 tokenId, uint256 price) external {
    require(onlyGrant() || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    // require(data.price > 0, "Invalid token");

    data.price = price;

    emit TokenUpdated(collection, tokenId, data);
  }

  function updateTokenStartDate(address collection, uint256 tokenId, uint256 startDate) external {
    require(onlyGrant() || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.startDate > 0, "Invalid token");

    data.startDate = startDate;

    emit TokenUpdated(collection, tokenId, data);
  }

  function updateTokenMetadata(address collection, uint256 tokenId, string calldata metadata) external {
    require(onlyGrant() || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];

    data.metadata = metadata;

    emit TokenUpdated(collection, tokenId, data);
  }

  function buy(
    address collection,
    uint256 tokenId,
    uint256 tokenLogic // amount - 0 for 721, N for 1155
  ) external virtual payable {
    address user = msg.sender;
    uint256 value = msg.value;
    TokenData storage tokenData = tokens[collection][tokenId];

    CollectionData memory collectionData = collections[collection];
    uint256 fee = (value * collectionData.mintFeePlatform) / RATIO;
    payable(platform).transfer(fee);
    payable(collectionData.artist).transfer(value - fee);

    // require(tokenData.price > 0, "Invalid token");
    require(tokenData.startDate < block.timestamp, "Invalid sale");
    if (tokenLogic == 0) {
      // ERC721
      require(tokenData.price == value, "Invalid price");

      if (collections[collection].splitter == address(0)) {
        // Manifolds
        INFT(collection).transferFrom(address(this), user, tokenId);
      } else {
        INFT(collection).mint(tokenId, tokenData.metadata, user);
      }
      tokenLogic = 1;
    } else {
      // ERC1155
      require(tokenData.price * tokenLogic == value, "Invalid price");

      if (collections[collection].splitter == address(0)) {
        // Manifolds
        INFT(collection).safeTransferFrom(address(this), user, tokenId, tokenLogic, "");
      } else {
        tokenData.amount = tokenData.amount - tokenLogic;
        INFT(collection).mint(tokenId, tokenLogic, tokenData.metadata, user);
      }
    }
    emit TokenSold(collection, tokenId, tokenLogic, value);
  }

  function airdrop(address collection, uint256 tokenId, address[] calldata redeemers) external virtual {
    require(onlyGrant(), "Invalid permission");
    TokenData storage data = tokens[collection][tokenId];
    // require(data.price > 0, "Invalid token");

    if (collections[collection].splitter == address(0)) {
      // Manifolds
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFT(collection).safeTransferFrom(address(this), redeemers[i], tokenId, 1, "");
        }
      } else {
        // ERC721
        INFT(collection).transferFrom(address(this), redeemers[0], tokenId);
      }
    } else {
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        data.amount = data.amount - tokenLogic;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFT(collection).mint(tokenId, 1, data.metadata, redeemers[i]);
        }
      } else {
        // ERC721
        INFT(collection).mint(tokenId, data.metadata, redeemers[0]);
      }
    }
    emit TokenAirdropped(collection, tokenId, redeemers);
  }

  function redeem(
    address collection,
    uint256 tokenId,
    address[] calldata redeemers,
    uint256[] calldata prices
  ) external virtual {
    require(onlyTrdparty());
    TokenData storage data = tokens[collection][tokenId];
    // require(data.price > 0, "Invalid token");

    if (collections[collection].splitter == address(0)) {
      // Manifolds
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFT(collection).safeTransferFrom(address(this), redeemers[i], tokenId, 1, "");
        }
      } else {
        // ERC721
        INFT(collection).transferFrom(address(this), redeemers[0], tokenId);
      }
    } else {
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        data.amount = data.amount - tokenLogic;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFT(collection).mint(tokenId, 1, data.metadata, redeemers[i]);
        }
      } else {
        // ERC721
        INFT(collection).mint(tokenId, data.metadata, redeemers[0]);
      }
    }
    emit TokenRedeemed(collection, tokenId, redeemers, prices);
  }

  function royaltyInfo(address collection, uint256, uint256 value) external view returns (address, uint256) {
    CollectionData memory data = collections[collection];
    return (data.splitter, (value * data.royaltyCollection) / RATIO);
  }

  function collectRoyalties(address collection, ICoin[] calldata coins) external {
    address artist = msg.sender;
    CollectionData memory data = collections[collection];
    require(data.artist == artist, "Invalid artist");
    (uint256 balance, uint256[] memory coinBalances) = RoyaltySplitter(payable(data.splitter)).claim(coins);

    uint256 royalties = balance;
    uint256 feePlatform = (royalties * data.royaltyPlatform) / data.royaltyCollection;
    payable(platform).transfer(feePlatform);
    payable(artist).transfer(royalties - feePlatform);

    for (uint256 i = 0; i < coinBalances.length; i++) {
      royalties = coinBalances[i];
      feePlatform = (royalties * data.royaltyPlatform) / data.royaltyCollection;
      coins[i].transfer(platform, feePlatform);
      coins[i].transfer(artist, royalties - feePlatform);
    }
  }

  function transferOwnership(address newOwner) public virtual override {
    require(msg.sender == owner);
    owner = newOwner;
    emit OwnershipTransferred(msg.sender, newOwner);
  }

  function setLogic(uint256 index, address newLogic) external {
    require(onlyOwner());
    logics[index] = newLogic;
  }

  function escapeTokens(address token, uint256 amount) external {
    require(onlyGrant());
    INFT(token).transferFrom(address(this), msg.sender, amount);
  }

  function escapeSafeTokens(address token, uint256 id, uint256 amount) external {
    require(onlyGrant());
    INFT(token).safeTransferFrom(address(this), msg.sender, id, amount, "");
  }
}
