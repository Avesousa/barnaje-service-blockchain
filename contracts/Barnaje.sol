// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Genesis.sol";
import "./SponsorHandler.sol";
import "./DonationHandler.sol";

import "./model/StepData.sol";
import "./model/Floor.sol";
import "./model/User.sol";

contract Barnaje is Ownable{

    event Deposit(address indexed donor, uint256 amount);
    event Transfer(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier OnlyKnownContract {
        require(msg.sender == address(donationHandler) || msg.sender == address(sponsorHandler), "Unknown contract");
        _;
    }


    IERC20 private usdt;  // USDT token contract interface
    DonationHandler private  donationHandler; // Donation handler contract interface
    SponsorHandler private sponsorHandler; // Manager sponsor contract interface

    mapping(address => User) private users;
    
    StepData[] private steps; // Steps and floor
    address private dao;  // DAO address

    constructor(IERC20 _usdt, address _dao) {
        usdt = _usdt;
        Genesis genesis = new Genesis();
        steps = genesis.generateSteps();
        donationHandler = new DonationHandler(this);
        sponsorHandler = new SponsorHandler(this);
        dao = _dao;
        transferOwnership(dao);
    }

    function deposit(uint256 _amount) public {
        usdt.transferFrom(msg.sender, address(this), _amount);
        users[msg.sender].balance += _amount;
    }

    function donate(address _sponsor) public {
        require(users[msg.sender].balance >= this.getNextStep(msg.sender).amount, "Insufficient balance for donation");
        require(_sponsor != msg.sender, "Cannot sponsor self");
        address actualSponsor = sponsorHandler.manageSponsor(msg.sender, _sponsor);
        donationHandler.distributeDonation(msg.sender, actualSponsor);
    }

    function transfer(address _to, uint256 _amount) public {
        require(users[msg.sender].balance >= _amount, "Insufficient balance for transfer");
        require(_to != msg.sender, "Cannot transfer to self");
        
        // Decrement sender's balance
        users[msg.sender].balance -= _amount;

        // Increment receiver's balance
        users[_to].balance += _amount;
    }
    
    function getNextStep(address _user) external view returns (StepData memory) {
        StepData memory nextStep = steps[users[_user].step + 1];
        if (nextStep.step <= steps.length) {
            return nextStep;
        }
        return steps[steps.length - 1];
    }

    function getDao() external returns (address){
        return dao;
    }

    function getUser(address _user) public view returns (User memory) {
        return users[_user];
    }

    function setUserStep(address _user, uint256 step) external OnlyKnownContract{
        users[_user].step = step;
    }

    function addUserBalance(address _user, uint256 _amount) external OnlyKnownContract {
        users[_user].balance += _amount;
    }

    function removeUserBalance(address _user, uint256 _amount) external OnlyKnownContract {
        users[_user].balance -= _amount;
    }

    function addSponsor(address _user, address sponsor) external OnlyKnownContract {
        users[_user].sponsor = sponsor;
    }

    function addDirectReferrals(address _user, address referral) external OnlyKnownContract {
        users[_user].directReferrals.push(referral);
    }

    function addReferralToTree(address _user, uint256 index, address referral) external OnlyKnownContract {
        users[_user].treeReferrals[index].push(referral);
    }

    function createTreeReferrals(address _user, address referrals) external OnlyKnownContract {
        users[_user].treeReferrals.push([referrals]);
    }

    function setUserUpline(address _user, address[] memory upline) external OnlyKnownContract{
        users[_user].upline = upline;
    }

    function addUserUpline(address _user, address upline) external OnlyKnownContract{
        users[_user].upline.push(upline);
    }
    
    
}
