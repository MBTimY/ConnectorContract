// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IGameLoot.sol";

contract GameLootTreasure is Ownable, Pausable, IERC721Receiver {
    address public controller;
    mapping(uint256 => bool) public usedNonce;
    mapping(uint256 => address) public lastOwner;
    mapping(address => bool) public signers;

    constructor(address _controller, address[] memory _signers){
        require(_controller != address(0), "controller can not be zero");
        controller = _controller;
        for (uint256 i; i < _signers.length; i++)
            signers[_signers[i]] = true;
    }

    event UpChain(address indexed sender, address token, uint256 tokenID, uint256 nonce);
    event TopUp(address indexed sender, address token, uint256 tokenID, uint256 nonce);
    event UpChainBatch(address indexed sender, address[] tokens, uint256[] tokenIDs, uint256 nonce);
    event TopUpBatch(address indexed sender, address[] tokens, uint256[] tokenIDs, uint256 nonce);

    receive() external payable {}

    /// @notice In-game asset set on chain
    /// @dev Need to sign
    function upChain(
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        uint128[] memory _attrIDs,
        uint128[] memory _attrValues,
        uint256[] memory _attrIndexesUpdate,
        uint128[] memory _attrValuesUpdate,
        uint256[] memory _attrIndexesRM,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce) {
        require(msg.sender == lastOwner[_tokenID], "only person who topped up it");
        require(verify(msg.sender, address(this), _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRM, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        if (_attrIDs.length != 0)
            IGameLoot(_token).attachBatch(_tokenID, _attrIDs, _attrValues);

        if (_attrIndexesUpdate.length != 0)
            IGameLoot(_token).updateBatch(_tokenID, _attrIndexesUpdate, _attrValuesUpdate);

        if (_attrIndexesRM.length != 0)
            IGameLoot(_token).removeBatch(_tokenID, _attrIndexesRM);

        lastOwner[_tokenID] = address(0);
        IERC721(_token).transferFrom(address(this), msg.sender, _tokenID);
        emit UpChain(msg.sender, _token, _tokenID, _nonce);
    }

    /// @notice Top up
    /// @dev Need to sign
    function topUp(
        address _token,
        uint256 _tokenID,
        uint256 _nonce
    ) public whenNotPaused nonceNotUsed(_nonce) {
        usedNonce[_nonce] = true;

        lastOwner[_tokenID] = msg.sender;
        IERC721(_token).transferFrom(msg.sender, address(this), _tokenID);
        emit TopUp(msg.sender, _token, _tokenID, _nonce);
    }

    /// @notice Multi In-game assets set on chain
    /// @dev Need to sign
    function upChainBatch(
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint128[][] memory _attrIDs,
        uint128[][] memory _attrValues,
        uint256[][] memory _attrIndexesUpdate,
        uint128[][] memory _attrValuesUpdate,
        uint256[][] memory _attrIndexesRMs,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce) {
        require(verify(msg.sender, address(this), _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRMs, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        for (uint256 i; i < _tokens.length; i++) {
            require(msg.sender == lastOwner[_tokenIDs[i]], "only person who topped up it");
            if (_attrIDs[i].length != 0)
                IGameLoot(_tokens[i]).attachBatch(_tokenIDs[i], _attrIDs[i], _attrValues[i]);

            if (_attrIndexesUpdate[i].length != 0)
                IGameLoot(_tokens[i]).updateBatch(_tokenIDs[i], _attrIndexesUpdate[i], _attrValuesUpdate[i]);

            if (_attrIndexesRMs[i].length != 0)
                IGameLoot(_tokens[i]).removeBatch(_tokenIDs[i], _attrIndexesRMs[i]);

            IERC721(_tokens[i]).transferFrom(address(this), msg.sender, _tokenIDs[i]);
        }
        emit UpChainBatch(msg.sender, _tokens, _tokenIDs, _nonce);
    }

    /// @notice Top up Multi NFTs
    /// @dev Need to sign
    function topUpBatch(
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce
    ) public whenNotPaused nonceNotUsed(_nonce) {
        usedNonce[_nonce] = true;

        for (uint256 i; i < _tokens.length; i++) {
            lastOwner[_tokenIDs[i]] = msg.sender;

            IERC721(_tokens[i]).transferFrom(msg.sender, address(this), _tokenIDs[i]);
        }
        emit TopUpBatch(msg.sender, _tokens, _tokenIDs, _nonce);
    }

    function verify(
        address _wallet,
        address _this,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signers[signatureWallet(_wallet, _this, _tokens, _tokenIDs, _nonce, _signature)];
    }

    function signatureWallet(
        address _wallet,
        address _this,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _this, _tokens, _tokenIDs, _nonce)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address _this,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint128[][] memory _attrIDs,
        uint128[][] memory _attrValues,
        uint256[][] memory _attrIndexesUpdate,
        uint128[][] memory _attrValuesUpdate,
        uint256[][] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal view returns (bool){
        return signers[signatureWallet(_wallet, _this, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRMs, _signature)];
    }

    function signatureWallet(
        address _wallet,
        address _this,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint128[][] memory _attrIDs,
        uint128[][] memory _attrValues,
        uint256[][] memory _attrIndexesUpdate,
        uint128[][] memory _attrValuesUpdate,
        uint256[][] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _this, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRMs)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address _this,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        uint128[] memory _attrIDs,
        uint128[] memory _attrValues,
        uint256[] memory _attrIndexesUpdate,
        uint128[] memory _attrValuesUpdate,
        uint256[] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal view returns (bool){
        return signers[signatureWallet(_wallet, _this, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRMs, _signature)];
    }

    function signatureWallet(
        address _wallet,
        address _this,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        uint128[] memory _attrIDs,
        uint128[] memory _attrValues,
        uint256[] memory _attrIndexesUpdate,
        uint128[] memory _attrValuesUpdate,
        uint256[] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _this, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRMs)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address _this,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signers[signatureWallet(_wallet, _this, _token, _tokenID, _nonce, _signature)];
    }

    function signatureWallet(
        address _wallet,
        address _this,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _this, _token, _tokenID, _nonce)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function pause() public onlyController {
        _pause();
    }

    function unPause() public onlyController {
        _unpause();
    }

    function addSigner(address _signer) public onlyOwner {
        signers[_signer] = true;
    }

    function removeSigner(address _signer) public onlyOwner {
        signers[_signer] = false;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    function unLockEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public override virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier nonceNotUsed(uint256 _nonce){
        require(!usedNonce[_nonce], "nonce already used");
        _;
    }

    modifier onlyController(){
        require(msg.sender == controller, "only controller");
        _;
    }
}

