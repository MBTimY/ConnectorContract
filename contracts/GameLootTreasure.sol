pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IGameLoot.sol";

contract GameLootTreasure is Ownable, Pausable, IERC721Receiver {
    address private signer;
    mapping(uint256 => bool) private usedNonce;

    event UpChain(address sender, address token, uint256 tokenID);
    event UpChainBatch(address sender, address[] tokens, uint256[] tokenIDs);
    event TopUp(address sender, address token, uint256 tokenID);
    event TopUpBatch(address sender, address[] tokens, uint256[] tokenIDs);

    constructor(address _signer){
        signer = _signer;
    }

    receive() external payable {}

    /// @notice In-game asset set on chain
    /// @dev Need to sign
    function upChain(
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bool _attrChanged,
        uint128[] memory _attrIDs,
        uint128[] memory _attrValues,
        uint256[] memory _attrIndexesRM,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce) {
        require(verify(msg.sender, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesRM, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        if (_attrChanged) {
            IGameLoot(_token).attachBatch(_tokenID, _attrIDs, _attrValues);
            IGameLoot(_token).removeBatch(_tokenID, _attrIndexesRM);
        }

        IERC721(_token).transferFrom(address(this), msg.sender, _tokenID);
        emit UpChain(msg.sender, _token, _tokenID);
    }

    /// @notice Top up
    /// @dev Need to sign
    function topUp(
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce) {
        require(verify(msg.sender, _token, _tokenID, _nonce, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        IERC721(_token).transferFrom(msg.sender, address(this), _tokenID);
        emit TopUp(msg.sender, _token, _tokenID);
    }

    /// @notice Multi In-game assets set on chain
    /// @dev Need to sign
    function upChainBatch(
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint128[][] memory _attrIDs,
        uint128[][] memory _attrValues,
        uint256[][] memory _attrIndexesRMs,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce){
        require(verify(msg.sender, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIndexesRMs, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        for (uint256 i; i < _tokens.length; i++) {
            IGameLoot(_tokens[i]).attachBatch(_tokenIDs[i], _attrIDs[i], _attrValues[i]);
            IGameLoot(_tokens[i]).removeBatch(_tokenIDs[i], _attrIndexesRMs[i]);
            IERC721(_tokens[i]).transferFrom(address(this), msg.sender, _tokenIDs[i]);
        }

        emit UpChainBatch(msg.sender, _tokens, _tokenIDs);
    }

    /// @notice Top up Multi NFTs
    /// @dev Need to sign
    function topUpBatch(
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce){
        require(verify(msg.sender, _tokens, _tokenIDs, _nonce, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        for (uint256 i; i < _tokens.length; i++) {
            IERC721(_tokens[i]).transferFrom(msg.sender, address(this), _tokenIDs[i]);
        }
        emit TopUpBatch(msg.sender, _tokens, _tokenIDs);
    }

    function verify(
        address _wallet,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWallet(_wallet, _tokens, _tokenIDs, _nonce, _signature) == signer;
    }

    function signatureWallet(
        address _wallet,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _tokens, _tokenIDs, _nonce)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint128[][] memory _attrIDs,
        uint128[][] memory _attrValues,
        uint256[][] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWallet(_wallet, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIndexesRMs, _signature) == signer;
    }

    function signatureWallet(
        address _wallet,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint128[][] memory _attrIDs,
        uint128[][] memory _attrValues,
        uint256[][] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIndexesRMs)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        uint128[] memory _attrIDs,
        uint128[] memory _attrValues,
        uint256[] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWallet(_wallet, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesRMs, _signature) == signer;
    }

    function signatureWallet(
        address _wallet,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        uint128[] memory _attrIDs,
        uint128[] memory _attrValues,
        uint256[] memory _attrIndexesRMs,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIndexesRMs)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verify(
        address _wallet,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWallet(_wallet, _token, _tokenID, _nonce, _signature) == signer;
    }

    function signatureWallet(
        address _wallet,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _token, _tokenID, _nonce)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function getSigner() public view onlyOwner returns (address){
        return signer;
    }

    function isUsed(uint256 _nonce) public view onlyOwner returns (bool){
        return usedNonce[_nonce];
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
}

