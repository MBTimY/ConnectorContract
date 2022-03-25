// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const {ethers} = require("hardhat");

async function main() {
    const admin = "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8"
    const signers = ["0xCB2eb8fc8dDb96038C3ef8Be0058e206df9B1565", "0x03ac95391feB5E77F9D835b2E9C2d03aCfEA140D"]

    //  treasure
    const GameLootTreasure = await ethers.getContractFactory("GameLootTreasure");
    const gameLootTreasure = await GameLootTreasure.deploy(admin, signers);
    await gameLootTreasure.deployed();
    console.log("gameLootTreasure deployed to:", gameLootTreasure.address);

    const GameLootEquipment = await ethers.getContractFactory("GameLootEquipment");
    const cap = 50;

    //  body
    const body = await GameLootEquipment.deploy("Monster Engineer Body", "MBody", admin, gameLootTreasure.address, admin, signers, cap);
    await body.deployed();
    console.log("Body deployed to:", body.address);

    //  head
    const head = await GameLootEquipment.deploy("Monster Engineer Head", "MHead", admin, gameLootTreasure.address, admin, signers, cap);
    await head.deployed();
    console.log("Head deployed to:", head.address);

    //  hand
    const hand = await GameLootEquipment.deploy("Monster Engineer Hand", "MHand", admin, gameLootTreasure.address, admin, signers, cap);
    await hand.deployed();
    console.log("Hand deployed to:", hand.address);

    //  leg
    const leg = await GameLootEquipment.deploy("Monster Engineer Leg", "MLeg", admin, gameLootTreasure.address, admin, signers, cap);
    await leg.deployed();
    console.log("Leg deployed to:", leg.address);

    //  accessory
    const accessory = await GameLootEquipment.deploy("Monster Engineer Accessory", "MAccessory", admin, gameLootTreasure.address, admin, signers, cap);
    await accessory.deployed();
    console.log("Accessory deployed to:", accessory.address);


    const GameLootSuit = await ethers.getContractFactory("GameLootSuit");
    const gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MSuit", [
        body.address,
        head.address,
        hand.address,
        leg.address,
        accessory.address,
    ], "10000000000000000", admin, signers);
    await gameLootSuit.deployed();
    console.log("gameLootSuit deployed to:", gameLootSuit.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});