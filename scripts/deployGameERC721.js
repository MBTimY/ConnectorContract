// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const {ethers} = require("hardhat");

async function main() {
    const GameLootTreasure = await ethers.getContractFactory("GameLootTreasure");
    const gameLootTreasure = await GameLootTreasure.deploy("0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameLootTreasure.deployed();
    console.log("gameLootTreasure deployed to:", gameLootTreasure.address);

    // We get the contract to deploy
    const GameLootEquipment = await ethers.getContractFactory("GameLootEquipment");
    const cap = 20;
    const admin = "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8"

    //  身体
    const gameLootEquipment0 = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, admin, admin, cap);
    await gameLootEquipment0.deployed();
    console.log("Body deployed to:", gameLootEquipment0.address);

    //  头
    const gameLootEquipment1 = await GameLootEquipment.deploy("Monster Engineer Head", "MEHead", gameLootTreasure.address, admin, admin, cap);
    await gameLootEquipment1.deployed();
    console.log("Head deployed to:", gameLootEquipment1.address);

    //  手
    const gameLootEquipment2 = await GameLootEquipment.deploy("Monster Engineer Hand", "MEHand", gameLootTreasure.address, admin, admin, cap);
    await gameLootEquipment2.deployed();
    console.log("Hand deployed to:", gameLootEquipment2.address);

    //  腿
    const gameLootEquipment3 = await GameLootEquipment.deploy("Monster Engineer Leg", "MELeg", gameLootTreasure.address, admin, admin, cap);
    await gameLootEquipment3.deployed();
    console.log("Leg deployed to:", gameLootEquipment3.address);

    //  配件
    const gameLootEquipment4 = await GameLootEquipment.deploy("Monster Engineer Accessory", "MEAccessory", gameLootTreasure.address, admin, admin, cap);
    await gameLootEquipment4.deployed();
    console.log("Accessory deployed to:", gameLootEquipment4.address);


    const GameLootSuit = await ethers.getContractFactory("GameLootSuit");
    const gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MESuit", [
        gameLootEquipment0.address,
        gameLootEquipment1.address,
        gameLootEquipment2.address,
        gameLootEquipment3.address,
        gameLootEquipment4.address,
    ], "10000000000000000",admin, admin);
    await gameLootSuit.deployed();
    console.log("gameLootSuit deployed to:", gameLootSuit.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});