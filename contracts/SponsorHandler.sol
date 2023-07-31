// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Barnaje.sol";
import "./model/User.sol";

contract SponsorHandler is Ownable{

    Barnaje private barnaje;

    bool daoDone;
    uint256 public constant maxDirectReferrals = 4;

    constructor(Barnaje _barnaje) {
        barnaje = _barnaje;
        transferOwnership(address(_barnaje));
    }

    function manageSponsor(address _user, address _sponsor) public onlyOwner returns (address){
        require(_user != address(0), "user cannot be 0 address");
        require(_sponsor != address(0) || _user == barnaje.getDao(), "sponsor cannot be 0 address");
        // require(_user != barnaje.getDao() && !daoDone, "has a referral Dao cannot have more than one referral");
        require(_user != _sponsor, "user cannot be sponsor");
        // If the user is the DAO, we don't need to find a new one or add to the tree
        if(_user == barnaje.getDao()){
            daoDone = true;
            barnaje.addSponsor(_user, address(0));
            return address(0);
        }

        // If the user is being sponsored by the DAO, we don't need to find a new one or add to the tree
        if(_sponsor == barnaje.getDao()){
            barnaje.addDirectReferrals(_sponsor, _user);
            barnaje.addSponsor(_user, _sponsor);
            return _sponsor;
        }

        User memory user = barnaje.getUser(_user);
        address actualSponsor = user.sponsor;

        // If the user already has a sponsor, we don't need to find a new one or add to the tree
        if (actualSponsor == address(0)) {
            if (barnaje.getUser(_sponsor).directReferrals.length >= maxDirectReferrals) {
                actualSponsor = addSponsorToUser(_sponsor);
            } else {
                actualSponsor = _sponsor;
            }
            barnaje.addDirectReferrals(actualSponsor, _user);
            barnaje.addSponsor(_user, actualSponsor);
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

}