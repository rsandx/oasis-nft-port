/* test/sample-test.js */
const { expect } = require('chai')

describe("NFTMarket", function() {
  it("Should create and execute market sales", async function() {
    /* deploy the marketplace */
    const NFTMarketplace = await ethers.getContractFactory("AIBlockchainArtNFTPortal")
    const nftMarketplace = await NFTMarketplace.deploy()
    await nftMarketplace.deployed()

    let listingPrice = await nftMarketplace.getListingPrice()
    listingPrice = listingPrice.toString()

    const auctionPrice = ethers.utils.parseUnits('1', 'ether')

    /* create two tokens */
    await nftMarketplace.createToken("https://www.mytokenlocation.com")
    await nftMarketplace.createToken("https://www.mytokenlocation2.com")
      
    /* query for and return the minted items */
    let items = await nftMarketplace.fetchMyNFTs()
    expect(items.length).to.equal(2)
    items = await Promise.all(items.map(async i => {
      const tokenUri = await nftMarketplace.tokenURI(i.tokenId)
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item
    }))
    console.log('minted items: ', items)

    /* list the items for sale */
    await nftMarketplace.listToken(1, auctionPrice)
    await nftMarketplace.listToken(2, auctionPrice)

    /* query for and return the listed items */
    items = await nftMarketplace.fetchMyListings()
    expect(items.length).to.equal(2)
    await nftMarketplace.delistToken(2)
    items = await nftMarketplace.fetchMyListings()
    expect(items.length).to.equal(1)
    await nftMarketplace.listToken(2, auctionPrice)

    /* query for and return the items available to buy by another user */
    const [_, buyerAddress] = await ethers.getSigners()
    items = await nftMarketplace.connect(buyerAddress).fetchMarketItems()
    expect(items.length).to.equal(2)
  
    /* execute sale of am item to another user */
    await nftMarketplace.connect(buyerAddress).createMarketSale(1, { value: auctionPrice })
    await nftMarketplace.connect(buyerAddress).createToken("https://www.otherstokenlocation.com")
    items = await nftMarketplace.connect(buyerAddress).fetchMyNFTs()
    expect(items.length).to.equal(2)
  
    /* query for and return the unsold items */
    items = await nftMarketplace.connect(buyerAddress).fetchMarketItems()
    expect(items.length).to.equal(1)
    items = await Promise.all(items.map(async i => {
      const tokenUri = await nftMarketplace.tokenURI(i.tokenId)
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item
    }))
    console.log('items available for sale: ', items)
  })

})
