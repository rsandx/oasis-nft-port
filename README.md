# oasis-nft-portal

The Smart Contract to mint and transact NFTs in AI Blockchain Art NFT Portal for Oasis Network

A NFT can be minted by anyone with basic descriptions and a file uploaded to IPFS, then it can be listed with a price for sale in the marketplace. The seller can also cancel the sale using the delist method, then list it again with a different price. A live demo is available at https://aiblockchain.art/nftportal/, please add Emerald Testnet to MetaMask and connect with a test account if you want to try out minting NFTs and making transactions. 

## Install dependencies

`yarn` or `npm install`

## Run a local ETH node

`npx hardhat node`

## Compile

`npx hardhat compile`

## Run tests

`npx hardhat test`

## Deploy

`npx hardhat run scripts/deploy.js --network emeraldTestnet`

> NOTES: once the contract is deployed a config.js will be generated containing the contract address to be used for the frontend.

## Etherscan verification

`npx hardhat verify --network NETWORK_NAME CONTRACT_ADDRESS`

More info about hardhat please refer to https://hardhat.org.
