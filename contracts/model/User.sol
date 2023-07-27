// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct User {
    uint256 balance;  // internal coins balance
    uint256 step;  // current floor
    address sponsor;  // sponsor address
    address[] directReferrals;  // array of direct referrals
    address[][] treeReferrals; // mapping of tree referrals 2xN
    address[] upline; // array of upline addresses
}