//SPDX-License-Identifier: MIT

//    ||||||||||||\                           /|||||||||||\
//    |||||||||||||\                         /|||||||||||||\
//    ||||||||||||||\                       /||||\______\|||\
//    ||||\ _____\|||\                      ||||| |      \___\
//    |||| |     |||| |     D a r k         ||||| |        
//    |||| |     |||| |       C y c l e     ||||| |          
//    ||||||||||||||/\|                     \|||| |     /|||\
//    |||||||||||||/ /                       \|||||||||||||/\|
//    ||||||||||||/ /                         \|||||||||||/ /
//    \___________\/                           \__________\/ 

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin/contracts/utils/introspection/IERC165.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/token/ERC721/ERC721.sol";
import "openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "./IERC2981.sol";

contract PuddySociety is ERC721Enumerable, Ownable, IERC2981 {
  using Strings for uint256;

  string baseURI;
  string internal baseExtension = ".json";
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 200;
  bool public paused = false;

  constructor(
    string memory _initBaseURI
  ) ERC721("PuddySociety", "PS") {
    baseURI = _initBaseURI;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "Minting is paused");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount");
    require(totalSupply() + _mintAmount <= maxSupply, "Exceeds maximum supply");

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "Insufficient payment");
    }

    uint256 startingTokenId = totalSupply();
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, startingTokenId + i);
    }
  }


  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  { 
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw(uint256 amount) public payable onlyOwner {
    require(amount <= address(this).balance, "Insufficient balance");
    (bool success, ) = payable(owner()).call{value: amount}("");
    require(success, "Withdraw failed");
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    require(_exists(tokenId), "ERC721: nonexistent token");
    uint256 fee = (salePrice * 5) / 100;
    return (owner(), fee);
  }

}

// Contract by Dark Cycle
// https://www.puddysociety.com
// https://twitter.com/PuddySocietyNFT
// https://www.instagram.com/puddysocietynft/
// #StayOnPuddy!