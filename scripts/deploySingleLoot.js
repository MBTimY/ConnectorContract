const {ethers} = require("hardhat");

async function main() {
    //  treasure
    const GameLootTreasure = await ethers.getContractFactory("GameLootTreasure");
    const gameLootTreasure = await GameLootTreasure.deploy("0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameLootTreasure.deployed();
    console.log("gameLootTreasure deployed to:", gameLootTreasure.address);

    const GameLootEquipment = await ethers.getContractFactory("GameLootEquipment");
    const cap = 20;
    const admin = "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8"

    //  body
    const body = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, admin, admin, cap);
    await body.deployed();
    console.log("Body deployed to:", body.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});