import { ethers } from "hardhat";

async function main() {
  // Replace this with the actual token address
  const tokenAddress = "0xYourTokenAddressHere";
  // Deploy the Staking contract
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(tokenAddress);
  // Wait for the contract to be deployed
  await staking.deployed();

  console.log("Staking contract deployed at:", staking.address);
  // get the owner of the contract
  const owner = await staking.owner();
  console.log("Owner of the contract is:", owner);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
