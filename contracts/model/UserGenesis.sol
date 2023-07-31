// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct UserGenesis {
    address me;  // user address
    uint256 balance;  // internal coins balance
    address sponsor;  // sponsor address
}