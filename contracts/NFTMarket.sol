// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    // for each individual market item created _itemIds
    Counters.Counter private _itemIds;
    // for no.of items sold _itemsSold
    // why?? keep length of the array
    // few arrays : no of items I bought,created myslef,currently not sold
    Counters.Counter private _itemsSold;
    // _itemsIds = totla no of items eg: 100
    // _itemsSold = total no sold  eg: 30
    address payable owner;
    // WHose the owner,He'll make commision
    // charge a lising fee=>$$$
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    // Struct for each individual marketitem
    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    // _itemId => MarketItem
    mapping(uint256 => MarketItem) private idToMarketItem;
    //  event when MarketItem Created
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // function to create a marketItem(and put it for sale)
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        // increment _itemIds which holds the total no.of items
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        // owner = no one,because seller puts it to sell and no one owns this right now
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
    }

    // for create a sale = buying or selling action
    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(
            msg.value == price,
            "Submit the asking price to complete the purchase"
        );
        idToMarketItem[itemId].seller.transfer(msg.value); // sends money to the seller
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); // transfered ownership
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice); // come back here
    }

    // function that returns all unsold items

    function fetchMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current(); // total no of items that is currently created
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;
        // we'll be looping over an array,
        // increment on empty address(not yet sold)
        // we'll populate array of unsold items and return it
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            // if item not sold,owner address 0
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    // function that returns all items I've purchased
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0; // no of items I purchased
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            // if purchased by me(sold to me),owner will be msg.sender
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        // done the loop to get the array length
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            // if purchased by me(sold to me),owner will be msg.sender
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }
    // function that returns all items I've created
    function fetchItemsCreated() public view returns(MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0; // no of items I created
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            // if created by me(sold to me),seller will be msg.sender
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
         for (uint256 i = 0; i < totalItemCount; i++) {
            // if created by me(sold to me),seller will be msg.sender
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }
}


