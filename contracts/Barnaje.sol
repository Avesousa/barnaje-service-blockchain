// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Genesis.sol";
import "./SponsorHandler.sol";
import "./TreeHandler.sol";
import "./DonationHandler.sol";

import "./model/StepData.sol";
import "./model/TreeNode.sol";
import "./model/UserGenesis.sol";
import "./model/Floor.sol";
import "./model/User.sol";

contract Barnaje is Ownable{

    event Deposit(address indexed donor, uint256 amount);
    event Transfer(address indexed from, address to, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier OnlyKnownContract {
        require(msg.sender == address(donationHandler) || msg.sender == address(sponsorHandler), "Unknown contract");
        _;
    }

    IERC20 private usdt;  // USDT token contract interface
    DonationHandler public  donationHandler; // Donation handler contract interface
    SponsorHandler public sponsorHandler; // Manager sponsor contract interface
    TreeHandler public treeHandler; // Manager sponsor contract interface


    mapping(address => User) private users;
    
    StepData[] private steps; // Steps and floor
    address private dao;  // DAO address
    bool private hasGenesis; // Flag to check if the contract is initialized

    constructor(IERC20 _usdt, address _dao) {
        usdt = _usdt;
        dao = _dao;
        transferOwnership(dao);
    }

    function initialize() public onlyOwner {
        sponsorHandler = new SponsorHandler(this);
        treeHandler = new TreeHandler(this);
        donationHandler = new DonationHandler(this, treeHandler);
    }

    function deposit(uint256 _amount) public {
        usdt.transferFrom(msg.sender, address(this), _amount);
        users[msg.sender].balance += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function donate(address _sponsor) public {
        require(users[msg.sender].balance >= this.getNextStep(msg.sender).amount, "Insufficient balance for donation");
        require(_sponsor != msg.sender, "Cannot sponsor self");
        address actualSponsor = sponsorHandler.manageSponsor(msg.sender, _sponsor);

        donationHandler.distributeDonation(msg.sender, actualSponsor);
        createUser(msg.sender);
    }

    function transfer(address _to, uint256 _amount) public {
        require(users[msg.sender].balance >= _amount, "Insufficient balance for transfer");
        require(_to != msg.sender, "Cannot transfer to self");
        
        // Decrement sender's balance
        users[msg.sender].balance -= _amount;

        // Increment receiver's balance
        users[_to].balance += _amount;
        emit Transfer(msg.sender, _to, _amount);
    }
    
    function getNextStep(address _user) external view returns (StepData memory) {
        StepData memory nextStep = steps[users[_user].step + 1];
        if (nextStep.step <= steps.length) {
            return nextStep;
        }
        return steps[steps.length - 1];
    }

    function getUserStep(address _user) public view returns (StepData memory) {
        return steps[users[_user].step];
    }

    function getDao() external view returns (address){
        return dao;
    }

    function getUser(address _user) public view returns (User memory) {
        return users[_user];
    }

    function getTree(address _user) public view returns (TreeNode memory) {
        return treeHandler.getTreeNode(_user);
    }

    function createUser(address _user) private {
        users[_user].isUser = true;
    }

    function setUserStep(address _user, uint256 step) public OnlyKnownContract{
        users[_user].step = step;
    }

    function addUserBalance(address _user, uint256 _amount) public OnlyKnownContract {
        require(users[_user].isUser, "User does not exist");
        users[_user].balance += _amount;
    }

    function removeUserBalance(address _user, uint256 _amount) public OnlyKnownContract {
        require(users[_user].balance >= _amount, "Insufficient balance");
        users[_user].balance -= _amount;
    }

    function addSponsor(address _user, address sponsor) public OnlyKnownContract {
        users[_user].sponsor = sponsor;
    }

    function addDirectReferrals(address _user, address referral) public OnlyKnownContract {
        users[_user].directReferrals.push(referral);
    }

    // Function for genesis
    function completeGenesis() public onlyOwner {
        Genesis genesis = new Genesis();
        StepData[] memory stepsData = genesis.generateSteps();
        for (uint256 i = 0; i < stepsData.length; i++) {
            steps.push(stepsData[i]);
        }
    }

    function completeUser(address _me, uint256 _balance, address _sponsor) public onlyOwner {
        User storage user = users[_me];
        user.balance = _balance;
        // user.sponsor = _sponsor;
        user.isUser = true;
        address sponsorGot = sponsorHandler.manageSponsor(_me, _sponsor);
        treeHandler.addToTree(_me, sponsorGot);
    }
    
}
