import { ethers } from "hardhat";

const main = async () => {
  const CeloNFTFactory = await ethers.getContractFactory("CeloNFT");

  const celoNftContract = await CeloNFTFactory.deploy();
  await celoNftContract.deployed();

  console.log(`Celo NFT deployed to: ${celoNftContract.address}`);

  const NFTMarketplaceFactory = await ethers.getContractFactory(
    "NFTMarketplace"
  );

  const nftMarketplaceContract = await NFTMarketplaceFactory.deploy();
  await nftMarketplaceContract.deployed();

  console.log(`NFT Marketplace deployed to: ${nftMarketplaceContract.address}`);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
