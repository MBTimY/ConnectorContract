// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IGameLoot.sol";

contract GameLootTreasure is Ownable, Pausable, IERC721Receiver {
    address[] public signers;
    mapping(uint256 => bool) public usedNonce;

    constructor(address[] memory _signers){
        signers = _signers;
    }

    event UpChain(address token, uint256 tokenID, uint256 nonce);
    event TopUp(address token, uint256 tokenID, uint256 nonce);
    event UpChainBatch(address[] tokens, uint256[] tokenIDs, uint256 nonce);
    event TopUpBatch(address[] tokens, uint256[] tokenIDs, uint256 nonce);

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
        require(verify(msg.sender, address(this), _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRM, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        if (_attrIDs.length != 0)
            IGameLoot(_token).attachBatch(_tokenID, _attrIDs, _attrValues);

        if (_attrIndexesUpdate.length != 0)
            IGameLoot(_token).updateBatch(_tokenID, _attrIndexesUpdate, _attrValuesUpdate);

        if (_attrIndexesRM.length != 0)
            IGameLoot(_token).removeBatch(_tokenID, _attrIndexesRM);

        IERC721(_token).transferFrom(address(this), msg.sender, _tokenID);
        emit UpChain(_token, _tokenID, _nonce);
    }

    /// @notice Top up
    /// @dev Need to sign
    function topUp(
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce) {
        require(verify(msg.sender, address(this), _token, _tokenID, _nonce, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        IERC721(_token).transferFrom(msg.sender, address(this), _tokenID);
        emit TopUp(_token, _tokenID, _nonce);
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
            if (_attrIDs[i].length != 0)
                IGameLoot(_tokens[i]).attachBatch(_tokenIDs[i], _attrIDs[i], _attrValues[i]);

            if (_attrIndexesUpdate[i].length != 0)
                IGameLoot(_tokens[i]).updateBatch(_tokenIDs[i], _attrIndexesUpdate[i], _attrValuesUpdate[i]);

            if (_attrIndexesRMs[i].length != 0)
                IGameLoot(_tokens[i]).removeBatch(_tokenIDs[i], _attrIndexesRMs[i]);

            IERC721(_tokens[i]).transferFrom(address(this), msg.sender, _tokenIDs[i]);
        }
        emit UpChainBatch(_tokens, _tokenIDs, _nonce);
    }

    /// @notice Top up Multi NFTs
    /// @dev Need to sign
    function topUpBatch(
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce) {
        require(verify(msg.sender,address(this), _tokens, _tokenIDs, _nonce, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        for (uint256 i; i < _tokens.length; i++) {
            IERC721(_tokens[i]).transferFrom(msg.sender, address(this), _tokenIDs[i]);
        }
        emit TopUpBatch(_tokens, _tokenIDs, _nonce);
    }

    function verify(
        address _wallet,
        address _this,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return isSigner(signatureWallet(_wallet,_this, _tokens, _tokenIDs, _nonce, _signature));
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
            abi.encode(_wallet,_this, _tokens, _tokenIDs, _nonce)
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
        return isSigner(signatureWallet(_wallet, _this, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRMs, _signature));
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
        return isSigner(signatureWallet(_wallet, _this, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesUpdate, _attrValuesUpdate, _attrIndexesRMs, _signature));
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
        return isSigner(signatureWallet(_wallet, _this, _token, _tokenID, _nonce, _signature));
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

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function addSigner(address _signer) public onlyOwner {
        signers.push(_signer);
    }

    function removeSigner(uint256 _index) public onlyOwner {
        signers[_index] = signers[signers.length - 1];
        signers.pop();
    }

    function unLockEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function isSigner(address s) internal view returns (bool){
        for (uint256 i; i < signers.length; i++) {
            if (s == signers[i]) {
                return true;
            }
        }
        return false;
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
}

