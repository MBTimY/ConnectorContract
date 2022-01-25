const hre = require("hardhat");

async function main() {
    // We get the contract to deploy
    const token = "";
    const GameERC20Treasure = await hre.ethers.getContractFactory("GameERC20Treasure");
    const gameERC20Treasure = await GameERC20Treasure.deploy(["0xc8fC426d82F807e280CbE506CD381015F46EeE69"], token);

    await gameERC20Treasure.deployed();

    console.log("GameERC20Treasure deployed to:", gameERC20Treasure.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });