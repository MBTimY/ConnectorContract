const hre = require('hardhat');
const {toBN, toWei} = require('web3-utils');
const web3Utils = require('web3-utils');
const {assert} = require('./common');

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
        gameLootTreasure = await GameLootTreasure.deploy([signer.address]);
        await gameLootTreasure.deployed();

        // We get the contract to deploy
        const GameLootEquipment = await hre.ethers.getContractFactory("GameLootEquipment");
        const cap = 20;

        body = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, vault.address, [signer.address], cap);
        await body.deployed();

        head = await GameLootEquipment.deploy("Monster Engineer Head", "MEHead", gameLootTreasure.address, vault.address, [signer.address], cap);
        await head.deployed();

        hand = await GameLootEquipment.deploy("Monster Engineer Hand", "MEHand", gameLootTreasure.address, vault.address, [signer.address], cap);
        await hand.deployed();

        leg = await GameLootEquipment.deploy("Monster Engineer Leg", "MELeg", gameLootTreasure.address, vault.address, [signer.address], cap);
        await leg.deployed();

        accessory = await GameLootEquipment.deploy("Monster Engineer Accessory", "MEAccessory", gameLootTreasure.address, vault.address, [signer.address], cap);
        await accessory.deployed();

        const GameLootSuit = await hre.ethers.getContractFactory("GameLootSuit");
        gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MESuit", [
            body.address,
            head.address,
            hand.address,
            leg.address,
            accessory.address,
        ], toWei('0.01', 'ether'), vault.address, [signer.address]);
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

    it.skip('constructor should be success: ', async () => {
        assert.equal(await gameLootTreasure.signers(signer.address), true);
        assert.equal(await gameLootTreasure.owner(), owner.address);

        assert.equal(await body.treasure(), gameLootTreasure.address);
        assert.equal(await body.signers(signer.address), true);
        assert.equal(await body.vault(), vault.address);

        assert.equal(await head.treasure(), gameLootTreasure.address);
        assert.equal(await head.signers(signer.address), true);
        assert.equal(await head.vault(), vault.address);

        assert.equal(await hand.treasure(), gameLootTreasure.address);
        assert.equal(await hand.signers(signer.address), true);
        assert.equal(await hand.vault(), vault.address);

        assert.equal(await leg.treasure(), gameLootTreasure.address);
        assert.equal(await leg.signers(signer.address), true);
        assert.equal(await leg.vault(), vault.address);

        assert.equal(await accessory.treasure(), gameLootTreasure.address);
        assert.equal(await accessory.signers(signer.address), signer.address);
        assert.equal(await accessory.vault(), vault.address);

        assert.equal(await gameLootSuit.price(), toWei('0.01', "ether"));
        assert.equal(await gameLootSuit.equipments(0), body.address);
        assert.equal(await gameLootSuit.equipments(1), head.address);
        assert.equal(await gameLootSuit.equipments(2), hand.address);
        assert.equal(await gameLootSuit.equipments(3), leg.address);
        assert.equal(await gameLootSuit.equipments(4), accessory.address);
        assert.equal(await gameLootSuit.signers(signer.address), true);
        assert.equal(await gameLootSuit.vault(), vault.address);
    });

    it('constructor params access should revert: ', async () => {

    });

    it.skip('constructor params access should be success: ', async () => {
        //  treasure
        await gameLootTreasure.connect(owner).addSigner(user.address);
        assert.equal(await gameLootTreasure.signers(1), user.address);

        //  equipment
        await body.connect(owner).setSuit(gameLootSuit.address)
        assert.equal(await body.suit(), gameLootSuit.address);
        assert.equal(await body.connect(owner).signer(), signer.address);

        // suit
        assert.equal(await gameLootSuit.connect(owner).signer(), signer.address);
    })

    it('gameMint should revert: ', async () => {
        await body.setMaxSupply(100);
        const nonce = 1;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
        const attrValuesError = [10, 11, 12, 13, 14, 15, 16, 17, 18];

        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        //  user signed not signer signed
        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));
        const signDataRight = await signer.signMessage(web3Utils.hexToBytes(hash));

        await assert.revert(
            body.connect(user).gameMint(nonce, attrIDs, attrValues, signDataError),
            "sign is not correct"
        );

        //  test nonce
        await body.connect(user).gameMint(nonce, attrIDs, attrValues, signDataRight);
        await assert.revert(
            body.connect(user).gameMint(nonce, attrIDs, attrValues, signDataRight),
            "nonce is used"
        );

        //  param length
        const nonce_ = 0;
        const originalDataError = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, nonce_, attrIDs, attrValuesError]
        );
        const hashError = hre.ethers.utils.keccak256(originalDataError);
        const signDataError_ = await signer.signMessage(web3Utils.hexToBytes(hashError));
        await assert.revert(
            body.connect(user).gameMint(nonce_, attrIDs, attrValuesError, signDataError_),
            "param length error"
        );
    })

    it('gameMint should be success: ', async () => {
        await body.setMaxSupply(100);
        const nonce = 0;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        // assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);
        await body.connect(user).gameMint(nonce, attrIDs, attrValues, signData);
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
            "sold out"
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
        await body.setMaxSupply(amount + 1);
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
        const amount = 5;
        const nonce = 0;
        await body.openPresale();
        await body.setMaxPresale(5);
        await body.setMaxSupply(amount);
        await body.setPrePer(amount);


        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user.address, body.address, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        // assert.equal(await body.getSigner(), signer.address);
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

        // assert.equal(await body.getSigner(), signer.address);
        await body.connect(user).reveal(tokenID, nonce, attrIDs, attrValues, signData);
    })

    it('withdraw should be revert: ', async () => {
        await assert.revert(
            body.connect(user).withdraw(),
            "Ownable: caller is not the owner"
        );
    })

    it('withdraw should be success: ', async () => {
        const price = await body.price();
        const maxAmount = 5;
        await body.openPublicSale();
        await body.setPubPer(maxAmount);
        await body.setMaxSupply(maxAmount + 1);

        const v = toBN(price).mul(toBN(maxAmount)).toString();
        await body.connect(user).mint(maxAmount, {value: v});

        await body.connect(owner).withdraw();
    })

    it('tokenURI should be success: ', async () => {
        await body.setMaxSupply(100);
        const nonce = 0;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        // assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);
        await body.connect(user).gameMint(nonce, attrIDs, attrValues, signData);

        const output = await body.tokenURI(0);
        const strArr = output.split('data:application/json;base64,')
        const json = Buffer.from(strArr[1], "base64").toString('ascii')
        const imgBase64 = JSON.parse(json).image.split("data:image/svg+xml;base64,")[1]

        const img = Buffer.from(imgBase64, "base64").toString('ascii')
        // console.log(img);
    })
})

describe("GameLootSuit", async function () {
    let gameLootTreasure;
    let body, head, hand, leg, accessory;
    let gameLootSuit;

    let owner, user, signer, vault, user1;

    beforeEach(async function () {
        [owner, user, signer, vault, user1] = await hre.ethers.getSigners();

        const GameLootTreasure = await hre.ethers.getContractFactory("GameLootTreasure");
        gameLootTreasure = await GameLootTreasure.deploy([signer.address]);
        await gameLootTreasure.deployed();

        // We get the contract to deploy
        const GameLootEquipment = await hre.ethers.getContractFactory("GameLootEquipment");
        const cap = 20;

        body = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, vault.address, [signer.address], cap);
        await body.deployed();

        head = await GameLootEquipment.deploy("Monster Engineer Head", "MEHead", gameLootTreasure.address, vault.address, [signer.address], cap);
        await head.deployed();

        hand = await GameLootEquipment.deploy("Monster Engineer Hand", "MEHand", gameLootTreasure.address, vault.address, [signer.address], cap);
        await hand.deployed();

        leg = await GameLootEquipment.deploy("Monster Engineer Leg", "MELeg", gameLootTreasure.address, vault.address, [signer.address], cap);
        await leg.deployed();

        accessory = await GameLootEquipment.deploy("Monster Engineer Accessory", "MEAccessory", gameLootTreasure.address, vault.address, [signer.address], cap);
        await accessory.deployed();

        const GameLootSuit = await hre.ethers.getContractFactory("GameLootSuit");
        gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MESuit", [
            body.address,
            head.address,
            hand.address,
            leg.address,
            accessory.address,
        ], toWei('0.01', 'ether'), vault.address, [signer.address]);
        await gameLootSuit.deployed();

        //  set suit address
        await body.setSuit(gameLootSuit.address);
        await head.setSuit(gameLootSuit.address);
        await hand.setSuit(gameLootSuit.address);
        await leg.setSuit(gameLootSuit.address);
        await accessory.setSuit(gameLootSuit.address);

        //  set config param
        await body.setPrice(toWei('0.01', "ether"));
        await head.setPrice(toWei('0.01', "ether"));
        await hand.setPrice(toWei('0.01', "ether"));
        await leg.setPrice(toWei('0.01', "ether"));
        await accessory.setPrice(toWei('0.01', "ether"));
        await gameLootSuit.setPrice(toWei('0.01', "ether"));
    });

    it('mint should be revert: ', async () => {
        await assert.revert(
            gameLootSuit.connect(user).mint(),
            "public mint is not start"
        );

        await gameLootSuit.openPublicSale();
        await assert.revert(
            gameLootSuit.connect(user).mint(),
            "tx value is not correct"
        );

        const price = await gameLootSuit.price();
        const v = toBN(price).toString();
        await gameLootSuit.connect(user).mint({value: v});
        await assert.revert(
            gameLootSuit.connect(user).mint({value: v}),
            "has minted"
        );
    })

    it('mint should be success: ', async () => {
        const price = await gameLootSuit.price();
        const v = toBN(price).toString();
        await gameLootSuit.openPublicSale();
        await gameLootSuit.connect(user).mint({value: v});

        assert.equal(await gameLootSuit.balanceOf(user.address), 1);
    })

    it('tokenURI should be success: ', async () => {
        const unRevealedBaseURI = "ipfs://QmXLHJ1Am75PLRUETcCnVPPPar29eUEyKDBYcQ8RaCMVXb";
        const baseURI = "ipfs://QmccmDqqeBcuYpmvQKmfkV9hx3emXTyAd4MH6vv1Ebiija/";
        await gameLootSuit.setUnRevealedBaseURI(unRevealedBaseURI);

        //  mint
        const price = await gameLootSuit.price();
        const v = toBN(price).toString();
        await gameLootSuit.openPublicSale();
        await gameLootSuit.connect(user).mint({value: v});

        assert.equal(await gameLootSuit.tokenURI(0), unRevealedBaseURI);

        await gameLootSuit.setBaseTokenURI(baseURI)
        assert.equal(await gameLootSuit.tokenURI(0), baseURI + '0');
    })

    it('presale should be revert: ', async () => {
        const nonce = 0;
        const price = await gameLootSuit.price();
        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user.address, gameLootSuit.address, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));
        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));

        await assert.revert(
            gameLootSuit.connect(user).presale(nonce, signData),
            "presale is not start"
        );

        await gameLootSuit.openPresale();
        await assert.revert(
            gameLootSuit.connect(user).presale(nonce, signData),
            "tx value is not correct"
        );

        await gameLootSuit.setMaxPresale(0);
        await assert.revert(
            gameLootSuit.connect(user).presale(nonce, signData, {value: toBN(price).toString()}),
            "presale out"
        );

        await gameLootSuit.setMaxPresale(2);
        await assert.revert(
            gameLootSuit.connect(user).presale(nonce, signDataError, {value: toBN(price).toString()}),
            "sign is not correct"
        );

        await gameLootSuit.connect(user).presale(nonce, signData, {value: toBN(price).toString()});
        await assert.revert(
            gameLootSuit.connect(user).presale(nonce, signDataError, {value: toBN(price).toString()}),
            "nonce is used"
        );
    })

    it('presale should be success: ', async () => {
        const nonce = 0;
        const price = await gameLootSuit.price();
        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [user.address, gameLootSuit.address, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await gameLootSuit.openPresale();
        await gameLootSuit.setMaxPresale(2);

        await gameLootSuit.connect(user).presale(nonce, signData, {value: toBN(price).toString()});
    })

    it('divide should be revert: ', async () => {
        //  mint
        const price = await gameLootSuit.price();
        const v = toBN(price).toString();
        await gameLootSuit.openPublicSale();
        await gameLootSuit.connect(user).mint({value: v});
        await gameLootSuit.connect(user1).mint({value: v});

        await body.setMaxSupply(2);
        await head.setMaxSupply(2);
        await hand.setMaxSupply(2);
        await leg.setMaxSupply(2);
        await accessory.setMaxSupply(2);


        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const tokenID = 0;
        const equipIDs = [0, 1, 2, 3, 4];
        const attrIDs_ = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const attrIDs = [attrIDs_, attrIDs_, attrIDs_, attrIDs_, attrIDs_];
        const values_ = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
        const values = [values_, values_, values_, values_, values_]
        const nonce = 0;

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["uint256", "address", "uint256[]", "uint256[][]", "uint256[][]", "uint256"],
            [tokenID, gameLootSuit.address, equipIDs, attrIDs, values, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await body.createBatch(attrIDs_, decimals);
        await head.createBatch(attrIDs_, decimals);
        await hand.createBatch(attrIDs_, decimals);
        await leg.createBatch(attrIDs_, decimals);
        await accessory.createBatch(attrIDs_, decimals);

        await assert.revert(
            gameLootSuit.connect(owner).divide(tokenID, equipIDs, attrIDs, values, nonce, signData),
            "owner missed"
        );

        const equipIDsError = [0, 0, 0, 0, 0, 0];
        await assert.revert(
            gameLootSuit.connect(user).divide(tokenID, equipIDsError, attrIDs, values, nonce, signData),
            "params length error"
        );

        const attrIDsError = [attrIDs_, attrIDs_, attrIDs_, attrIDs_, attrIDs_, attrIDs_];
        const valuesError = [values_, values_, values_, values_, values_, values_]
        await assert.revert(
            gameLootSuit.connect(user).divide(tokenID, equipIDs, attrIDsError, valuesError, nonce, signData),
            "params length error"
        );

        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));
        await assert.revert(
            gameLootSuit.connect(user).divide(tokenID, equipIDs, attrIDs, values, nonce, signDataError),
            "sign is not correct"
        );

        await gameLootSuit.connect(user).divide(tokenID, equipIDs, attrIDs, values, nonce, signData);
        await assert.revert(
            gameLootSuit.connect(user1).divide(1, equipIDs, attrIDs, values, nonce, signData),
            "nonce is used"
        );
    })

    it('divide should be success: ', async () => {
        const price = await gameLootSuit.price();
        const v = toBN(price).toString();
        await gameLootSuit.openPublicSale();
        await gameLootSuit.connect(user).mint({value: v});
        await gameLootSuit.connect(user1).mint({value: v});

        await body.setMaxSupply(2);
        await head.setMaxSupply(2);
        await hand.setMaxSupply(2);
        await leg.setMaxSupply(2);
        await accessory.setMaxSupply(2);


        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const tokenID = 0;
        const equipIDs = [0, 1, 2, 3, 4];
        const attrIDs_ = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const attrIDs = [attrIDs_, attrIDs_, attrIDs_, attrIDs_, attrIDs_];
        const values_ = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
        const values = [values_, values_, values_, values_, values_]
        const nonce = 0;

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["uint256", "address", "uint256[]", "uint256[][]", "uint256[][]", "uint256"],
            [tokenID, gameLootSuit.address, equipIDs, attrIDs, values, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await body.createBatch(attrIDs_, decimals);
        await head.createBatch(attrIDs_, decimals);
        await hand.createBatch(attrIDs_, decimals);
        await leg.createBatch(attrIDs_, decimals);
        await accessory.createBatch(attrIDs_, decimals);

        await gameLootSuit.connect(user).divide(tokenID, equipIDs, attrIDs, values, nonce, signData);
    })

    it('withdraw should be revert: ', async () => {
        const price = await gameLootSuit.price();
        const v = toBN(price).toString();
        await gameLootSuit.openPublicSale();
        await gameLootSuit.connect(user).mint({value: v});

        await assert.revert(
            gameLootSuit.connect(user).withdraw(),
            "Ownable: caller is not the owner"
        );
    })

    it('withdraw should be success: ', async () => {
        const price = await gameLootSuit.price();
        const v = toBN(price).toString();
        await gameLootSuit.openPublicSale();
        await gameLootSuit.connect(user).mint({value: v});

        await gameLootSuit.connect(owner).withdraw();
    })
})

describe("GameLootTreasure", async function () {
    let gameLootTreasure;
    let body, leg;
    let gameLootSuit;

    let owner, user, signer, vault, user1;

    beforeEach(async function () {
        [owner, user, signer, vault, user1] = await hre.ethers.getSigners();

        const GameLootTreasure = await hre.ethers.getContractFactory("GameLootTreasure");
        gameLootTreasure = await GameLootTreasure.deploy([signer.address]);
        await gameLootTreasure.deployed();

        // We get the contract to deploy
        const GameLootEquipment = await hre.ethers.getContractFactory("GameLootEquipment");
        const cap = 20;

        body = await GameLootEquipment.deploy("Monster Engineer Body", "MEBody", gameLootTreasure.address, vault.address, [signer.address], cap);
        await body.deployed();

        leg = await GameLootEquipment.deploy("Monster Engineer Leg", "MELeg", gameLootTreasure.address, vault.address, [signer.address], cap);
        await leg.deployed();

        const GameLootSuit = await hre.ethers.getContractFactory("GameLootSuit");
        gameLootSuit = await GameLootSuit.deploy("Monster Engineer Suit", "MESuit", [
            body.address,
        ], toWei('0.01', 'ether'), vault.address, [signer.address]);
        await gameLootSuit.deployed();

        //  set suit address
        await body.setSuit(gameLootSuit.address);
        await leg.setSuit(gameLootSuit.address);

        //  set config param
        await body.setPrice(toWei('0.01', "ether"));
        await leg.setPrice(toWei('0.01', "ether"));

        /*
        * mint
        * */
        const price = await body.price();
        const maxAmount = 5;
        await body.openPublicSale();
        await body.setPubPer(maxAmount);
        await body.setMaxSupply(maxAmount + 1);

        const v = toBN(price).mul(toBN(maxAmount)).toString();
        await body.connect(user).mint(maxAmount, {value: v});
    });

    it('topUp should be revert: ', async () => {
        const tokenID = 0;
        const nonce = 0;

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address", "uint256", "uint256"],
            [user.address, gameLootTreasure.address, body.address, tokenID, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await gameLootTreasure.pause();

        await assert.revert(
            gameLootTreasure.connect(user).topUp(body.address, tokenID, nonce, signData),
            "Pausable: paused"
        );

        await gameLootTreasure.unPause();

        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));
        await assert.revert(
            gameLootTreasure.connect(user).topUp(body.address, tokenID, nonce, signDataError),
            "sign is not correct"
        );

        await assert.revert(
            gameLootTreasure.connect(user).topUp(body.address, tokenID, nonce, signData),
            "ERC721: transfer caller is not owner nor approved"
        );

        await body.connect(user).setApprovalForAll(gameLootTreasure.address, true);
        await gameLootTreasure.connect(user).topUp(body.address, tokenID, nonce, signData);
        await assert.revert(
            gameLootTreasure.connect(user).topUp(body.address, tokenID, nonce, signData),
            "nonce already used"
        );
    })

    it('topUp should be success: ', async () => {
        const tokenID = 0;
        const nonce = 0;

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address", "uint256", "uint256"],
            [user.address, gameLootTreasure.address, body.address, tokenID, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await body.connect(user).setApprovalForAll(gameLootTreasure.address, true);
        await gameLootTreasure.connect(user).topUp(body.address, tokenID, nonce, signData);
    })

    it('topUpBatch should be revert: ', async () => {
        const nonce = 0;
        const tokenIDs = [0, 1, 2, 3, 4]
        const addresses = [body.address, body.address, body.address, body.address, body.address]
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address[]", "uint256[]", "uint256"],
            [user.address, gameLootTreasure.address, addresses, tokenIDs, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await user.signMessage(web3Utils.hexToBytes(hash));

        await assert.revert(
            gameLootTreasure.connect(user).topUpBatch(addresses, tokenIDs, nonce, signData),
            "sign is not correct"
        );
    })

    it('topUpBatch should be success: ', async () => {
        const nonce = 0;
        const tokenIDs = [0, 1, 2, 3, 4]
        const addresses = [body.address, body.address, body.address, body.address, body.address]
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address[]", "uint256[]", "uint256"],
            [user.address, gameLootTreasure.address, addresses, tokenIDs, nonce]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await body.connect(user).setApprovalForAll(gameLootTreasure.address, true);
        await gameLootTreasure.connect(user).topUpBatch(addresses, tokenIDs, nonce, signData);
    })

    it('upChain should be success: ', async () => {
        /*
        * body gameMint
        * */
        await body.setMaxSupply(100);
        const nonce = 0;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        // assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);
        await body.connect(user).gameMint(nonce, attrIDs, attrValues, signData);

        /*
        * body topUp
        * */
        const _nonce = 0;
        const tokenID = 5;

        //  generate hash
        const _originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address", "uint256", "uint256"],
            [user.address, gameLootTreasure.address, body.address, tokenID, _nonce]
        );
        const _hash = hre.ethers.utils.keccak256(_originalData);
        const _signData = await signer.signMessage(web3Utils.hexToBytes(_hash));

        await body.connect(user).setApprovalForAll(gameLootTreasure.address, true);
        await gameLootTreasure.connect(user).topUp(body.address, tokenID, _nonce, _signData);

        /*
        * upChain
        * */
        const nonce_ = 1;
        const attrIDs_ = [10, 11, 12];
        const attrValues_ = [20, 20, 20];
        const attrIndexesUpdate_ = [3, 4, 5];
        const attrValuesUpdate_ = [20, 20, 20];
        const attrIndexesRM_ = [9];

        //  generate hash
        const originalData_ = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address", "uint256", "uint256", "uint256[]", "uint256[]", "uint256[]", "uint256[]", "uint256[]"],
            [user.address, gameLootTreasure.address, body.address, tokenID, nonce_, attrIDs_, attrValues_, attrIndexesUpdate_, attrValuesUpdate_, attrIndexesRM_]
        );
        const hash_ = hre.ethers.utils.keccak256(originalData_);
        const signData_ = await signer.signMessage(web3Utils.hexToBytes(hash_));

        await body.createBatch(attrIDs_, [0, 0, 0]);

        await gameLootTreasure.connect(user).upChain(body.address, tokenID, nonce_, attrIDs_, attrValues_, attrIndexesUpdate_, attrValuesUpdate_, attrIndexesRM_, signData_);

        const attrData = await body.attributes(tokenID);

        assert.equal(attrData.length, 12);
    })

    it('upChainBatch should be success: ', async () => {
        /*
       * body gameMint
       * */
        await body.setMaxSupply(100);
        const nonce = 0;
        const attrIDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const decimals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValues = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256[]", "uint256[]"],
            [user.address, body.address, nonce, attrIDs, attrValues]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        // assert.equal(await body.getSigner(), signer.address);
        await body.createBatch(attrIDs, decimals);
        await body.connect(user).gameMint(nonce, attrIDs, attrValues, signData);


        /*
        * topUp
        * */
        const _nonce = 0;
        const tokenID = 5;

        //  generate hash
        const _originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address", "uint256", "uint256"],
            [user.address, gameLootTreasure.address, body.address, tokenID, _nonce]
        );
        const _hash = hre.ethers.utils.keccak256(_originalData);
        const _signData = await signer.signMessage(web3Utils.hexToBytes(_hash));

        await body.connect(user).setApprovalForAll(gameLootTreasure.address, true);
        await gameLootTreasure.connect(user).topUp(body.address, tokenID, _nonce, _signData);


        /*
        * leg gameMint
        * */
        await leg.setMaxSupply(100);
        const tokenIDleg = 0;
        const nonceleg = 0;
        const attrIDsleg = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        const decimalsleg = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        const attrValuesleg = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

        //  generate hash
        const originalDataleg = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256[]", "uint256[]"],
            [user.address, leg.address, nonceleg, attrIDsleg, attrValuesleg]
        );
        const hashleg = hre.ethers.utils.keccak256(originalDataleg);
        const signDataleg = await signer.signMessage(web3Utils.hexToBytes(hashleg));

        // assert.equal(await leg.getSigner(), signer.address);
        await leg.createBatch(attrIDsleg, decimalsleg);
        await leg.connect(user).gameMint(nonceleg, attrIDsleg, attrValuesleg, signDataleg);

        /*
        * leg topUp
        * */
        const _nonceleg = 1;

        //  generate hash
        const _originalDataleg = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address", "uint256", "uint256"],
            [user.address, gameLootTreasure.address, leg.address, tokenIDleg, _nonceleg]
        );
        const _hashleg = hre.ethers.utils.keccak256(_originalDataleg);
        const _signDataleg = await signer.signMessage(web3Utils.hexToBytes(_hashleg));

        await leg.connect(user).setApprovalForAll(gameLootTreasure.address, true);
        await gameLootTreasure.connect(user).topUp(leg.address, tokenIDleg, _nonceleg, _signDataleg);

        /*
        * upChainBatch
        * */
        const nonce_ = 2;
        const attrIDs_ = [10, 11, 12];
        const attrValues_ = [20, 20, 20];
        const attrIDsUpdate_ = [3, 4, 5];
        const attrValuesUpdate_ = [20, 20, 20];
        const attrIndexesRM_ = [9];

        //  generate hash
        const originalData_ = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "address[]", "uint256[]", "uint256", "uint128[][]", "uint128[][]", "uint256[][]", "uint128[][]", "uint256[][]"],
            [user.address, gameLootTreasure.address, [body.address, leg.address], [tokenID, tokenIDleg], nonce_, [attrIDs_, attrIDs_], [attrValues_, attrValues_], [attrIDsUpdate_, attrIDsUpdate_], [attrValuesUpdate_, attrValuesUpdate_], [attrIndexesRM_, attrIndexesRM_]]
        );
        const hash_ = hre.ethers.utils.keccak256(originalData_);
        const signData_ = await signer.signMessage(web3Utils.hexToBytes(hash_));

        await body.createBatch(attrIDs_, [0, 0, 0]);
        await leg.createBatch(attrIDs_, [0, 0, 0]);

        await gameLootTreasure.connect(user).upChainBatch([body.address, leg.address], [tokenID, tokenIDleg], nonce_, [attrIDs_, attrIDs_], [attrValues_, attrValues_], [attrIDsUpdate_, attrIDsUpdate_], [attrValuesUpdate_, attrValuesUpdate_], [attrIndexesRM_, attrIndexesRM_], signData_);

        const attrData = await body.attributes(tokenID);

        assert.equal(attrData.length, 12);
    })
})