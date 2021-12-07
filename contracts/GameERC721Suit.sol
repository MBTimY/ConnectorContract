pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IEquipment {
    function suitMint(
        address _addr,
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        bytes memory _signature
    ) external;
}

contract GameERC721Suit is ERC721, Ownable {
    uint64 public maxPresale;
    uint64 public maxSupply;
    uint64 public presaleAmount;
    uint256 public totalSupply;
    address public vault;

    uint256 public price;
    bool public publicStart;
    bool public presaleStart;

    address[] public equipments;

    mapping(address => bool) hasMinted;
    mapping(address => bool) hasPresale;

    address private signer;
    mapping(uint256 => bool) private usedNonce;

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

    /// @notice public mint
    /// @dev
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
        require(!hasPresale[msg.sender], "has minted");
        require(msg.value >= price, "tx value is not correct");
        presaleAmount ++;
        require(presaleAmount <= maxPresale, "presale out");
        require(verify(msg.sender, address(this), _nonce, _signature), "sign is not correct");

        hasPresale[msg.sender] = true;

        _safeMint(msg.sender, totalSupply);
    }

    /// @notice Divide suit
    /// @dev Need to sign
    function divide(
        uint256 _tokenID,
        uint256[] memory _equipIDs,
        uint256[][] memory _attrIDs,
        uint256[][] memory _values,
        uint256[] memory _nonce,
        bytes[] memory _signatures
    ) public {
        require(ownerOf(_tokenID) == msg.sender, "owner missed");
        require(_equipIDs.length == equipments.length, "equips length error");
        require(_attrIDs.length == _values.length && equipments.length == _attrIDs.length, "params length error");

        _burn(_tokenID);

        for (uint256 i; i < equipments.length; i++) {
            IEquipment(equipments[i]).suitMint(msg.sender, _equipIDs[i], _nonce[i], _attrIDs[i], _values[i], _signatures[i]);
        }
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

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxPresale(uint64 _maxPresale) public onlyOwner {
        maxPresale = _maxPresale;
    }

    function setMaxSupply(uint64 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
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
            require(totalSupply < maxSupply, "sold out");
        }
    }
}
