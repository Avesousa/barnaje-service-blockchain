// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./model/UserGenesis.sol";
import "./model/StepData.sol";
import "./model/Floor.sol";

contract Genesis is Ownable{

    function convertToUSDT(uint256 baseAmount) internal pure returns (uint256) {
        return baseAmount * 1e6;
    }

    function generateSteps() public pure returns (StepData[] memory) {
        StepData[] memory steps = new StepData[](22);
         // Populate the steps array
        steps[0] = StepData({amount: convertToUSDT(0), step: 0, floor: Floor.INIT, minimumReferrals: 0});
        steps[1] = StepData({amount: convertToUSDT(50), step: 1, floor: Floor.BRONZE, minimumReferrals: 0});
        steps[2] = StepData({amount: convertToUSDT(100), step: 2, floor: Floor.BRONZE, minimumReferrals: 0});
        steps[3] = StepData({amount: convertToUSDT(200), step: 3, floor: Floor.BRONZE, minimumReferrals: 0});
        steps[4] = StepData({amount: convertToUSDT(300), step: 4, floor: Floor.SILVER, minimumReferrals: 0});
        steps[5] = StepData({amount: convertToUSDT(500), step: 5, floor: Floor.SILVER, minimumReferrals: 0});
        steps[6] = StepData({amount: convertToUSDT(700), step: 6, floor: Floor.SILVER, minimumReferrals: 0});
        steps[7] = StepData({amount: convertToUSDT(1000), step: 7, floor: Floor.GOLD, minimumReferrals: 0});
        steps[8] = StepData({amount: convertToUSDT(1400), step: 8, floor: Floor.GOLD, minimumReferrals: 0});
        steps[9] = StepData({amount: convertToUSDT(1800), step: 9, floor: Floor.GOLD, minimumReferrals: 0});
        steps[10]= StepData({amount: convertToUSDT(2200), step: 10, floor: Floor.EMERALD, minimumReferrals: 1});
        steps[11] = StepData({amount: convertToUSDT(2600), step: 11, floor: Floor.EMERALD, minimumReferrals: 1});
        steps[12] = StepData({amount: convertToUSDT(3000), step: 12, floor: Floor.EMERALD, minimumReferrals: 1});
        steps[13] = StepData({amount: convertToUSDT(3500), step: 13, floor: Floor.SAPPHIRE, minimumReferrals: 2});
        steps[14] = StepData({amount: convertToUSDT(4000), step: 14, floor: Floor.SAPPHIRE, minimumReferrals: 2});
        steps[15] = StepData({amount: convertToUSDT(4500), step: 15, floor: Floor.SAPPHIRE, minimumReferrals: 2});
        steps[16] = StepData({amount: convertToUSDT(5000), step: 16, floor: Floor.RUBY, minimumReferrals: 3});
        steps[17] = StepData({amount: convertToUSDT(5500), step: 17, floor: Floor.RUBY, minimumReferrals: 3});
        steps[18] = StepData({amount: convertToUSDT(6000), step: 18, floor: Floor.RUBY, minimumReferrals: 3});
        steps[19] = StepData({amount: convertToUSDT(7000), step: 19, floor: Floor.DIAMOND, minimumReferrals: 4});
        steps[20] = StepData({amount: convertToUSDT(8000), step: 20, floor: Floor.DIAMOND, minimumReferrals: 4});
        steps[21] = StepData({amount: convertToUSDT(10000), step: 21, floor: Floor.DIAMOND, minimumReferrals: 4});
        return steps;
    }
}