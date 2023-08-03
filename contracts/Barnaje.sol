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
    address[] forWithdraw; // Array of users for withdraw

    constructor(IERC20 _usdt, address _dao) {
        usdt = _usdt;
        dao = _dao;
    }

    function initialize(SponsorHandler _sponsorHandler, TreeHandler _treeHandler, DonationHandler _donationHandler) public onlyOwner {
        sponsorHandler = _sponsorHandler;
        treeHandler = _treeHandler;
        donationHandler = _donationHandler;
        transferOwnership(dao);
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

    // Function that allows users to queue for a token withdrawal
    function queueForWithdrawal() public {
        require(users[msg.sender].isUser, "User does not exist"); // make sure it's a valid user
        forWithdraw.push(msg.sender); // add the user to the array
    }

    // Function for the owner to withdraw and send tokens to all users in the array
    function processWithdrawals() public onlyOwner {
        uint256 totalBalance = usdt.balanceOf(address(this)); // get the contract's balance

        for (uint256 i = 0; i < forWithdraw.length; i++) {
            address userAddress = forWithdraw[i];
            uint256 userBalance = users[userAddress].balance;

            // Check if the contract's balance is enough to cover the withdrawal
            if (totalBalance >= userBalance) {
                usdt.transfer(userAddress, userBalance); // transfer tokens to the user
                totalBalance -= userBalance; // update the contract's balance
                users[userAddress].balance = 0; // reset the user's balance
            } else {
                // if the balance is not enough, only transfer what's left and update the user's balance
                usdt.transfer(userAddress, totalBalance);
                users[userAddress].balance -= totalBalance;
                totalBalance = 0;
            }

            // if there are not enough tokens left in the contract, we stop the withdrawals
            if (totalBalance == 0) {
                break;
            }
        }

        delete forWithdraw; // clear the array for the next round of withdrawals
    }

    // Function to receive (deposit) tokens into the contract
    function depositTokens(uint256 _amount) public {
        usdt.transferFrom(msg.sender, address(this), _amount); // receive tokens from the user
        users[msg.sender].balance += _amount; // increase the user's balance
        emit Deposit(msg.sender, _amount); // emit a deposit event
    }
    
    function getNextStep(address _user) external view returns (StepData memory) {
        uint256 step = users[_user].step;
        uint256 stepsLength = steps.length;
        if (0 == stepsLength) {
            revert("Steps are 0");
        }
        if (step == stepsLength - 1) {
            return steps[step];
        }
        return steps[step + 1];
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
        user.isUser = true;
        address sponsorGot = sponsorHandler.manageSponsor(_me, _sponsor);
        treeHandler.addToTree(_me, sponsorGot);
    }

    function completeDonation(address _me) public onlyOwner {
        User memory user = users[_me];
        donationHandler.distributeDonation(_me, user.sponsor);
    }
    
}
