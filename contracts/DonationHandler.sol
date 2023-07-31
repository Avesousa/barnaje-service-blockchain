// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Barnaje.sol";
import "./TreeHandler.sol";

import "./model/StepData.sol";
import "./model/Floor.sol";
import "./model/User.sol";

contract DonationHandler is Ownable {
    event Donate(address indexed user,address sponsor,uint256 step,uint256 amount);

    Barnaje private barnaje;
    TreeHandler private treeHandler;

    uint256 private MAX_STEPS = 20;

    constructor(Barnaje _barnaje, TreeHandler _treeHandler){
        barnaje = _barnaje;
        treeHandler = _treeHandler;
        transferOwnership(address(_barnaje));
    }

    function distributeDonation(
        address _donor,
        address _sponsor
    ) external onlyOwner {
        // Distribute the donation
        uint256 userBalance = barnaje.getUser(_donor).balance;
        StepData memory stepData = barnaje.getNextStep(_donor);
        while (userBalance >= stepData.amount || stepData.step <= MAX_STEPS) {
            distributeDonationToSponsors(_donor, stepData, _sponsor);
            barnaje.setUserStep(_donor, stepData.step);
            stepData = barnaje.getNextStep(_donor);
            userBalance = barnaje.getUser(_donor).balance;
        }
    }

    function distributeDonationToSponsors(
        address _donor,
        StepData memory step,
        address _sponsor
    ) private {
        if (step.floor == Floor.BRONZE) {
            // Pay 100% to the sponsor if the floor is BRONZE
            // Verify if sponsor meets the requirements, if not, go upline
            address sponsorToDonate = getSponsorToDonate(_sponsor, step.step);
            if(sponsorToDonate == address(0)){
                sponsorToDonate = barnaje.getDao();
            }
            sendDonationToUser(_donor, sponsorToDonate, step.step, step.amount);
            return;
        }
        
        address[] memory upline = treeHandler.getTreeNode(_donor).upline;
        uint256 indexFloor = 0;
        uint256 uplineLength = upline.length;

        // Pay 50% to the sponsor direct and 25% and 25% to the sponsor sponsor
        for (uint256 i = uplineLength; i > 0; i--) {
            address uplineUser = upline[i - 1];
            if (indexFloor >= uint(step.floor) &&
                barnaje.getUser(uplineUser).directReferrals.length >= step.minimumReferrals &&
                barnaje.getUserStep(uplineUser).step >= step.step &&
                uplineUser != address(0)) {

                distributeDonationToUser(_donor, uplineUser, step);
                return;
            }
            indexFloor += 1;
        }
        
        // If no sponsor meeting the conditions is found, send the donation to the DAO user.
        sendDonationToUser(_donor, barnaje.getDao(), step.step, step.amount);
    }

    function distributeDonationToUser(
        address donor,
        address sponsor,
        StepData memory step
    ) private {
        address directSponsor = barnaje.getUser(sponsor).sponsor;
        address directSponsorSponsor = barnaje.getUser(directSponsor).sponsor;
        address dao = barnaje.getDao();

        if (sponsor == dao) {
            sendDonationToUser(donor, sponsor, step.step, step.amount);
            return;
        }

        if (directSponsor == dao) {
            sendDonationToUser(donor,directSponsor,step.step,step.amount / 2);
            return;
        }

        sendDonationToUser(donor, sponsor, step.step, step.amount / 2);
        sendDonationToUser(donor, directSponsor, step.step, step.amount / 4);
        sendDonationToUser(donor,directSponsorSponsor,step.step,step.amount / 4
        );
    }

    function getSponsorToDonate(address _sponsor, uint256 _step) private view returns(address){
        if(barnaje.getUserStep(_sponsor).step >= _step) {
            return _sponsor;
        }
        else {
            return getSponsorToDonate(barnaje.getUser(_sponsor).sponsor, _step);
        }
    }

    function sendDonationToUser(address donor,address sponsor,uint256 step,uint256 amount) private {
        barnaje.addUserBalance(sponsor, amount);
        barnaje.removeUserBalance(donor, amount);
        emit Donate(donor, sponsor, step + 1, amount);
    }
}
