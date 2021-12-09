// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./Governable.sol";

contract GameDaoFixedNFT is Configurable, IERC721ReceiverUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 internal constant TxFeeRatio = bytes32("GAMEDAONFT::TxFeeRatio");
    bytes32 internal constant FeeAccount = bytes32("GAMEDAONFT::FeeAccount");
    bytes32 internal constant DisableErc721 = bytes32("GAMEDAONFT::DisableErc721");

    struct Pool {
        // address of pool creator
        address payable creator;
        // address of sell token
        address token0;
        // address of buy token
        address token1;
        // token id of token0
        uint256 tokenId;
        // total amount of token0
        uint256 amountTotal0;
        // total amount of token1
        uint256 amountTotal1;
        // the timestamp in seconds the pool will be closed
        uint256 closeAt;
    }

    Pool[] public pools;

    // pool index => pool password, if password is not set, the default value is zero
    mapping(uint256 => uint256) public passwordP;
    // pool index => a flag that if creator is claimed the pool
    mapping(uint256 => bool) public creatorClaimedP;
    mapping(uint256 => bool) public swappedP;

    // check if token0 in whitelist
    bool public checkToken0;
    // token0 address => true or false
    mapping(address => bool) public token0List;

    // pool index => swapped amount of token0
    mapping(uint256 => uint256) public swappedAmount0P;
    // pool index => swapped amount of token1
    mapping(uint256 => uint256) public swappedAmount1P;

    /*
    TODO: delete in main net
    */
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    bytes32 internal constant Token1WhiteList = bytes32("GAMEDAONFT::Token1WhiteList");

    event Created(Pool pool, uint256 index);
    event Swapped(address sender, uint256 index, uint256 amount0);
    event Claimed(address sender, uint256 index);
    event Closed(address sender, uint256 index);
    event NewPrice(address sender, uint256 index, uint256 price);
    event NewTime(address sender, uint256 index, uint256 timestamp);

    function initialize(address _governor, address _feeAccount) public initializer {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;

        config[TxFeeRatio] = 0.02 ether;
        config[FeeAccount] = uint256(uint160(_feeAccount));
    }

    function createPool(
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint256 tokenId,
        // total amount of token1
        uint256 amountTotal1,
        // duration time
        uint256 duration
    ) external payable {
        require(!getDisableErc721(), "ERC721 pool is disabled");
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint256 amountTotal0 = 1;
        _create(
            token0, token1, tokenId, amountTotal0, amountTotal1,
            duration
        );
    }

    function _create(
        address token0,
        address token1,
        uint256 tokenId,
        uint256 amountTotal0,
        uint256 amountTotal1,
        uint256 duration
    ) private {
        require(amountTotal1 != 0, "the value of amountTotal1 is zero.");
        require(duration != 0, "the value of duration is zero.");
        require(getToken1WhiteList(token1),"token1 must in white list");

        // transfer tokenId of token0 to this contract
        IERC721Upgradeable(token0).safeTransferFrom(msg.sender, address(this), tokenId);

        // creator pool
        Pool memory pool;
        pool.creator = payable(msg.sender);
        pool.token0 = token0;
        pool.token1 = token1;
        pool.tokenId = tokenId;
        pool.amountTotal0 = amountTotal0;
        pool.amountTotal1 = amountTotal1;
        pool.closeAt = block.timestamp + duration;

        uint256 index = pools.length;

        pools.push(pool);

        emit Created(pool, index);
    }

    function swap(uint256 index) external payable
        isPoolExist(index)
        isPoolNotClosed(index)
        isPoolNotSwap(index)
    {
        Pool storage pool = pools[index];

        // mark pool is swapped
        swappedP[index] = true;

        uint256 txFee = pool.amountTotal1 * getTxFeeRatio() / (1 ether);
        uint256 _actualAmount1 = pool.amountTotal1 - txFee;
        // transfer amount of token1 to creator
        if (pool.token1 == address(0)) {
            require(pool.amountTotal1 <= msg.value, "invalid ETH amount");

            if (_actualAmount1 > 0) {
                // transfer ETH to creator
                pool.creator.transfer(_actualAmount1);
            }
            if (txFee > 0) {
                // transaction fee to fee account
                payable(getFeeAccount()).transfer(txFee);
            }
        } else {
            IERC20Upgradeable(pool.token1).safeTransferFrom(msg.sender, address(this), pool.amountTotal1);
            // transfer token1 to creator
            IERC20Upgradeable(pool.token1).safeTransfer(pool.creator, _actualAmount1);
            IERC20Upgradeable(pool.token1).safeTransfer(getFeeAccount(), txFee);
        }

        // transfer tokenId of token0 to sender
        IERC721Upgradeable(pool.token0).safeTransferFrom(address(this), msg.sender, pool.tokenId);

        emit Swapped(msg.sender, index, pool.amountTotal0);
    }

    function close(uint256 index) external
        isPoolExist(index)
        isPoolNotClosed(index)
        isPoolNotSwap(index)
    {
        require(isCreator(msg.sender, index), "is not creator");
        require(!creatorClaimedP[index], "creator has claimed this pool");

        creatorClaimedP[index] = true;
        pools[index].closeAt = block.timestamp - 1;

        Pool memory pool = pools[index];
        IERC721Upgradeable(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);
        emit Closed(msg.sender, index);
    }

    function creatorRedeem(uint256 index) external
        isPoolExist(index)
        isPoolClosed(index)
        isPoolNotSwap(index)
    {
        require(isCreator(msg.sender, index), "sender is not pool creator");
        require(!creatorClaimedP[index], "creator has claimed this pool");
        creatorClaimedP[index] = true;

        Pool memory pool = pools[index];
        IERC721Upgradeable(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);

        emit Claimed(msg.sender, index);
    }

    function setNewTime(uint256 index, uint256 timeStamp) external isPoolNotSwap(index) {
        require(isCreator(msg.sender, index), "is not creator");
        require(timeStamp > block.timestamp,"time is invalid");
        pools[index].closeAt = timeStamp;
        emit NewTime(msg.sender, index, timeStamp);
    }

    function setNewPrice(uint256 index, uint256 price) external isPoolNotClosed(index) isPoolNotSwap(index) {
        require(isCreator(msg.sender, index), "is not creator");
        pools[index].amountTotal1 = price;
        emit NewPrice(msg.sender, index, price);
    }

    function transferGovernor(address _governor) external {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;
    }

    function isCreator(address target, uint256 index) internal view returns (bool) {
        if (pools[index].creator == target) {
            return true;
        }
        return false;
    }

    function getTxFeeRatio() public view returns (uint256) {
        return config[TxFeeRatio];
    }

    function getFeeAccount() public view returns (address) {
        return address(uint160(config[FeeAccount]));
    }

    function getDisableErc721() public view returns (bool) {
        return config[DisableErc721] != 0;
    }

    function getToken1WhiteList(address token1_) public view returns (bool){
        return getConfig(Token1WhiteList, token1_) != 0;
    }

    function getPoolCount() external view returns (uint256) {
        return pools.length;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier isPoolClosed(uint256 index) {
        require(pools[index].closeAt <= block.timestamp, "this pool is not closed");
        _;
    }

    modifier isPoolNotClosed(uint256 index) {
        require(pools[index].closeAt > block.timestamp, "this pool is closed");
        _;
    }

    modifier isPoolNotSwap(uint256 index) {
        require(!swappedP[index], "this pool is swapped");
        _;
    }

    modifier isPoolExist(uint256 index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }
}
