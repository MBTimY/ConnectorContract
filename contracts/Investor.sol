// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct Right {
    uint256 amount;
    // unlocks per second
    uint256 speed;
    uint256 lastTime;
}

contract Investor {
    using SafeERC20 for IERC20;

    address immutable token;
    uint256 public startTime;

    // investor right
    mapping(address => Right) rights;

    constructor(
        address[] memory investors,
        uint256[] memory amounts,
        uint256 period,
        address token_
    ) {
        startTime = block.timestamp;
        token = token_;
        for (uint256 i = 0; i < investors.length; i++) {
            uint256 speed = amounts[i] / period;
            rights[investors[i]] = Right({
                amount: amounts[i],
                speed: speed,
                lastTime: 0
            });
        }
    }

    // unlock
    function unlock() public {
        // time
        uint t;
        if (rights[msg.sender].lastTime == 0) {
            t = block.timestamp - startTime;
        } else {
            t = block.timestamp - rights[msg.sender].lastTime;
        }
        rights[msg.sender].lastTime = block.timestamp;

        // amount
        uint amount = t * rights[msg.sender].speed;
        if (amount > rights[msg.sender].amount)
            amount = rights[msg.sender].amount;
        rights[msg.sender].amount -= amount;

        IERC20(token).safeTransferFrom(address(this), msg.sender, amount);
    }
}
