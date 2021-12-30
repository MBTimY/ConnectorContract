// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IEquipment {
    function suitMint(
        address _addr,
        uint128[] memory _attrIDs,
        uint128[] memory _attrValues
    ) external;
}

contract GameLootSuit is ERC721, Ownable {
    using Strings for uint256;

    uint64 constant public maxSupply = 2200;
    uint64 public maxPresale;
    uint64 public presaleAmount;
    uint64 public totalSupply;
    address public vault;

    string private baseURI;
    string private unRevealedBaseURI;

    uint256 public price;
    bool public publicStart;
    bool public presaleStart;

    address[] public equipments;

    mapping(address => bool) hasMinted;
    mapping(address => bool) hasPresale;

    address private signer;
    mapping(uint256 => bool) public usedNonce;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _equipment,
        uint256 _price,
        address _vault,
        address _signer
    ) ERC721(_name, _symbol){
        equipments = _equipment;
        price = _price;
        vault = _vault;
        signer = _signer;
    }

    receive() external payable {}

    /// @notice public mint
    /// @dev Each address can only mint once, only one can be minted at a time
    function mint() public payable {
        require(publicStart, "public mint is not start");
        require(tx.origin == msg.sender, "forbidden tx");
        require(!hasMinted[msg.sender], "has minted");
        require(msg.value >= price, "tx value is not correct");

        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, totalSupply);
    }

    /// @notice presale
    /// @dev Need to sign
    function presale(uint256 _nonce, bytes memory _signature) public payable {
        require(presaleStart, "presale is not start");
        require(!usedNonce[_nonce], "nonce is used");
        require(msg.value >= price, "tx value is not correct");
        presaleAmount ++;
        require(presaleAmount <= maxPresale, "presale out");
        require(verify(msg.sender, address(this), _nonce, _signature), "sign is not correct");

        usedNonce[_nonce] = true;

        _safeMint(msg.sender, totalSupply);
    }

    /// @notice Divide suit
    /// @dev Need to sign
    function divide(
        uint256 _tokenID,
        uint256[] memory _equipIndexes,
        uint128[][] memory _attrIDs,
        uint128[][] memory _values,
        uint256 _nonce,
        bytes memory _signature
    ) public {
        require(ownerOf(_tokenID) == msg.sender, "owner missed");
        require(!usedNonce[_nonce], "nonce is used");
        require(_attrIDs.length == _values.length && _equipIndexes.length == _attrIDs.length, "params length error");
        require(verify(_tokenID, address(this), _equipIndexes, _attrIDs, _values, _nonce, _signature), "sign is not correct");

        usedNonce[_nonce] = true;

        _burn(_tokenID);

        for (uint256 i; i < _equipIndexes.length; i++) {
            IEquipment(equipments[_equipIndexes[i]]).suitMint(msg.sender, _attrIDs[i], _values[i]);
        }
    }

    function verify(
        uint256 _tokenID,
        address _token,
        uint256[] memory _equipTokenIDs,
        uint128[][] memory _attrIDs,
        uint128[][] memory _values,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWallet(_tokenID, _token, _equipTokenIDs, _attrIDs, _values, _nonce, _signature) == signer;
    }

    function signatureWallet(
        uint256 _tokenID,
        address _token,
        uint256[] memory _equipTokenIDs,
        uint128[][] memory _attrIDs,
        uint128[][] memory _values,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_tokenID, _token, _equipTokenIDs, _attrIDs, _values, _nonce)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address _token,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWallet(_wallet, _token, _nonce, _signature) == signer;
    }

    function signatureWallet(
        address _wallet,
        address _token,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _token, _nonce)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxPresale(uint64 _maxPresale) public onlyOwner {
        maxPresale = _maxPresale;
    }

    function setUnRevealedBaseURI(string memory unRevealedBaseURI_) public onlyOwner {
        unRevealedBaseURI = unRevealedBaseURI_;
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

    function getSigner() public view onlyOwner returns (address){
        return signer;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance != 0);
        payable(vault).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString())) : unRevealedBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) {
            totalSupply ++;
            require(totalSupply <= maxSupply, "suit sold out");
        }
    }
}
