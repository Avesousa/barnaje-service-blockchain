// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBarnajeSpreadProfits {
    function spreadProfits() external;
    function transferOwnership(address newOwner) external;
}