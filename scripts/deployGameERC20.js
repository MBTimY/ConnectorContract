const hre = require("hardhat");

async function main() {
    // We get the contract to deploy
    const GameERC20Factory = await hre.ethers.getContractFactory("GameERC20Factory");
    const gameERC20Factory = await GameERC20Factory.deploy();

    await gameERC20Factory.deployed();

    console.log("GameERC20Factory deployed to:", gameERC20Factory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
