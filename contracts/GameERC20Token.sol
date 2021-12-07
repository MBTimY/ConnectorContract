//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract GameERC20Token is ERC20Upgradeable{
    constructor() {}

    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        // initialize inherited contracts
        __ERC20_init(_name, _symbol);
    }
}