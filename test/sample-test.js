const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Market", function () {
  let MarketContract;
  let NFTContract;
  let owner;
  let accounts;
  let listingPrice;
  const auctionPrice = ethers.utils.parseUnits("100", "ether");
  beforeEach(async () => {
    const MarketFactory = await ethers.getContractFactory("NFTMarket");
    MarketContract = await MarketFactory.deploy();
    await MarketContract.deployed();
    const NFTFactory = await ethers.getContractFactory("NFT");
    NFTContract = await NFTFactory.deploy(MarketContract.address);
    await NFTContract.deployed();
    [owner, ...accounts] = await ethers.getSigners();
    listingPrice = await MarketContract.getListingPrice();
  });
  describe("add item to market", async () => {
    beforeEach(async () => {
      for (let index = 0; index < 6; index++) {
        await NFTContract.createToken("https://");
      }
    });
    it("createMarketItem", async function () {
      for (let index = 0; index < 6; index++) {
        expect(
          await MarketContract.createMarketItem(
            NFTContract.address,
            index + 1,
            auctionPrice,
            { value: listingPrice.toString() }
          )
        ).to.emit("MarketItemCreated");
      }
      arr = await MarketContract.fetchMarketItem();
      expect(arr.length).to.equal(6);
    });
  });
  describe("sell item from market", async () => {
    beforeEach(async () => {
      for (let index = 0; index < 6; index++) {
        await NFTContract.createToken("https://");
        await MarketContract.createMarketItem(
          NFTContract.address,
          index + 1,
          auctionPrice,
          { value: listingPrice.toString() }
        );
      }
    });
    it("createMarketSale", async () => {
      arr = await MarketContract.fetchMarketItem();
      console.log(arr.length);
      created_by_me = await MarketContract.fetchItemsCreated();
      console.log(created_by_me.length);
      await MarketContract.connect(accounts[0]).createMarketSale(
        NFTContract.address,
        1,
        { value: auctionPrice }
      );
      arr = await MarketContract.fetchMarketItem();
      console.log(arr.length);
      created_by_me = await MarketContract.fetchItemsCreated();
      console.log(created_by_me.length);
      my_purchased = await MarketContract.connect(accounts[0]).fetchMyNFTs();
      console.log(my_purchased);
    });
  });
});
