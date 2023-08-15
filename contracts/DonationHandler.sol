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

    uint256 private MAX_STEPS = 21;
    uint256 private MIN_STEP_FOR_USER_AVAILABLE = 4;

    constructor(Barnaje _barnaje, TreeHandler _treeHandler){
        barnaje = _barnaje;
        treeHandler = _treeHandler;
        transferOwnership(address(_barnaje));
    }

    function distributeDonation(
        address _donor,
        address _sponsor
    ) public onlyOwner {
        // Distribute the donation
        uint256 userBalance = barnaje.getUserBalance(_donor);
        StepData memory stepData = barnaje.getNextStep(_donor);
        if(_donor != barnaje.getDao()) {
            while (userBalance >= stepData.amount && stepData.step <= MAX_STEPS) {
                distributeDonationToSponsors(_donor, stepData, _sponsor);
                barnaje.setUserStep(_donor, stepData.step);
                userBalance -= stepData.amount;
                stepData = barnaje.getNextStep(_donor);
            }
            if(barnaje.getUserStep(_donor).step >= MIN_STEP_FOR_USER_AVAILABLE){
                barnaje.enableUserToDistributeProfit(_donor);
            }
        } else {
            barnaje.setUserStep(_donor, MAX_STEPS);
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

            if(step.step == 1){
                barnaje.newUser();
            }

            sendDonationToUser(_donor, sponsorToDonate, step.step, step.amount);
            barnaje.getUser(sponsorToDonate).amountDirectReferralReceived += step.amount;
            return;
        }

        
        address[] memory upline = treeHandler.getTreeNode(_donor).upline;
        uint256 indexFloor = 1;
        uint256 uplineLength = upline.length;
        
        if(uplineLength > 0){
            // Pay 50% to the sponsor direct and 25% and 25% to the sponsor sponsor
            for (uint256 i = uplineLength - 1; i > 0; i--) {
                address uplineUser = upline[i];
                if (indexFloor >= uint256(step.floor) &&
                    barnaje.getUser(uplineUser).directReferrals.length >= step.minimumReferrals &&
                    barnaje.getUserStep(uplineUser).step >= step.step &&
                    uplineUser != address(0)) {
                    distributeDonationToUser(_donor, uplineUser, step);
                    return;
                }else if(uplineUser == barnaje.getDao() || uplineUser == address(0)){
                    distributeDonationToUser(_donor, barnaje.getDao(), step);
                    return;
                }
                indexFloor += 1;
            }
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
        uint256 amount = step.amount;
        uint256 amountToSponsor = amount / 2;
        uint256 amountToGeneration = amount / 4;

        if (sponsor == dao || sponsor == address(0)) {
            sendDonationToUser(donor, dao, step.step, amount);
            barnaje.getUser(dao).amountSponsorReceived += amount;
            return;
        }

        if (directSponsor == dao || directSponsor == address(0)) {
            sendDonationToUser(donor, sponsor, step.step, amountToSponsor);
            sendDonationToUser(donor, dao, step.step,amountToSponsor);

            barnaje.getUser(sponsor).amountSponsorReceived += amountToSponsor;
            barnaje.getUser(dao).amountSponsorReceived += amountToSponsor;
            return;
        }

        if(directSponsorSponsor == dao || directSponsorSponsor == address(0)){
            sendDonationToUser(donor, sponsor, step.step, amountToSponsor);
            sendDonationToUser(donor, directSponsor, step.step, amountToGeneration);
            sendDonationToUser(donor, dao, step.step, amountToGeneration);

            barnaje.getUser(sponsor).amountSponsorReceived += amountToSponsor;
            barnaje.getUser(directSponsor).amountFirtsGenerationReceived += amountToGeneration;
            barnaje.getUser(dao).amountSponsorReceived += amountToGeneration;
            return;
        }

        sendDonationToUser(donor, sponsor, step.step, amountToSponsor);
        sendDonationToUser(donor, directSponsor, step.step, amountToGeneration);
        sendDonationToUser(donor,directSponsorSponsor, step.step,amountToGeneration);

        barnaje.getUser(sponsor).amountSponsorReceived += amountToSponsor;
        barnaje.getUser(directSponsor).amountFirtsGenerationReceived += amountToGeneration;
        barnaje.getUser(directSponsorSponsor).amountSecondGenerationReceived += amountToGeneration;
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
