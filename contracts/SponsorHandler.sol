// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Barnaje.sol";
import "./model/User.sol";

contract SponsorHandler is Ownable{

    Barnaje private barnaje;

    uint256 public constant maxDirectReferrals = 4;

    constructor(Barnaje _barnaje) {
        barnaje = _barnaje;
    }

    function manageSponsor(address _user, address _sponsor) public onlyOwner returns (address){
        User memory user = barnaje.getUser(_user);
        address actualSponsor = user.sponsor;
        // If the user already has a sponsor, we don't need to find a new one or add to the tree
        if (user.sponsor == address(0)) {
            if (barnaje.getUser(actualSponsor).directReferrals.length >= maxDirectReferrals) {
                actualSponsor = addSponsorToUser(_sponsor);
            } else {
                actualSponsor = _sponsor;
            }
            barnaje.addDirectReferrals(actualSponsor, _user);
            barnaje.addSponsor(_user, actualSponsor);
            addToTree(_user, actualSponsor);
        }
        return actualSponsor;
    }

    function addSponsorToUser(address _sponsor) internal view returns (address) {
        address newSponsor = _sponsor;
        uint256 minDirectReferrals = maxDirectReferrals;
        User memory sponsor = barnaje.getUser(_sponsor);

        for (uint i = 0; i < sponsor.directReferrals.length; i++) {
            address referral = sponsor.directReferrals[i];
            uint256 referralDirectReferralsCount = barnaje.getUser(referral).directReferrals.length;

            if (referralDirectReferralsCount < minDirectReferrals) {
                minDirectReferrals = referralDirectReferralsCount;
                newSponsor = referral;
            }
        }

        return newSponsor;
    }

    function addToTree(address _user, address _sponsor) internal {

        // Create a queue for BFS, starting with the sponsor
        address[] memory queue = new address[](1);
        queue[0] = _sponsor;

        uint256 front = 0;

        // While there are still addresses in the queue
        while (front < queue.length) {
            address currentAddress = queue[front];
            front += 1;  // Dequeue the current address

            // If the current address has less than 2 direct referrals, add the user here
            if (barnaje.getUser(currentAddress).treeReferrals.length < 2) {
                barnaje.createTreeReferrals(currentAddress, _user);
                // Update the upline
                manageUpline(_user, currentAddress);
                return;
            } 
            else if (barnaje.getUser(currentAddress).treeReferrals[0].length < 2) {
                barnaje.addReferralToTree(currentAddress, 0, _user);
                // Update the upline
                manageUpline(_user, currentAddress);
                return;
            }
            else if (barnaje.getUser(currentAddress).treeReferrals[1].length < 2) {
                barnaje.addReferralToTree(currentAddress, 1, _user);
                // Update the upline
                manageUpline(_user, currentAddress);
                return;
            } else {
                // Otherwise, enqueue all referrals of the current address
                for (uint256 i = 0; i < barnaje.getUser(currentAddress).treeReferrals.length; i++) {
                    for (uint256 j = 0; j < barnaje.getUser(currentAddress).treeReferrals[i].length; j++) {
                        queue[queue.length] = barnaje.getUser(currentAddress).treeReferrals[i][j];
                    }
                }
            }
        }
    }

    function manageUpline(address _user, address currentAddress) private {
        barnaje.setUserUpline(_user, barnaje.getUser(currentAddress).upline);
        barnaje.addUserUpline(_user, currentAddress);
    }

}