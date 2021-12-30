// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./GameLoot.sol";
import "hardhat/console.sol";

contract GameLootEquipment is GameLoot, Ownable {
    address public signer;
    address public treasure;
    address public suit;
    address public vault;
    mapping(uint256 => bool) public usedNonce;

    uint256 public totalSupply;
    uint128 public maxPresale;
    uint128 public maxSupply;
    uint128 public presaleAmount;
    uint128 public price;
    uint128 public pubPer;
    uint128 public prePer;
    bool public publicStart;
    bool public presaleStart;
    mapping(address => bool) public hasMinted;
    mapping(address => bool) public hasPresale;

    event GameMint(address user, uint256 tokenID, uint256 nonce);

    constructor(
        string memory name_,
        string memory symbol_,
        address treasure_,
        address vault_,
        address signer_,
        uint256 cap_
    ) GameLoot(name_, symbol_, cap_) {
        require(treasure_ != address(0), "treasure can not be zero");
        treasure = treasure_;
        vault = vault_;
        signer = signer_;
    }

    receive() external payable {}

    /// @notice public mint
    /// @dev
    function mint(uint128 amount_) public payable {
        require(publicStart, "public mint is not start");
        require(tx.origin == msg.sender, "forbidden tx");
        require(!hasMinted[msg.sender], "has minted");
        require(amount_ <= pubPer, "exceed max per");
        require(msg.value >= price * amount_, "tx value is not correct");

        hasMinted[msg.sender] = true;

        for (uint256 i; i < amount_; i++) {
            _safeMint(msg.sender, totalSupply);
        }
    }

    /// @notice presale
    /// @dev Need to sign
    function presale(
        uint128 amount_,
        uint256 nonce_,
        bytes memory signature_
    ) public payable {
        require(presaleStart, "presale is not start");
        require(!hasPresale[msg.sender], "has minted");
        require(amount_ <= prePer, "exceed max per");
        require(msg.value >= price * amount_, "tx value is not correct");
        require(presaleAmount < maxPresale, "presale out");
        require(!usedNonce[nonce_], "nonce is used");
        require(verify(msg.sender, address(this), nonce_, signature_), "sign is not correct");
        if (presaleAmount + amount_ > maxPresale)
            amount_ = uint128(maxPresale - presaleAmount);

        usedNonce[nonce_] = true;
        presaleAmount += uint128(amount_);

        hasPresale[msg.sender] = true;

        for (uint256 i; i < amount_; i++) {
            _safeMint(msg.sender, totalSupply);
        }
    }

    /// @notice reveal mystery box
    /// @dev
    function reveal(
        uint256 tokenID_,
        uint256 nonce_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) public {
        require(_exists(tokenID_), "token is not exist");
        require(!usedNonce[nonce_], "nonce is used");
        require(attrIDs_.length == attrValues_.length, "param length error");
        require(verify(msg.sender, address(this), tokenID_, nonce_, attrIDs_, attrValues_, signature_), "sign is not correct");
        usedNonce[nonce_] = true;

        _attachBatch(tokenID_, attrIDs_, attrValues_);
    }

    /// @notice Mint from game
    /// @dev Need to sign
    function gameMint(
        uint256 nonce_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) public {
        require(!usedNonce[nonce_], "nonce is used");
        require(verify(msg.sender, address(this), nonce_, attrIDs_, attrValues_, signature_), "sign is not correct");
        require(attrIDs_.length == attrValues_.length, "param length error");
        usedNonce[nonce_] = true;

        _attachBatch(totalSupply, attrIDs_, attrValues_);

        _safeMint(msg.sender, totalSupply);
        emit GameMint(msg.sender, totalSupply, nonce_);
    }

    /// @notice Mint from suit contract
    /// @dev Need to sign
    function suitMint(
        address _addr,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_
    ) public {
        require(msg.sender == suit, "suit only");
        require(attrIDs_.length == attrValues_.length, "param length error");

        _attachBatch(totalSupply, attrIDs_, attrValues_);

        _safeMint(_addr, totalSupply);
    }

    function verify(
        address wallet_,
        address contract_,
        uint256 nonce_,
        bytes memory signature_
    ) internal view returns (bool){
        return signatureWallet(wallet_, contract_, nonce_, signature_) == signer;
    }

    function signatureWallet(
        address wallet_,
        address contract_,
        uint256 nonce_,
        bytes memory signature_
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(wallet_, contract_, nonce_)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature_);
    }

    function verify(
        address wallet_,
        address contract_,
        uint256 nonce_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) internal view returns (bool){
        return signatureWallet(wallet_, contract_, nonce_, attrIDs_, attrValues_, signature_) == signer;
    }

    function signatureWallet(
        address wallet_,
        address contract_,
        uint256 nonce_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(wallet_, contract_, nonce_, attrIDs_, attrValues_)
        );

        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature_);
    }

    function verify(
        address wallet_,
        address contract_,
        uint256 tokenID_,
        uint256 nonce_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) internal view returns (bool){
        return signatureWallet(wallet_, contract_, tokenID_, nonce_, attrIDs_, attrValues_, signature_) == signer;
    }

    function signatureWallet(
        address wallet_,
        address contract_,
        uint256 tokenID_,
        uint256 nonce_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(wallet_, contract_, tokenID_, nonce_, attrIDs_, attrValues_)
        );

        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature_);
    }

    function exists(uint256 tokenId) public view {
        _exists(tokenId);
    }

    function openPresale() public onlyOwner {
        presaleStart = true;
    }

    function closePresale() public onlyOwner {
        presaleStart = false;
    }

    function openPublicSale() public onlyOwner {
        publicStart = true;
    }

    function closePublicSale() public onlyOwner {
        publicStart = false;
    }

    function setPrice(uint128 price_) public onlyOwner {
        price = price_;
    }

    function setMaxPresale(uint128 maxPresale_) public onlyOwner {
        maxPresale = maxPresale_;
    }

    function setMaxSupply(uint128 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setPubPer(uint128 pubPer_) public onlyOwner {
        pubPer = pubPer_;
    }

    function setPrePer(uint128 prePer_) public onlyOwner {
        prePer = prePer_;
    }

    function setCap(uint256 cap) public onlyOwner {
        _cap = cap;
    }

    function create(uint128 attrID_, uint8 decimals_) override public onlyOwner {
        super.create(attrID_, decimals_);
    }

    function createBatch(uint128[] memory attrIDs_, uint8[] memory decimals_) override public onlyOwner {
        super.createBatch(attrIDs_, decimals_);
    }

    function attach(uint256 tokenID_, uint128 attrID_, uint128 _value) override public onlyTreasure {
        _attach(tokenID_, attrID_, _value);
    }

    function attachBatch(uint256 tokenID_, uint128[] memory attrIDs_, uint128[] memory _values) override public onlyTreasure {
        _attachBatch(tokenID_, attrIDs_, _values);
    }

    function remove(uint256 tokenID_, uint256 attrIndex_) override public onlyTreasure {
        _remove(tokenID_, attrIndex_);
    }

    function removeBatch(uint256 tokenID_, uint256[] memory attrIndexes_) override public onlyTreasure {
        _removeBatch(tokenID_, attrIndexes_);
    }

    function update(uint256 tokenID_, uint256 attrIndex_, uint128 value_) override public onlyTreasure {
        _update(tokenID_, attrIndex_, value_);
    }

    function updateBatch(uint256 tokenID_, uint256[] memory attrIndexes_, uint128[] memory values_) override public onlyTreasure {
        _updateBatch(tokenID_, attrIndexes_, values_);
    }

    function setSuit(address suit_) public onlyOwner {
        suit = suit_;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance != 0);
        payable(vault).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) {
            totalSupply ++;
            require(totalSupply <= maxSupply, "sold out");
        }
    }

    modifier onlyTreasure(){
        require(msg.sender == treasure, "is not treasure");
        _;
    }
}