// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Barnaje.sol";

import "./model/StepData.sol";
import "./model/Floor.sol";
import "./model/User.sol";

contract DonationHandler is Ownable{
    event Donate(address indexed user, address sponsor, uint256 step, uint256 amount);

    Barnaje private barnaje;

    uint256 private MAX_STEPS = 20;
    
    constructor(Barnaje _barnaje) {
        barnaje = _barnaje;
        transferOwnership(address(_barnaje));
    }

    function distributeDonation(address _donor, address _sponsor) external onlyOwner {
        // Distribute the donation
        uint256 userBalance = barnaje.getUser(_donor).balance;
        StepData memory stepData = barnaje.getNextStep(_donor);
        while(userBalance >= stepData.amount || stepData.step <= MAX_STEPS) {
            distributeDonationToSponsors(_donor, stepData, _sponsor);
            barnaje.setUserStep(_donor, stepData.step);
            stepData = barnaje.getNextStep(_donor);
            userBalance = barnaje.getUser(_donor).balance;
        }
    }

    

    function distributeDonationToSponsors(address _donor, StepData memory step, address _sponsor) private {
        if (step.floor == Floor.BRONZE) {
            // Pay 100% to the sponsor if the floor is BRONZE
            sendDonationToUser(_donor, _sponsor, step.step, step.amount);
        } else {
            address[] memory upline = barnaje.getUser(_donor).upline;
            uint256 indexFloor = 0;
            uint256 uplineLength = upline.length;

            // Iterate over the upline in reverse order
            for (uint256 i = uplineLength; i > 0; i--) {
                address uplineUser = upline[i-1];
                if (indexFloor >= uint(step.floor) && barnaje.getUser(uplineUser).directReferrals.length >= step.minimumReferrals) {
                    distributeDonationToUser(_donor, uplineUser, step);
                    break;
                }
                indexFloor += 1;
            }
        }
    }

    function distributeDonationToUser(address donor, address sponsor, StepData memory step) private {
        address directSponsor = barnaje.getUser(sponsor).sponsor;
        address directSponsorSponsor = barnaje.getUser(directSponsor).sponsor;
        address dao = barnaje.getDao();

        if(sponsor == dao) {
            sendDonationToUser(donor, sponsor, step.step, step.amount);
            return;
        }

        if(directSponsor == dao){
            sendDonationToUser(donor, directSponsor, step.step, step.amount/2);
            return;
        }

        sendDonationToUser(donor, sponsor, step.step, step.amount / 2);
        sendDonationToUser(donor, directSponsor, step.step, step.amount / 4);
        sendDonationToUser(donor, directSponsorSponsor, step.step, step.amount / 4);
    }

    function sendDonationToUser(address donor, address sponsor, uint256 step, uint256 amount) private {
        barnaje.addUserBalance(sponsor, amount);
        barnaje.removeUserBalance(donor, amount);
        emit Donate(donor, sponsor, step + 1, amount);
    }
}