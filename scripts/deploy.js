// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run('compile');

  // We get the contract to deploy
  const MetaCraft = await hre.ethers.getContractFactory("MetaCraft");
  // uint256 _mintSupplyCount,
  // uint256 _ownerMintReserveCount,
  // uint256 _whitelistExpirationTimestamp,
  // uint256 _maxWhitelistCount,
  // uint256 _maxMintPerAddress
  console.log("deploying metacraft nft...");
  const nft = await MetaCraft.deploy(10000, 1000, 5);

  await nft.deployed();

  console.log("MetaCraft NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
