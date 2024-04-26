// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DroplinkedERC20Token is ERC20 {
    constructor() ERC20("DroplinkedToken", "DROPLINK") {
        _mint(msg.sender, 23000e18);
    }
}