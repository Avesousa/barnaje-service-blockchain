// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./model/StepData.sol";
import "./model/Floor.sol";

contract Genesis is Ownable{

    function generateSteps() public pure returns (StepData[] memory) {
        StepData[] memory steps = new StepData[](21);
        // Populate the steps array
        steps[0] = StepData({amount: 50 wei, step: 0, floor: Floor.BRONZE, minimumReferrals: 0});
        steps[1] = StepData({amount: 100 wei, step: 1, floor: Floor.BRONZE, minimumReferrals: 0});
        steps[2] = StepData({amount: 200 wei, step: 2, floor: Floor.BRONZE, minimumReferrals: 0});
        steps[3] = StepData({amount: 300 wei, step: 3, floor: Floor.SILVER, minimumReferrals: 0});
        steps[4] = StepData({amount: 500 wei, step: 4, floor: Floor.SILVER, minimumReferrals: 0});
        steps[5] = StepData({amount: 700 wei, step: 5, floor: Floor.SILVER, minimumReferrals: 0});
        steps[6] = StepData({amount: 1000 wei, step: 6, floor: Floor.GOLD, minimumReferrals: 0});
        steps[7] = StepData({amount: 1400 wei, step: 7, floor: Floor.GOLD, minimumReferrals: 0});
        steps[8] = StepData({amount: 1800 wei, step: 8, floor: Floor.GOLD, minimumReferrals: 0});
        steps[9] = StepData({amount: 2200 wei, step: 9, floor: Floor.EMERALD, minimumReferrals: 1});
        steps[10] = StepData({amount: 2600 wei, step: 10, floor: Floor.EMERALD, minimumReferrals: 1});
        steps[11] = StepData({amount: 3000 wei, step: 11, floor: Floor.EMERALD, minimumReferrals: 1});
        steps[12] = StepData({amount: 3500 wei, step: 12, floor: Floor.SAPPHIRE, minimumReferrals: 2});
        steps[13] = StepData({amount: 4000 wei, step: 13, floor: Floor.SAPPHIRE, minimumReferrals: 2});
        steps[14] = StepData({amount: 4500 wei, step: 14, floor: Floor.SAPPHIRE, minimumReferrals: 2});
        steps[15] = StepData({amount: 5000 wei, step: 15, floor: Floor.RUBY, minimumReferrals: 3});
        steps[16] = StepData({amount: 5500 wei, step: 16, floor: Floor.RUBY, minimumReferrals: 3});
        steps[17] = StepData({amount: 6000 wei, step: 17, floor: Floor.RUBY, minimumReferrals: 3});
        steps[18] = StepData({amount: 7000 wei, step: 18, floor: Floor.DIAMOND, minimumReferrals: 4});
        steps[19] = StepData({amount: 8000 wei, step: 19, floor: Floor.DIAMOND, minimumReferrals: 4});
        steps[20] = StepData({amount: 10000 wei, step: 20, floor: Floor.DIAMOND, minimumReferrals: 4});
        return steps;
    }

}