const hre = require('hardhat');
const {toBN, toWei, soliditySha3, encodePacked} = require('web3-utils');
const web3Utils = require('web3-utils');
const {assert} = require('./common');
const {currentTime, toUnit, fastForward} = require('../utils')();

describe("GameLootEquipment", async function () {
    let gameLootTreasure;
    let body;
    let head;
    let hand;
    let leg;
    let accessory;
    let gameLootSuit;

    let owner, user, signer, vault;

    beforeEach(async function () {
        [owner, user, signer, vault] = await hre.ethers.getSigners();

        const GameLootTreasure = await hre.ethers.getContractFactory("GameLootTreasure");
        gameLootTreasure = await GameLootTreasure.deploy(signer.address);
        await gameLootTreasure.deployed();

        // We get the contract to deploy
        const GameLootEquipment = await hre.ethers.getContractFactory("GameLootEquipment");
        const cap = 20;

        body = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, vault.address,signer.address,  cap);
        await body.deployed();

        head = await GameLootEquipment.deploy("Monster Engineer Head", "MEHead", gameLootTreasure.address, vault.address,signer.address,  cap);
        await head.deployed();

        hand = await GameLootEquipment.deploy("Monster Engineer Hand", "MEHand", gameLootTreasure.address, vault.address,signer.address,  cap);
        await hand.deployed();

        leg = await GameLootEquipment.deploy("Monster Engineer Leg", "MELeg", gameLootTreasure.address, vault.address,signer.address,  cap);
        await leg.deployed();

        accessory = await GameLootEquipment.deploy("Monster Engineer Accessory", "MEAccessory", gameLootTreasure.address, vault.address,signer.address,  cap);
        await accessory.deployed();

        const GameLootSuit = await hre.ethers.getContractFactory("GameLootSuit");
        gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MESuit", [
            body.address,
            head.address,
            hand.address,
            leg.address,
            accessory.address,
        ], toWei('0.01', 'ether'),vault.address, signer.address);
        await gameLootSuit.deployed();

        await body.setSuit(gameLootSuit.address);
        await head.setSuit(gameLootSuit.address);
        await hand.setSuit(gameLootSuit.address);
        await leg.setSuit(gameLootSuit.address);
        await accessory.setSuit(gameLootSuit.address);

        //  set config param
        await body.setPrice(toWei('0.01', "ether"));
    });

    it('constructor should be success: ', async () => {
        assert.equal(await gameLootTreasure.getSigner({from: owner.address}), signer.address);
        assert.equal(await gameLootTreasure.owner(), owner.address);

        assert.equal(await body.treasure(), gameLootTreasure.address);
        assert.equal(await body.getSigner({from: owner.address}), signer.address);
        assert.equal(await head.treasure(), gameLootTreasure.address);
        assert.equal(await head.getSigner({from: owner.address}), signer.address);
        assert.equal(await hand.treasure(), gameLootTreasure.address);
        assert.equal(await hand.getSigner({from: owner.address}), signer.address);
        assert.equal(await leg.treasure(), gameLootTreasure.address);
        assert.equal(await leg.getSigner({from: owner.address}), signer.address);
        assert.equal(await accessory.treasure(), gameLootTreasure.address);
        assert.equal(await accessory.getSigner({from: owner.address}), signer.address);

        assert.equal(await gameLootSuit.price(), toWei('0.01', "ether"));
        assert.equal(await gameLootSuit.equipments(0), body.address);
        assert.equal(await gameLootSuit.equipments(1), head.address);
        assert.equal(await gameLootSuit.equipments(2), hand.address);
        assert.equal(await gameLootSuit.equipments(3), leg.address);
        assert.equal(await gameLootSuit.equipments(4), accessory.address);
    });

    //  equipment
    it('equipment access should revert: ', async () => {
        await assert.revert(
            gameLootTreasure.connect(user).getSigner(),
            "Ownable: caller is not the owner"
        );
        await assert.revert(
            body.connect(user).getSigner(),
            "Ownable: caller is not the owner"
        );
        await assert.revert(
            head.connect(user).getSigner(),
            "Ownable: caller is not the owner"
        );
        await assert.revert(
            hand.connect(user).getSigner(),
            "Ownable: caller is not the owner"
        );
        await assert.revert(
            leg.connect(user).getSigner(),
            "Ownable: caller is not the owner"
        );
        await assert.revert(
            accessory.connect(user).getSigner(),
            "Ownable: caller is not the owner"
        );
    });

    it('equipment access should be success: ', async () => {
        //  treasure
        assert.equal(await gameLootTreasure.isUsed(0), false);
        await gameLootTreasure.setSigner(user.address);
        assert.equal(await gameLootTreasure.getSigner(), user.address);
        await gameLootTreasure.pause();
        await gameLootTreasure.unPause();

        //  equipment
        await body.setSuit(gameLootSuit.address)
        assert.equal(await body.suit(), gameLootSuit.address);
        await body.create(0, 18);
        await body.createBatch([1, 2], [18, 18]);
        assert.equal(await body.getSigner(), signer.address);

        await head.setSuit(gameLootSuit.address)
        assert.equal(await head.suit(), gameLootSuit.address);
        await head.create(0, 18);
        await head.createBatch([1, 2], [18, 18]);
        assert.equal(await head.getSigner(), signer.address);

        await hand.setSuit(gameLootSuit.address)
        assert.equal(await hand.suit(), gameLootSuit.address);
        await hand.create(0, 18);
        await hand.createBatch([1, 2], [18, 18]);
        assert.equal(await hand.getSigner(), signer.address);

        await leg.setSuit(gameLootSuit.address)
        assert.equal(await leg.suit(), gameLootSuit.address);
        await leg.create(0, 18);
        await leg.createBatch([1, 2], [18, 18]);
        assert.equal(await leg.getSigner(), signer.address);

        await accessory.setSuit(gameLootSuit.address)
        assert.equal(await accessory.suit(), gameLootSuit.address);
        await accessory.create(0, 18);
        await accessory.createBatch([1, 2], [18, 18]);
        assert.equal(await accessory.getSigner(), signer.address);
    })

    it('equipment gameMint should be success: ', async () => {
        const tokenID = 0;
        const nonce = 0;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, tokenID, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);
        await body.connect(user).gameMint(tokenID, nonce, attrIDs, attrValues, signData);
    })

    it('equipment gameMint should revert: ', async () => {
        const tokenID = 1;
        const nonce = 1;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, tokenID, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await user.signMessage(web3Utils.hexToBytes(hash));

        assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);
        await assert.revert(
            body.connect(user).gameMint(tokenID, nonce, attrIDs, attrValues, signData),
            "sign is not correct"
        );
    })

    it('equipment mint should be success: ', async () => {
        const maxAmount = 5;
        await body.openPublicSale();
        await body.setPubPer(maxAmount);
        await body.connect(user).mint(maxAmount);

        assert.equal(await body.balanceOf(user.address), maxAmount);
    })

    it('equipment mint should be revert: ', async () => {
        const maxAmount = 5;
        await body.setPubPer(maxAmount);

        await assert.revert(
            body.connect(user).mint(maxAmount),
            "public mint is not start"
        );
    })

    it('equipment presale should be success: ', async () => {
        const amount = 5;
        const nonce = 0;
        await body.openPresale();
        await body.setMaxPresale(amount);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user.address, body.address, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        assert.equal(await body.getSigner(), signer.address);
        await body.connect(user).presale(amount, nonce, signData);

        assert.equal(await body.balanceOf(user.address), amount);
    })

    it('equipment reveal should be success: ', async () => {
        const maxAmount = 5;
        await body.openPublicSale();
        await body.setPubPer(maxAmount);
        await body.connect(user).mint(maxAmount);
        assert.equal(await body.balanceOf(user.address), maxAmount);

        const tokenID = 0;
        const nonce = 0;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        await body.createBatch(attrIDs, decimals);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, tokenID, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        assert.equal(await body.getSigner(), signer.address);
        await body.connect(user).reveal(tokenID, nonce, attrIDs, attrValues, signData);
    })

    //  suit
    /*it('suit mint should be success: ', async () => {
        await gameLootSuit.publicStart();
        await body.setPubPer(maxAmount);
        await body.connect(user).mint(maxAmount);

        assert.equal(await body.balanceOf(user.address), maxAmount);
    })

    it('suit mint should be revert: ', async () => {
        const maxAmount = 5;
        await body.setPubPer(maxAmount);

        await assert.revert(
            body.connect(user).mint(maxAmount),
            "public mint is not start"
        );
    })*/
})

