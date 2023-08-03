// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct User {
    uint256 balance;  // internal coins balance
    uint256 step;  // current floor
    address sponsor;  // sponsor address
    address[] directReferrals;  // array of direct referrals
    bool isUser;  // flag to check if the user is registered
}