// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
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
    const signer = "0xc8fC426d82F807e280CbE506CD381015F46EeE69"

    //  body
    const body = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, admin, [signer], cap);
    await body.deployed();
    console.log("Body deployed to:", body.address);

    //  head
    const head = await GameLootEquipment.deploy("Monster Engineer Head", "MEHead", gameLootTreasure.address, admin, [signer], cap);
    await head.deployed();
    console.log("Head deployed to:", head.address);

    //  hand
    const hand = await GameLootEquipment.deploy("Monster Engineer Hand", "MEHand", gameLootTreasure.address, admin, [signer], cap);
    await hand.deployed();
    console.log("Hand deployed to:", hand.address);

    //  leg
    const leg = await GameLootEquipment.deploy("Monster Engineer Leg", "MELeg", gameLootTreasure.address, admin, [signer], cap);
    await leg.deployed();
    console.log("Leg deployed to:", leg.address);

    //  accessory
    const accessory = await GameLootEquipment.deploy("Monster Engineer Accessory", "MEAccessory", gameLootTreasure.address, admin, [signer], cap);
    await accessory.deployed();
    console.log("Accessory deployed to:", accessory.address);


    const GameLootSuit = await ethers.getContractFactory("GameLootSuit");
    const gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MESuit", [
        body.address,
        head.address,
        hand.address,
        leg.address,
        accessory.address,
    ], "10000000000000000", admin, [signer]);
    await gameLootSuit.deployed();
    console.log("gameLootSuit deployed to:", gameLootSuit.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});