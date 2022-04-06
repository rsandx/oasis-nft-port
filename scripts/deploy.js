const hre = require("hardhat");
const fs = require('fs');

async function main() {
  const NFTMarketplace = await hre.ethers.getContractFactory("AIBlockchainArtNFTPortal");
  const nftMarketplace = await NFTMarketplace.deploy();
  await nftMarketplace.deployed();
  console.log("nftMarketplace deployed to:", nftMarketplace.address);

  fs.writeFileSync('./config.js', `
  export const marketplaceAddress = "${nftMarketplace.address}"
  export const token = "ROSE"
  `)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
