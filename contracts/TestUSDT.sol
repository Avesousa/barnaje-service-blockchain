// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDT is ERC20 {
    constructor() ERC20("Test USDT", "TUSDT") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1,000,000 TUSDT tokens to the deployer
    }
}