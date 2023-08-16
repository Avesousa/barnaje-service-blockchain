// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct User {
    uint256 balance;  // internal coins balance
    uint256 balanceAvailable; // internal coins balance available to withdraw
    uint256 step;  // current floor
    uint256 countDonations; // number of donations for current step
    address sponsor;  // sponsor address
    address[] directReferrals;  // array of direct referrals
    bool isUser;  // flag to check if the user is registered
    uint256 amountWithdrawn;  // amount withdrawn by the user
    uint256 amountDeposit; // amount deposited by the user
    uint256 amountTransferReceived; // amount received by transfer
    uint256 amountTransferSent; // amount sent by transfer
    uint256 amountDirectReferralReceived; // amount received by direct referrals
    uint256 amountSponsorReceived; // amount received by sponsor
    uint256 amountFirtsGenerationReceived; // amount received by first generation
    uint256 amountSecondGenerationReceived; // amount received by second generation
}