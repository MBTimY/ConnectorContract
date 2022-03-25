const hre = require("hardhat");

async function main() {
    // We get the contract to deploy
    const token = "0xbCEA91b6c849ddBC39c46e75D2605D58f5DD2517";
    const signers = ["0xCB2eb8fc8dDb96038C3ef8Be0058e206df9B1565", "0x03ac95391feB5E77F9D835b2E9C2d03aCfEA140D"];
    const controller = "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8";
    const GameERC20Treasure = await hre.ethers.getContractFactory("GameERC20Treasure");
    const gameERC20Treasure = await GameERC20Treasure.deploy(signers, token, controller);

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