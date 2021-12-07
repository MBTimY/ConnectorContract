pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IGameERC721.sol";

contract GameERC721Treasure is Ownable, Pausable, IERC721Receiver {

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
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        uint256[] memory _attrIDsRM,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce) {
        require(verifyUpChain(msg.sender, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIDsRM, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        if (_attrChanged) {
            IGameERC721(_token).attachBatch(_tokenID, _attrIDs, _attrValues);
            IGameERC721(_token).removeBatch(_tokenID, _attrIDsRM);
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
        require(verifyTopUp(msg.sender, _token, _tokenID, _nonce, _signature), "sign is not correct");
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
        uint256[][] memory _attrIDs,
        uint256[][] memory _attrValues,
        uint256[][] memory _attrIDsRMs,
        bytes memory _signature
    ) public whenNotPaused nonceNotUsed(_nonce){
        require(verifyUpChainBatch(msg.sender, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIDsRMs, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        for (uint256 i; i < _tokens.length; i++) {
            IGameERC721(_tokens[i]).attachBatch(_tokenIDs[i], _attrIDs[i], _attrValues[i]);
            IGameERC721(_tokens[i]).removeBatch(_tokenIDs[i], _attrIDsRMs[i]);
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
        require(verifyTopUpBatch(msg.sender, _tokens, _tokenIDs, _nonce, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        for (uint256 i; i < _tokens.length; i++) {
            IERC721(_tokens[i]).transferFrom(msg.sender, address(this), _tokenIDs[i]);
        }
        emit TopUpBatch(msg.sender, _tokens, _tokenIDs);
    }

    function verifyTopUpBatch(
        address _wallet,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWalletTopUpBatch(_wallet, _tokens, _tokenIDs, _nonce, _signature) == signer;
    }

    function signatureWalletTopUpBatch(
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

    function verifyUpChainBatch(
        address _wallet,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint256[][] memory _attrIDs,
        uint256[][] memory _attrValues,
        uint256[][] memory _attrIDRMs,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWalletUpChainBatch(_wallet, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIDRMs, _signature) == signer;
    }

    function signatureWalletUpChainBatch(
        address _wallet,
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce,
        uint256[][] memory _attrIDs,
        uint256[][] memory _attrValues,
        uint256[][] memory _attrIDRMs,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _tokens, _tokenIDs, _nonce, _attrIDs, _attrValues, _attrIDRMs)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verifyUpChain(
        address _wallet,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        uint256[] memory _attrIDsRM,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWalletUpChain(_wallet, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIDsRM, _signature) == signer;
    }

    function signatureWalletUpChain(
        address _wallet,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        uint256[] memory _attrIDs,
        uint256[] memory _attrValues,
        uint256[] memory _attrIDsRM,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(
            abi.encode(_wallet, _token, _tokenID, _nonce, _attrIDs, _attrValues, _attrIDsRM)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function verifyTopUp(
        address _wallet,
        address _token,
        uint256 _tokenID,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool){
        return signatureWalletTopUp(_wallet, _token, _tokenID, _nonce, _signature) == signer;
    }

    function signatureWalletTopUp(
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

