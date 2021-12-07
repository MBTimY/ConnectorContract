pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./GameERC721.sol";

contract GameERC721Equipment is GameERC721, Ownable {
    address private signer;
    address public treasure;
    address public suit;
    address public vault;
    mapping(uint256 => bool) private usedNonce;

    uint256 public totalSupply;
    uint128 public maxPresale;
    uint128 public maxSupply;
    uint128 public presaleAmount;
    uint128 public price;
    uint256 public pubPer;
    bool public publicStart;
    bool public presaleStart;
    mapping(address => bool) hasMinted;
    mapping(address => bool) hasPresale;

    constructor(
        string memory _name,
        string memory _symbol,
        address _treasure,
        address _vault,
        address _signer
    ) GameERC721(_name, _symbol) {
        require(_treasure != address(0), "treasure can not be zero");
        treasure = _treasure;
        vault = _vault;
        signer = _signer;
    }

    /// @notice public mint
    /// @dev
    function mint(uint256 _amount) public payable {
        require(publicStart, "public mint is not start");
        require(tx.origin == msg.sender, "forbidden tx");
        require(!hasMinted[msg.sender], "has minted");
        require(_amount <= pubPer, "exceed max per");
        require(msg.value >= price * _amount, "tx value is not correct");

        hasMinted[msg.sender] = true;

        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, totalSupply);
        }
    }

    /// @notice presale
    /// @dev Need to sign
    function presale(
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public payable {
        require(presaleStart, "presale is not start");
        require(!hasPresale[msg.sender], "has minted");
        require(msg.value >= price * _amount, "tx value is not correct");
        require(presaleAmount + _amount <= maxPresale, "presale out");
        require(verifyPresale(msg.sender, address(this), _nonce, _signature), "sign is not correct");
        presaleAmount += uint128(_amount);

        hasPresale[msg.sender] = true;

        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, totalSupply);
        }
    }

    /// @notice reveal mystery box
    /// @dev
    function reveal(
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        bytes memory _signature
    ) public {
        require(_exists(_tokenID), "token is not exist");
        require(!usedNonce[_nonce], "nonce is used");
        require(verify(msg.sender, address(this), _tokenID, _nonce, _attrIDs, _attrValues, _signature), "sign is not correct");
        require(_attrIDs.length == _attrValues.length, "param length error");
        usedNonce[_nonce] = true;

        _attachBatch(_tokenID, _attrIDs, _attrValues);
    }

    /// @notice Mint from game
    /// @dev Need to sign
    function gameMint(
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        bytes memory _signature
    ) public {
        require(!usedNonce[_nonce], "nonce is used");
        require(verify(msg.sender, address(this), _tokenID, _nonce, _attrIDs, _attrValues, _signature), "sign is not correct");
        require(_attrIDs.length == _attrValues.length, "param length error");
        usedNonce[_nonce] = true;

        _attachBatch(_tokenID, _attrIDs, _attrValues);

        _safeMint(msg.sender, _tokenID);
    }

    /// @notice Mint from suit contract
    /// @dev Need to sign
    function suitMint(
        address _addr,
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        bytes memory _signature
    ) public {
        require(msg.sender == suit, "suit only");
        require(!usedNonce[_nonce], "nonce is used");
        require(verify(_addr, address(this), _tokenID, _nonce, _attrIDs, _attrValues, _signature), "sign is not correct");
        require(_attrIDs.length == _attrValues.length, "param length error");
        usedNonce[_nonce] = true;

        _attachBatch(_tokenID, _attrIDs, _attrValues);

        _safeMint(_addr, _tokenID);
    }

    function verifyPresale(
        address _wallet,
        address _contract,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWalletPresale(_wallet, _contract, _nonce, _signature) == signer;
    }

    function signatureWalletPresale(
        address _wallet,
        address _contract,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _contract, _nonce)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address _contract,
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWallet(_wallet, _contract, _tokenID, _nonce, _attrIDs, _attrValues, _signature) == signer;
    }

    function signatureWallet(
        address _wallet,
        address _contract,
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        bytes memory _signature
    ) internal view returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _contract, _tokenID, _nonce, _attrIDs, _attrValues)
        );

        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
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

    function setPrice(uint128 _price) public onlyOwner {
        price = _price;
    }

    function setMaxPresale(uint64 _maxPresale) public onlyOwner {
        maxPresale = _maxPresale;
    }

    function setMaxSupply(uint64 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPubPer(uint64 _pubPer) public onlyOwner {
        pubPer = _pubPer;
    }

    function getSigner() public view onlyOwner returns (address){
        return signer;
    }

    function create(uint256 _id, uint8 _decimals) override public onlyOwner {
        super.create(_id, _decimals);
    }

    function createBatch(uint256[] memory _ids, uint8[] memory _decimals) override public onlyOwner {
        super.createBatch(_ids, _decimals);
    }

    function attach(uint256 _tokenID, uint256 _attrID, uint256 _value) override public onlyTreasure {
        super.attach(_tokenID, _attrID, _value);
    }

    function attachBatch(uint256 _tokenID, uint256[] memory _attrIDs, uint256[] memory _values) override public onlyTreasure {
        super.attachBatch(_tokenID, _attrIDs, _values);
    }

    function remove(uint256 _tokenID, uint256 _attrID) override public onlyTreasure {
        super.remove(_tokenID, _attrID);
    }

    function removeBatch(uint256 _tokenID, uint256[] memory _attrIDs) override public onlyTreasure {
        super.removeBatch(_tokenID, _attrIDs);
    }

    function setSuit(address _suit) public onlyOwner {
        suit = _suit;
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
        }
    }

    modifier onlyTreasure(){
        require(msg.sender == treasure, "is not treasure");
        _;
    }
}