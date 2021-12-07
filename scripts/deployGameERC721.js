// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const {ethers} = require("hardhat");

async function main() {
    const GameERC721Treasure = await ethers.getContractFactory("GameERC721Treasure");
    const gameERC721Treasure = await GameERC721Treasure.deploy("0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameERC721Treasure.deployed();
    console.log("gameERC721Treasure deployed to:", gameERC721Treasure.address);

    // We get the contract to deploy
    const GameERC721Equipment = await ethers.getContractFactory("GameERC721Equipment");

    //  身体
    const gameERC721Equipment0 = await GameERC721Equipment.deploy("Monster Engineer Body", "MEBody", gameERC721Treasure.address, "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameERC721Equipment0.deployed();
    console.log("Body deployed to:", gameERC721Equipment0.address);

    //  头
    const gameERC721Equipment1 = await GameERC721Equipment.deploy("Monster Engineer Head", "MEHead", gameERC721Treasure.address, "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameERC721Equipment1.deployed();
    console.log("Head deployed to:", gameERC721Equipment1.address);

    //  手
    const gameERC721Equipment2 = await GameERC721Equipment.deploy("Monster Engineer Hand", "MEHand", gameERC721Treasure.address, "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameERC721Equipment2.deployed();
    console.log("Hand deployed to:", gameERC721Equipment2.address);

    //  腿
    const gameERC721Equipment3 = await GameERC721Equipment.deploy("Monster Engineer Leg", "MELeg", gameERC721Treasure.address, "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameERC721Equipment3.deployed();
    console.log("Leg deployed to:", gameERC721Equipment3.address);

    //  配件
    const gameERC721Equipment4 = await GameERC721Equipment.deploy("Monster Engineer Accessory", "MEAccessory", gameERC721Treasure.address, "0xBCcC2073ADfC46421308f62cfD9868dF00D339a8");
    await gameERC721Equipment4.deployed();
    console.log("Accessory deployed to:", gameERC721Equipment4.address);


    const GameERC721Suit = await ethers.getContractFactory("GameERC721Suit");
    const gameERC721Suit = await GameERC721Suit.deploy("Monster Engineer Suit", "MESuit", [
        gameERC721Equipment0.address,
        gameERC721Equipment1.address,
        gameERC721Equipment2.address,
        gameERC721Equipment3.address,
        gameERC721Equipment4.address,
    ], "10000000000000000");
    await gameERC721Suit.deployed();
    console.log("gameERC721Suit deployed to:", gameERC721Suit.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});