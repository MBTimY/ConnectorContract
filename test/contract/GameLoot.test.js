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

    let owner, user, signer, vault, user1;

    beforeEach(async function () {
        [owner, user, signer, vault, user1] = await hre.ethers.getSigners();

        const GameLootTreasure = await hre.ethers.getContractFactory("GameLootTreasure");
        gameLootTreasure = await GameLootTreasure.deploy(signer.address);
        await gameLootTreasure.deployed();

        // We get the contract to deploy
        const GameLootEquipment = await hre.ethers.getContractFactory("GameLootEquipment");
        const cap = 20;

        body = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, vault.address, signer.address, cap);
        await body.deployed();

        head = await GameLootEquipment.deploy("Monster Engineer Head", "MEHead", gameLootTreasure.address, vault.address, signer.address, cap);
        await head.deployed();

        hand = await GameLootEquipment.deploy("Monster Engineer Hand", "MEHand", gameLootTreasure.address, vault.address, signer.address, cap);
        await hand.deployed();

        leg = await GameLootEquipment.deploy("Monster Engineer Leg", "MELeg", gameLootTreasure.address, vault.address, signer.address, cap);
        await leg.deployed();

        accessory = await GameLootEquipment.deploy("Monster Engineer Accessory", "MEAccessory", gameLootTreasure.address, vault.address, signer.address, cap);
        await accessory.deployed();

        const GameLootSuit = await hre.ethers.getContractFactory("GameLootSuit");
        gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MESuit", [
            body.address,
            head.address,
            hand.address,
            leg.address,
            accessory.address,
        ], toWei('0.01', 'ether'), vault.address, signer.address);
        await gameLootSuit.deployed();

        //  set suit address
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
        assert.equal(await body.vault(), vault.address);

        assert.equal(await head.treasure(), gameLootTreasure.address);
        assert.equal(await head.getSigner({from: owner.address}), signer.address);
        assert.equal(await head.vault(), vault.address);

        assert.equal(await hand.treasure(), gameLootTreasure.address);
        assert.equal(await hand.getSigner({from: owner.address}), signer.address);
        assert.equal(await hand.vault(), vault.address);

        assert.equal(await leg.treasure(), gameLootTreasure.address);
        assert.equal(await leg.getSigner({from: owner.address}), signer.address);
        assert.equal(await leg.vault(), vault.address);

        assert.equal(await accessory.treasure(), gameLootTreasure.address);
        assert.equal(await accessory.getSigner({from: owner.address}), signer.address);
        assert.equal(await accessory.vault(), vault.address);

        assert.equal(await gameLootSuit.price(), toWei('0.01', "ether"));
        assert.equal(await gameLootSuit.equipments(0), body.address);
        assert.equal(await gameLootSuit.equipments(1), head.address);
        assert.equal(await gameLootSuit.equipments(2), hand.address);
        assert.equal(await gameLootSuit.equipments(3), leg.address);
        assert.equal(await gameLootSuit.equipments(4), accessory.address);
        assert.equal(await gameLootSuit.getSigner({from: owner.address}), signer.address);
        assert.equal(await gameLootSuit.vault(), vault.address);
    });

    it('constructor params access should revert: ', async () => {
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
        await assert.revert(
            gameLootSuit.connect(user).getSigner(),
            "Ownable: caller is not the owner"
        );
    });

    it('constructor params access should be success: ', async () => {
        //  treasure
        await gameLootTreasure.connect(owner).setSigner(user.address);
        assert.equal(await gameLootTreasure.getSigner(), user.address);
        await gameLootTreasure.connect(owner).setSigner(user.address);
        assert.equal(await gameLootTreasure.getSigner(), user.address);

        //  equipment
        await body.connect(owner).setSuit(gameLootSuit.address)
        assert.equal(await body.suit(), gameLootSuit.address);
        assert.equal(await body.connect(owner).getSigner(), signer.address);

        // suit
        assert.equal(await gameLootSuit.connect(owner).getSigner(), signer.address);
    })

    it('gameMint should revert: ', async () => {
        const tokenID = 1;
        const nonce = 1;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
        const attrValuesError = [10, 11, 12, 13, 14, 15, 16, 17, 18];

        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, tokenID, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        //  user signed not signer signed
        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));
        const signDataRight = await signer.signMessage(web3Utils.hexToBytes(hash));

        await assert.revert(
            body.connect(user).gameMint(tokenID, nonce, attrIDs, attrValues, signDataError),
            "sign is not correct"
        );

        //  test nonce
        await body.connect(user).gameMint(tokenID, nonce, attrIDs, attrValues, signDataRight);
        await assert.revert(
            body.connect(user).gameMint(tokenID, nonce, attrIDs, attrValues, signDataRight),
            "nonce is used"
        );

        //  param length
        const nonce_ = 0;
        const originalDataError = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, tokenID, nonce_, attrIDs, attrValuesError]
        );
        const hashError = hre.ethers.utils.keccak256(originalDataError);
        const signDataError_ = await signer.signMessage(web3Utils.hexToBytes(hashError));
        await assert.revert(
            body.connect(user).gameMint(tokenID, nonce_, attrIDs, attrValuesError, signDataError_),
            "param length error"
        );
    })

    it('gameMint should be success: ', async () => {
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

    it('mint should be revert: ', async () => {
        const price = await body.price();

        const maxAmount = 5;
        await body.setPubPer(maxAmount);
        await body.setMaxSupply(maxAmount);

        await assert.revert(
            body.connect(user).mint(maxAmount),
            "public mint is not start"
        );

        await body.openPublicSale();
        await assert.revert(
            body.connect(user).mint(maxAmount + 1),
            "exceed max per"
        );

        const v = toBN(price).mul(toBN(maxAmount - 1)).toString();
        await assert.revert(
            body.connect(user).mint(maxAmount, {value: v}),
            "tx value is not correct"
        );

        const v_ = toBN(price).mul(toBN(maxAmount)).toString();
        await body.connect(user).mint(maxAmount, {value: v_});
        assert.equal(await body.balanceOf(user.address), maxAmount);
        await assert.revert(
            body.connect(user).mint(maxAmount, {value: v_}),
            "has minted"
        );

        await assert.revert(
            body.connect(user1).mint(maxAmount, {value: v_}),
            "sale out"
        );
    })

    it('mint should be success: ', async () => {
        const price = await body.price();
        const maxAmount = 5;
        await body.openPublicSale();
        await body.setPubPer(maxAmount);
        await body.setMaxSupply(maxAmount + 1);

        const v = toBN(price).mul(toBN(maxAmount)).toString();
        await body.connect(user).mint(maxAmount, {value: v});

        assert.equal(await body.balanceOf(user.address), maxAmount);
    })

    it('presale should be revert: ', async () => {
        const price = await body.price();
        const amount = 5;
        const nonce = 0;
        await body.setPrePer(amount);
        await body.setMaxPresale(amount);
        const v = toBN(price).mul(toBN(amount)).toString();
        const v1 = toBN(price).mul(toBN(amount + 1)).toString();
        const v2 = toBN(price).mul(toBN(amount - 1)).toString();

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user.address, body.address, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await assert.revert(
            body.connect(user).presale(amount, nonce, signData, {value: v}),
            "presale is not start"
        );

        await body.openPresale();
        await assert.revert(
            body.connect(user).presale(amount + 1, nonce, signData, {value: v1}),
            "exceed max per"
        );

        await assert.revert(
            body.connect(user).presale(amount, nonce, signData, {value: v2}),
            "tx value is not correct"
        );

        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));
        await assert.revert(
            body.connect(user).presale(amount, nonce, signDataError, {value: v}),
            "sign is not correct"
        );

        await body.connect(user).presale(amount, nonce, signData, {value: v});
        await assert.revert(
            body.connect(user).presale(amount, nonce, signDataError, {value: v}),
            "has minted"
        );

        const originalData1 = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user1.address, body.address, nonce + 1]
        );
        const hash1 = hre.ethers.utils.keccak256(originalData1);
        const signData1 = await signer.signMessage(web3Utils.hexToBytes(hash1));
        await assert.revert(
            body.connect(user1).presale(amount, nonce + 1, signData1, {value: v}),
            "presale out"
        );

        await body.setMaxPresale(amount * 2);
        const originalData2 = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user1.address, body.address, nonce]
        );
        const hash2 = hre.ethers.utils.keccak256(originalData2);
        const signData2 = await signer.signMessage(web3Utils.hexToBytes(hash2));
        await assert.revert(
            body.connect(user1).presale(amount, nonce, signData2, {value: v}),
            "nonce is used"
        );
    })

    it('presale should be success: ', async () => {
        const price = await body.price();
        const amount = 6;
        const nonce = 0;
        await body.openPresale();
        await body.setMaxPresale(5);
        await body.setPrePer(amount);


        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user.address, body.address, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        assert.equal(await body.getSigner(), signer.address);
        const v = toBN(price).mul(toBN(amount)).toString()
        await body.connect(user).presale(amount, nonce, signData, {value: v});

        // assert.equal(await body.balanceOf(user.address), amount);
    })

    it('reveal should be revert: ', async () => {
        const tokenID = 0;
        const nonce = 0;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        await body.createBatch(attrIDs, decimals);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, tokenID, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await assert.revert(
            body.connect(user).reveal(tokenID, nonce, attrIDs, attrValues, signData),
            "token is not exist"
        );


        //  mint 5 nft
        const maxAmount = 5;
        const price = await body.price();
        await body.openPublicSale();
        await body.setPubPer(maxAmount);
        await body.setMaxSupply(maxAmount + 1);
        const v = toBN(price).mul(toBN(maxAmount)).toString();
        await body.connect(user).mint(maxAmount, {value: v});
        assert.equal(await body.balanceOf(user.address), maxAmount);

        const attrValues_ = [10, 11, 12, 13, 14, 15, 16, 17, 18];
        await assert.revert(
            body.connect(user).reveal(tokenID, nonce, attrIDs, attrValues_, signData),
            "param length error"
        );


        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));
        await assert.revert(
            body.connect(user).reveal(tokenID, nonce, attrIDs, attrValues, signDataError),
            "sign is not correct"
        );


        await body.connect(user).reveal(tokenID, nonce, attrIDs, attrValues, signData);
        await assert.revert(
            body.connect(user).reveal(tokenID, nonce, attrIDs, attrValues, signData),
            "nonce is used"
        );
    })

    it('reveal should be success: ', async () => {
        const maxAmount = 5;
        const price = await body.price();
        await body.openPublicSale();
        await body.setPubPer(maxAmount);
        await body.setMaxSupply(maxAmount + 1);
        const v = toBN(price).mul(toBN(maxAmount)).toString();
        await body.connect(user).mint(maxAmount, {value: v});
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

        //  TODO tokenRUI
    })
})

describe("GameLootSuit", async function () {
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

describe("GameLootTreasure", async function () {
})