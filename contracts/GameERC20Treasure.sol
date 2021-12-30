// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GameERC20Treasure is Ownable, Pausable {
    using SafeERC20 for IERC20;

    address private signer;
    mapping(uint256 => bool) private _usedNonce;

    address public token;

    event UpChain(address indexed sender, uint256 amount, uint256 nonce);
    event TopUp(address indexed sender, uint256 amount, uint256 nonce);

    constructor(address _signer, address _token){
        signer = _signer;
        token = _token;
    }

    receive() external payable {}

    function upChain(
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public nonceNotUsed(_nonce) whenNotPaused {
        require(verify(msg.sender, token, _amount, _nonce, this.upChain.selector, _signature), "sign is not correct");
        _usedNonce[_nonce] = true;

        IERC20(token).safeTransfer(msg.sender, _amount);
        emit UpChain(msg.sender, _amount, _nonce);
    }

    function topUp(
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public nonceNotUsed(_nonce) whenNotPaused {
        require(verify(msg.sender, token, _amount, _nonce, this.topUp.selector, _signature), "sign is not correct");
        _usedNonce[_nonce] = true;

        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        emit TopUp(msg.sender, _amount, _nonce);
    }

    function verify(
        address _wallet,
        address _token,
        uint256 _amount,
        uint256 _nonce,
        bytes4 _selector,
        bytes memory _signature
    ) public view returns (bool){
        return signatureWallet(_wallet, _token, _amount, _nonce, _selector, _signature) == signer;
    }

    function signatureWallet(
        address _wallet,
        address _token,
        uint256 _amount,
        uint256 _nonce,
        bytes4 _selector,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(abi.encode(_wallet, _token, _amount, _nonce, _selector));
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function unLockEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
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

    modifier nonceNotUsed(uint256 _nonce){
        require(!_usedNonce[_nonce], "nonce already used");
        _;
    }
}

