const hre = require('hardhat');
const {toBN, toWei} = require('web3-utils');
const web3Utils = require('web3-utils');
const Web3 = require('web3');
const web3 = new Web3();
const {assert} = require('./common');

describe("GameERC20", async function () {
    let factory, token, treasure;

    let owner, user, signer, user1;

    const upChainSelector = web3.eth.abi.encodeFunctionSignature("upChain(uint256,uint256,bytes)");
    const topUpSelector = web3.eth.abi.encodeFunctionSignature("topUp(uint256,uint256,bytes)");


    beforeEach(async function () {
        [owner, user, signer, user1] = await hre.ethers.getSigners();

        //  factory
        const GameERC20Factory = await hre.ethers.getContractFactory("GameERC20Factory");
        factory = await GameERC20Factory.deploy();
        await factory.deployed();

        //  erc20 token
        const name = "Monster Engineer";
        const symbol = "ME";
        await factory.generate(name, symbol);

        const vaultID = 0;
        const tokenAddress = await factory.vaults(vaultID);

        const GameERC20Token = await hre.ethers.getContractFactory("GameERC20Token");
        token = new hre.ethers.Contract(tokenAddress, GameERC20Token.interface, owner);

        //  treasure
        const GameERC20Treasure = await hre.ethers.getContractFactory("GameERC20Treasure");
        treasure = await GameERC20Treasure.deploy(signer.address, tokenAddress);
        await treasure.deployed();
    });

    it('constructor should be success: ', async () => {
        assert.equal(await treasure.getSigner({from: owner.address}), signer.address);
        assert.equal(await treasure.token(), token.address);

        assert.equal(await token.owner(), owner.address);
    });

    it('mint should be revert: ', async () => {
        await assert.revert(
            token.connect(user).mint(user.address, toWei("1000000000", "ether")),
            "only owner"
        );
    })

    it('mint should be success: ', async () => {
        const amount = toWei("1000000000", "ether");
        await token.connect(owner).mint(user.address, amount);

        assert.equal(await token.balanceOf(user.address), amount);
    })

    it('topUp should be revert: ', async () => {
        const amount = toWei("1000000000", "ether")
        const nonce = 0;
        await token.connect(owner).mint(user.address, amount);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "bytes4"],
            [user.address, token.address, amount, nonce, web3Utils.hexToBytes(topUpSelector)]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));
        const signDataError = await user.signMessage(web3Utils.hexToBytes(hash));

        await assert.revert(
            treasure.connect(user).topUp(amount, nonce, signDataError),
            "sign is not correct"
        );

        await assert.revert(
            treasure.connect(user).topUp(amount, nonce, signData),
            "ERC20: transfer amount exceeds allowance"
        );

        await token.connect(user).approve(treasure.address, toWei('100000000000000000000', 'ether'));
        await treasure.connect(user).topUp(amount, nonce, signData);

        await assert.revert(
            treasure.connect(user).topUp(amount, nonce, signData),
            "nonce already used"
        );
    })

    it('topUp should be success: ', async () => {
        const amount = toWei("1000000000", "ether")
        const nonce = 0;
        await token.connect(owner).mint(user.address, amount);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "bytes4"],
            [user.address, token.address, amount, nonce, web3Utils.hexToBytes(topUpSelector)]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await token.connect(user).approve(treasure.address, toWei('100000000000000000000', 'ether'));
        await treasure.connect(user).topUp(amount, nonce, signData);
    })

    it('upChain should be revert: ', async () => {
        /*
        * topUp
        * */
        const amount = toWei("1000000000", "ether")
        let nonce = 0;
        await token.connect(owner).mint(user.address, amount);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "bytes4"],
            [user.address, token.address, amount, nonce, web3Utils.hexToBytes(topUpSelector)]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await token.connect(user).approve(treasure.address, toWei('100000000000000000000', 'ether'));
        await treasure.connect(user).topUp(amount, nonce, signData);


        /*
        * upChain
        * */
        await assert.revert(
            treasure.connect(user).upChain(amount, nonce, signData),
            "nonce already used"
        );

        nonce = 1;
        //  generate hash
        const originalDataUpChain = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "bytes4"],
            [user.address, token.address, amount, nonce, web3Utils.hexToBytes(upChainSelector)]
        );
        const hashUpChain = hre.ethers.utils.keccak256(originalDataUpChain);
        const signDataUpChainError = await user.signMessage(web3Utils.hexToBytes(hashUpChain));
        await assert.revert(
            treasure.connect(user).upChain(amount, nonce, signDataUpChainError),
            "sign is not correct"
        );
    })

    it('upChain should be success: ', async () => {
        /*
        * topUp
        * */
        const amount = toWei("1000000000", "ether")
        let nonce = 0;
        await token.connect(owner).mint(user.address, amount);

        //  generate hash
        const originalData = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "bytes4"],
            [user.address, token.address, amount, nonce, web3Utils.hexToBytes(topUpSelector)]
        );
        const hash = hre.ethers.utils.keccak256(originalData);
        const signData = await signer.signMessage(web3Utils.hexToBytes(hash));

        await token.connect(user).approve(treasure.address, toWei('100000000000000000000', 'ether'));
        await treasure.connect(user).topUp(amount, nonce, signData);
        assert.equal(await token.balanceOf(treasure.address),amount);

        /*
        * upChain
        * */
        nonce = 1;
        //  generate hash
        const originalDataUpChain = hre.ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256", "bytes4"],
            [user.address, token.address, amount, nonce, web3Utils.hexToBytes(upChainSelector)]
        );
        const hashUpChain = hre.ethers.utils.keccak256(originalDataUpChain);
        const signDataUpChain = await signer.signMessage(web3Utils.hexToBytes(hashUpChain));
        await treasure.connect(user).upChain(amount, nonce, signDataUpChain);
    })
})


