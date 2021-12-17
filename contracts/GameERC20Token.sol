//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract GameERC20Token is ERC20Upgradeable {
    address public owner;

    constructor() {}

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_
    ) external initializer {
        // initialize inherited contracts
        __ERC20_init(name_, symbol_);
        owner = owner_;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}