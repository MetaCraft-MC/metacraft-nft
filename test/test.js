const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MetaCraftTest", function () {
  it("Should return the new greeting once it's changed", async function () {
    const nft = await ethers.getContractFactory("MetaCraft");
    const greeter = await nft.deploy(10000, 1000, 5);
    await greeter.deployed();

    expect(await greeter.mintSupplyCount).to.equal(10000);
  });
});
