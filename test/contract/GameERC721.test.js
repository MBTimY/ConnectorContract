const hre = require('hardhat');
const {toBN, toWei, soliditySha3, encodePacked} = require('web3-utils');
const web3Utils = require('web3-utils');
const {assert} = require('./common');
const {currentTime, toUnit, fastForward} = require('../utils')();

describe("GameERC721Equipment", async function () {
    let gameERC721Treasure;
    let body;
    let head;
    let hand;
    let leg;
    let accessory;
    let gameERC721Suit;

    let owner, user, signer;

    beforeEach(async function () {
        [owner, user, signer] = await hre.ethers.getSigners();

        const GameERC721Treasure = await hre.ethers.getContractFactory("GameERC721Treasure");
        gameERC721Treasure = await GameERC721Treasure.deploy(signer.address);
        await gameERC721Treasure.deployed();

        // We get the contract to deploy
        const GameERC721Equipment = await hre.ethers.getContractFactory("GameERC721Equipment");

        body = await GameERC721Equipment.deploy(
            "Monster Engineer Body", "MEBody", gameERC721Treasure.address, signer.address);
        await body.deployed();

        head = await GameERC721Equipment.deploy("Monster Engineer Head", "MEHead", gameERC721Treasure.address, signer.address);
        await head.deployed();

        hand = await GameERC721Equipment.deploy("Monster Engineer Hand", "MEHand", gameERC721Treasure.address, signer.address);
        await hand.deployed();

        leg = await GameERC721Equipment.deploy("Monster Engineer Leg", "MELeg", gameERC721Treasure.address, signer.address);
        await leg.deployed();

        accessory = await GameERC721Equipment.deploy("Monster Engineer Accessory", "MEAccessory", gameERC721Treasure.address, signer.address);
        await accessory.deployed();

        const GameERC721Suit = await hre.ethers.getContractFactory("GameERC721Suit");
        gameERC721Suit = await GameERC721Suit.deploy("Monster Engineer Suit", "MESuit", [
            body.address,
            head.address,
            hand.address,
            leg.address,
            accessory.address,
        ], toWei('0.01', 'ether'), signer.address);
        await gameERC721Suit.deployed();

        await body.setSuit(gameERC721Suit.address);
        await head.setSuit(gameERC721Suit.address);
        await hand.setSuit(gameERC721Suit.address);
        await leg.setSuit(gameERC721Suit.address);
        await accessory.setSuit(gameERC721Suit.address);

        //  set config param
        await body.setPrice(toWei(0.01, "ether"));
    });

    it('constructor should be success: ', async () => {
        assert.equal(await gameERC721Treasure.getSigner({from: owner.address}), signer.address);
        assert.equal(await gameERC721Treasure.owner(), owner.address);

        assert.equal(await body.treasure(), gameERC721Treasure.address);
        assert.equal(await body.getSigner({from: owner.address}), signer.address);
        assert.equal(await head.treasure(), gameERC721Treasure.address);
        assert.equal(await head.getSigner({from: owner.address}), signer.address);
        assert.equal(await hand.treasure(), gameERC721Treasure.address);
        assert.equal(await hand.getSigner({from: owner.address}), signer.address);
        assert.equal(await leg.treasure(), gameERC721Treasure.address);
        assert.equal(await leg.getSigner({from: owner.address}), signer.address);
        assert.equal(await accessory.treasure(), gameERC721Treasure.address);
        assert.equal(await accessory.getSigner({from: owner.address}), signer.address);

        assert.equal(await gameERC721Suit.price(), toWei('0.01', "ether"));
        assert.equal(await gameERC721Suit.equipments(0), body.address);
        assert.equal(await gameERC721Suit.equipments(1), head.address);
        assert.equal(await gameERC721Suit.equipments(2), hand.address);
        assert.equal(await gameERC721Suit.equipments(3), leg.address);
        assert.equal(await gameERC721Suit.equipments(4), accessory.address);
    });

    //  equipment
    it('equipment access should revert: ', async () => {
        await assert.revert(
            gameERC721Treasure.connect(user).getSigner(),
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
        assert.equal(await gameERC721Treasure.isUsed(0), false);
        await gameERC721Treasure.setSigner(user.address);
        assert.equal(await gameERC721Treasure.getSigner(), user.address);
        await gameERC721Treasure.pause();
        await gameERC721Treasure.unPause();

        //  equipment
        await body.setSuit(gameERC721Suit.address)
        assert.equal(await body.suit(), gameERC721Suit.address);
        await body.create(0, 18);
        await body.createBatch([1, 2], [18, 18]);
        assert.equal(await body.getSigner(), signer.address);

        await head.setSuit(gameERC721Suit.address)
        assert.equal(await head.suit(), gameERC721Suit.address);
        await head.create(0, 18);
        await head.createBatch([1, 2], [18, 18]);
        assert.equal(await head.getSigner(), signer.address);

        await hand.setSuit(gameERC721Suit.address)
        assert.equal(await hand.suit(), gameERC721Suit.address);
        await hand.create(0, 18);
        await hand.createBatch([1, 2], [18, 18]);
        assert.equal(await hand.getSigner(), signer.address);

        await leg.setSuit(gameERC721Suit.address)
        assert.equal(await leg.suit(), gameERC721Suit.address);
        await leg.create(0, 18);
        await leg.createBatch([1, 2], [18, 18]);
        assert.equal(await leg.getSigner(), signer.address);

        await accessory.setSuit(gameERC721Suit.address)
        assert.equal(await accessory.suit(), gameERC721Suit.address);
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
        await gameERC721Suit.publicStart();
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

