// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Floor.sol";

struct StepData {
    uint256 amount;
    uint256 step;
    Floor floor;
    uint256 minimumReferrals;
}