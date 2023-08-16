// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Genesis.sol";
import "./SponsorHandler.sol";
import "./TreeHandler.sol";
import "./DonationHandler.sol";

import "./model/StepData.sol";
import "./model/TreeNode.sol";
import "./model/Floor.sol";
import "./model/User.sol";

contract Barnaje is Ownable, ReentrancyGuard{

    event Deposit(address indexed donor, uint256 amount);
    event Transfer(address indexed from, address to, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier OnlyKnownContract {
        require(msg.sender == address(donationHandler) || msg.sender == address(sponsorHandler), "Unknown contract");
        _;
    }

    modifier onlyInFirst24Hours() {
        require(block.timestamp <= deploymentTime + 1 days, "This function can only be called within the first 24 hours after deployment");
        _;
    }

    modifier donationAllowModification() {
        require(!donationHasModification, "Donation is not allowed to be modified");
        _;
    }

    IERC20 private usdt;  // USDT token contract interface
    DonationHandler public  donationHandler; // Donation handler contract interface
    SponsorHandler public sponsorHandler; // Manager sponsor contract interface
    TreeHandler public treeHandler; // Manager sponsor contract interface


    mapping(address => User) private users;
    
    StepData[] private steps; // Steps and floor
    address[] private usersAvailable; // Users available for spread profits
    address private dao;  // DAO address
    uint256 private userCount; // Total number of users
    uint256 private amountWithdrawn; // Total amount withdrawn
    uint256 private amountDonation; // Total amount donated
    
    uint256 public deploymentTime; // Contract deployment time
    bool private hasGenesis; // Flag to check if the contract is initialized
    bool private isPreLaunch; // Flag to check if the contract is pre launch
    bool private donationHasModification; // Flag to check if the contract is pre launch

    uint256 private constant DECIMALS = 1e6;
    uint256 private constant MAX_AMOUNT_IN_PRELAUNCH = 6050 * DECIMALS;

    constructor(IERC20 _usdt) {
        usdt = _usdt;
        deploymentTime = block.timestamp;
    }

    function initialize(SponsorHandler _sponsorHandler, TreeHandler _treeHandler, DonationHandler _donationHandler, address _dao) public onlyOwner {
        sponsorHandler = _sponsorHandler;
        treeHandler = _treeHandler;
        donationHandler = _donationHandler;
        dao = _dao;
    }

    function deposit(uint256 _amount) public nonReentrant {
        require(!isPreLaunch || _amount == MAX_AMOUNT_IN_PRELAUNCH, "Amount exceeds maximum amount in prelaunch");
        usdt.transferFrom(msg.sender, address(this), _amount);
        users[msg.sender].balance += _amount;
        users[msg.sender].amountDeposit += _amount;
        emit Deposit(msg.sender, _amount);
    }

    // Function to receive (deposit) tokens into the contract
    function depositTokens(uint256 _amount) public {
        usdt.transferFrom(msg.sender, address(this), _amount); // receive tokens from the user
        emit Deposit(msg.sender, _amount); // emit a deposit event
    }

    function donate(address _sponsor) public nonReentrant {
        require(getUserBalance(msg.sender) >= this.getNextStep(msg.sender).amount, "Insufficient balance for donation");
        require(_sponsor != msg.sender, "Cannot sponsor self");
        address actualSponsor = sponsorHandler.manageSponsor(msg.sender, _sponsor);

        donationHandler.distributeDonation(msg.sender, actualSponsor);
        createUser(msg.sender);
    }

    function transfer(address _to, uint256 _amount) public nonReentrant {
        require(!isPreLaunch || _amount == MAX_AMOUNT_IN_PRELAUNCH, "Amount exceeds maximum amount in prelaunch");
        require(getUserBalance(msg.sender) >= _amount, "Insufficient balance for transfer");
        require(_to != msg.sender, "Cannot transfer to self");
        
        // Decrement sender's balance
        removeUserBalance(msg.sender, _amount);
        users[msg.sender].amountTransferSent += _amount;

        // Increment receiver's balance
        users[_to].balance += _amount;
        users[_to].amountTransferReceived += _amount;
        emit Transfer(msg.sender, _to, _amount);
    }

    // Function to withdraw tokens from the contract
    function withdrawal(uint256 amount) public nonReentrant {
        uint256 totalBalance = usdt.balanceOf(address(this)); // get the contract's balance
        uint256 userBalance = users[msg.sender].balanceAvailable;

        require(totalBalance >= amount, "Insufficient balance for withdrawal in contract");
        require(userBalance >= amount, "Insufficient balance for withdrawal");

        // Decrement sender's balance
        users[msg.sender].balanceAvailable -= amount;
        users[msg.sender].amountWithdrawn += amount;
        amountWithdrawn += amount;
        usdt.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
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
        users[_user].countDonations = 0;
    }

    function getUserBalance(address _user) public view returns (uint256) {
        return users[_user].balance + users[_user].balanceAvailable;
    }

    function addUserBalance(address _user, uint256 _amount, bool isDonationStep) public OnlyKnownContract {
        require(users[_user].isUser, "User does not exist");
        users[_user].balanceAvailable += _amount;
        if(isDonationStep){
            users[_user].countDonations += 1;
        }
        amountDonation += _amount;
    }

    function removeUserBalance(address _user, uint256 _amount) public OnlyKnownContract {
        uint256 balance = getUserBalance(_user);
        require(balance >= _amount, "Insufficient balance");

        // Si el balance es suficiente para cubrir el _amount
        if (users[_user].balance >= _amount) {
            users[_user].balance -= _amount;
        } else {
            // Si el balance no es suficiente, primero usamos lo que queda en balance
            uint256 remaining = _amount - users[_user].balance; 
            users[_user].balance = 0; // vaciamos el balance

            // Luego deducimos la cantidad restante del balanceAvailable
            require(users[_user].balanceAvailable >= remaining, "Insufficient available balance");
            users[_user].balanceAvailable -= remaining;
        }
    }

    function addSponsor(address _user, address sponsor) public OnlyKnownContract {
        users[_user].sponsor = sponsor;
    }

    function addDirectReferrals(address _user, address referral) public OnlyKnownContract {
        users[_user].directReferrals.push(referral);
    }

    function newUser() public OnlyKnownContract {
        userCount += 1;
    }

    function getUserCount() public view returns (uint256) {
        return userCount;
    }

    function enableUserToDistributeProfit(address _user) public OnlyKnownContract {
        usersAvailable.push(_user);
    }

    function getUsersAvailable() public view returns (address[] memory) {
        return usersAvailable;
    }

    function getAmountWithdrawn() public view returns (uint256) {
        return amountWithdrawn;
    }

    function getAmountDonation() public view returns (uint256) {
        return amountDonation;
    }

    // Function only for genesis before launch (24 hours)
    function completeGenesis() public onlyOwner onlyInFirst24Hours {
        Genesis genesis = new Genesis();
        StepData[] memory stepsData = genesis.generateSteps();
        for (uint256 i = 0; i < stepsData.length; i++) {
            steps.push(stepsData[i]);
        }
    }

    function completeUser(address _me, uint256 _balance, address _sponsor, address _partner, address _leftChild, address _rightChild) public onlyOwner onlyInFirst24Hours {
        require(_me != address(0), "User wallet cannot be 0x0");
        require(_sponsor != address(0) || _me == dao, "Sponsor wallet cannot be 0x0");
        require(_partner != address(0) || _me == dao, "Partner wallet cannot be 0x0");
        User storage user = users[_me];
        user.balance = _balance;
        user.isUser = true;
        users[_me].sponsor = _sponsor;
        treeHandler.pushToTreeManually(_me, _partner, _leftChild, _rightChild);
    }

    function completeDonation(address _me) public onlyOwner onlyInFirst24Hours {
        User memory user = users[_me];
        donationHandler.distributeDonation(_me, user.sponsor);
    }

    function renounceOwnershipToDao() public onlyOwner {
        transferOwnership(dao);
    }

    function setNewDonationRule(address _donationHandler) public onlyOwner donationAllowModification {
        donationHandler = DonationHandler(_donationHandler);
        donationHasModification = true;
    }
    
}
