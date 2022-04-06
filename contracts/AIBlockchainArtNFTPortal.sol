// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

/**
 * enable meta-transactions to allow for gas-less transactions. 
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */
abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}


contract AIBlockchainArtNFTPortal is ERC721URIStorage, ContextMixin, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 listingFee = 0;  //fee to list an item for sale, paid at point of sale
    uint256 commission = 500;  //sales commission in basis points, paid at point of sale 
    uint256 artCreationFee = 1 ether;  //actually 1 ROSE for Oasis Emerald, will be used to create art without watermarks
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
      uint256 tokenId;
      address payable seller;
      address payable owner;
      uint256 price;
    }

    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price
    );

    constructor() ERC721("AI Blockchain Art", "ABA") {
      owner = payable(msg.sender);
    }

    /* Updates the listing fee of the contract */
    function updateListingFee(uint _listingFee) external payable {
      require(owner == msg.sender, "Only marketplace owner can update listing fee.");
      listingFee = _listingFee;
    }

    /* Returns the listing fee of the contract */
    function getListingFee() external view returns (uint256) {
      return listingFee;
    }

    /* Updates the sales commission of the contract */
    function updateCommission(uint _commission) external payable {
      require(owner == msg.sender, "Only marketplace owner can update commission.");
      commission = _commission;
    }

    /* Returns the sales commission of the contract */
    function getCommission() external view returns (uint256) {
      return commission;
    }

    /* Updates the art creation fee */
    function updateArtCreationFee(uint _artCreationFee) external payable {
      require(owner == msg.sender, "Only marketplace owner can update art creation fee.");
      artCreationFee = _artCreationFee;
    }

    /* Returns the art creation fee */
    function getArtCreationFee() external view returns (uint256) {
      return artCreationFee;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(string memory tokenURI) external payable returns (uint) {
      _tokenIds.increment();
      uint256 newTokenId = _tokenIds.current();

      _safeMint(msg.sender, newTokenId);
      _setTokenURI(newTokenId, tokenURI);
      createMarketItem(newTokenId);
      return newTokenId;
    }

    function createMarketItem(uint256 tokenId) private {
      //require(msg.value == listingFee, "Value must be equal to listing fee");

      idToMarketItem[tokenId] = MarketItem(
        tokenId,
        payable(msg.sender),
        payable(msg.sender),
        0
      );

      emit MarketItemCreated(
        tokenId,
        msg.sender,
        msg.sender,
        0
      );
    }

    /* allows someone to list a token for sale */
    function listToken(uint256 tokenId, uint256 price) external {
      require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
      require(price > 0, "Price must be greater than 0");
      idToMarketItem[tokenId].price = price;
      idToMarketItem[tokenId].seller = payable(msg.sender);
      idToMarketItem[tokenId].owner = payable(address(this));

      _transfer(msg.sender, address(this), tokenId);
    }

    /* allows someone to delist a token for sale */
    function delistToken(uint256 tokenId) external {
      require(idToMarketItem[tokenId].seller == msg.sender, "Only item seller can perform this operation");
      idToMarketItem[tokenId].owner = payable(msg.sender);

      _transfer(address(this), msg.sender, tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId) external payable nonReentrant {
      uint price = idToMarketItem[tokenId].price;
      address seller = idToMarketItem[tokenId].seller;
      require(msg.value == price, "Please submit the asking price in order to complete the purchase");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].seller = payable(msg.sender);
      _transfer(address(this), msg.sender, tokenId);

      if (listingFee > 0) {
        payable(owner).transfer(listingFee);
        payable(seller).transfer(msg.value);
      } else if (commission > 0) {
        uint marketCommission = msg.value * commission / 10000;
        payable(owner).transfer(marketCommission);
        payable(seller).transfer(msg.value - marketCommission);
      }
    }

    /* allows someone to pay a fee to create an artistic image without watermarks */
    function payArtCreationFee() external payable {
      require(msg.value == artCreationFee, "Value must be equal to art creation fee");
    }

    /* Returns all listed market items  */
    function fetchAllMarketItems() external view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this)) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this)) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns all market items not belonging to the seller */
    function fetchMarketItems() external view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this) && idToMarketItem[i + 1].seller != msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this) && idToMarketItem[i + 1].seller != msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items that a user owns */
    function fetchMyNFTs() external view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items a user has listed for sale */
    function fetchMyListings() external view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this) && idToMarketItem[i + 1].seller == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this) && idToMarketItem[i + 1].seller == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }
    
}