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

    //  receive ETH
    address public vault;

    uint64 immutable public maxSupply = 2200;
    uint64 public maxPresale;
    uint64 public presaleAmount;
    uint64 public totalSupply;

    string private baseURI;
    string private unRevealedBaseURI;

    uint256 public price;
    bool public publicStart;
    bool public presaleStart;

    //  auction
    uint64 public auctionStartTime;
    uint64 public maxPerAddressDuringAuction = 3;
    mapping(address => uint256) public numberMinted;

    address[] public equipments;

    mapping(address => uint256) public preAmount;

    mapping(address => bool) public signers;
    mapping(uint256 => bool) public usedNonce;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _equipment,
        uint256 _price,
        address _vault,
        address[] memory _signers
    ) ERC721(_name, _symbol){
        equipments = _equipment;
        price = _price;
        vault = _vault;
        for (uint256 i; i < _signers.length; i++)
            signers[_signers[i]] = true;
    }

    receive() external payable {}

    /// @notice public mint
    /// @dev Each address can only mint once, only one can be minted at a time
    function mint() external payable callerIsUser {
        require(publicStart, "public mint is not start");
        require(numberMinted[msg.sender] == 0, "has minted");
        require(msg.value >= price, "tx value is not correct");

        numberMinted[msg.sender] ++;
        _safeMint(msg.sender, totalSupply);
    }

    /// @notice presale
    /// @dev presale for white list
    function presale(uint64 _amount) external payable {
        require(presaleStart, "presale is not start");
        require(preAmount[msg.sender] >= _amount, "can't mint so many");
        require(msg.value >= price * _amount, "tx value is not correct");
        presaleAmount += _amount;
        require(presaleAmount <= maxPresale, "presale out");

        preAmount[msg.sender] -= _amount;
        for (uint256 i; i < _amount; i++)
            _safeMint(msg.sender, totalSupply);
    }

    function auctionMint(uint64 _amount) external payable callerIsUser {
        uint256 _saleStartTime = uint256(auctionStartTime);
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );
        require(
            numberMinted[msg.sender] + _amount <= maxPerAddressDuringAuction,
            "can not mint this many"
        );
        if (totalSupply + _amount > maxSupply)
            _amount = maxSupply - totalSupply;

        uint256 totalCost = getAuctionPrice(_saleStartTime) * _amount;
        for (uint256 i; i < _amount; i++)
            _safeMint(msg.sender, totalSupply);

        refundIfOver(totalCost);
    }

    function refundIfOver(uint256 cost) private {
        require(msg.value >= cost, "Need to send more ETH.");
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    uint256 public constant AUCTION_START_PRICE = 5 ether;
    uint256 public constant AUCTION_END_PRICE = 0.5 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 360 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

    function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256) {
        if (block.timestamp < _saleStartTime) {
            return AUCTION_START_PRICE;
        }
        if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) /
            AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
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
        uint256[] memory _equipIndexes,
        uint128[][] memory _attrIDs,
        uint128[][] memory _values,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signers[signatureWallet(_tokenID, _token, _equipIndexes, _attrIDs, _values, _nonce, _signature)];
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

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxPresale(uint64 _maxPresale) public onlyOwner {
        require(_maxPresale <= maxSupply, "can not exceed maxSupply");
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

    function withdraw() public onlyOwner {
        require(address(this).balance != 0);
        payable(vault).transfer(address(this).balance);
    }

    function addSigner(address _signer) public onlyOwner {
        signers[_signer] = true;
    }

    function removeSigner(address _signer) public onlyOwner {
        signers[_signer] = false;
    }

    function setAuctionStartTime(uint64 _auctionStartTime) public onlyOwner {
        auctionStartTime = _auctionStartTime;
    }

    function setMaxPerAddressDuringAuction(uint64 _maxPerAddressDuringAuction) public onlyOwner {
        maxPerAddressDuringAuction = _maxPerAddressDuringAuction;
    }

    function setPresaleUserAmount(address _user, uint256 _amount) public onlyOwner {
        preAmount[_user] = _amount;
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

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}
