const {ethers} = require("hardhat");

async function main() {
    
    //  treasure
    /* const GameLootTreasure = await ethers.getContractFactory("GameLootTreasure");
    const gameLootTreasure = await GameLootTreasure.deploy(["0xBCcC2073ADfC46421308f62cfD9868dF00D339a8"]);
    await gameLootTreasure.deployed();
    console.log("gameLootTreasure deployed to:", gameLootTreasure.address); */

    const GameLootEquipment = await ethers.getContractFactory("GameLootEquipment");
    const cap = 20;
    const admin = "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8"
    const signers = ["0xCB2eb8fc8dDb96038C3ef8Be0058e206df9B1565", "0x03ac95391feB5E77F9D835b2E9C2d03aCfEA140D"]

    //  body
    const body = await GameLootEquipment.deploy("Monster Engineer", "ME", admin,"0xc54D167A093468F6Ed187e43c68F9c8632Bebd06", admin, signers, cap);
    await body.deployed();
    console.log("Body deployed to:", body.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});