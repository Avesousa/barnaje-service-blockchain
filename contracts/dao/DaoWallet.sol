// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ProposalGovernance.sol";
import "./SpreadProfits.sol";
import "../Barnaje.sol";

contract DaoWallet is ReentrancyGuard{
    ProposalGovernance public governanceContract;
    SpreadProfits public dealer;
    Barnaje public barnaje;
    IERC20 public usdt;
    mapping(address => bool) public owners;

    event OwnerAdded(address newOwner);
    event OwnerRemoved(address exOwner);
    event SpreadProfitsExecuted();
    
    modifier onlyOwners() {
        require(owners[msg.sender], "Only owners can call this");
        _;
    }
    
    constructor(address _usdt, address _barnaje) {
        governanceContract = new ProposalGovernance(address(this));
        barnaje = Barnaje(_barnaje);
        dealer = new SpreadProfits(msg.sender, address(this), _usdt);
        usdt = IERC20(_usdt);
        owners[msg.sender] = true;
    }
    
    function setBarnajeSpreadProfits(address newContract) external onlyOwners {
        governanceContract.propose(ProposalGovernance.ProposalType.ChangeContract, newContract);
    }
     
    function addOwner(address newOwner) external onlyOwners {
        governanceContract.propose(ProposalGovernance.ProposalType.AddOwner, newOwner);
    }
    
    function removeOwner(address ownerToRemove) external onlyOwners {
        governanceContract.propose(ProposalGovernance.ProposalType.RemoveOwner, ownerToRemove);
    }

    function spreadProfits() external onlyOwners {
        governanceContract.propose(ProposalGovernance.ProposalType.SpreadProfits, dealer.getWalletToCollect());
    }

    function changeWalletToCollect(address newWallet) external onlyOwners {
        require(owners[newWallet], "New wallet must be an owner");
        governanceContract.propose(ProposalGovernance.ProposalType.ChangeWalletToCollect, newWallet);
    }

    function vote(uint256 proposalId, bool inFavor) external onlyOwners {
        governanceContract.vote(proposalId, inFavor);
    }

    function transfer() private {
        uint256 amount = usdt.balanceOf(address(this));
        require(amount > 0, "No funds in DAO Wallet");
        usdt.transfer(address(dealer), amount);
    }

    function withdrawal() public nonReentrant onlyOwners {
        uint256 amount = barnaje.getUser(address(this)).balanceAvailable;
        barnaje.withdrawal(amount);
    }

    function getBarnaje() public view returns (Barnaje) {
        return barnaje;
    }
    
    function executeChangeContractProposal(uint256 proposalId) external onlyOwners {
        require(governanceContract.isProposalApproved(proposalId), "Proposal not approved or already executed");
        
        (, address newContract, , , , ,) = governanceContract.proposals(proposalId);
        dealer = SpreadProfits(newContract);
        
        governanceContract.executeProposal(proposalId);
    }

    function executeAddOwnerProposal(uint256 proposalId) external onlyOwners {
        require(governanceContract.isProposalApproved(proposalId), "Proposal not approved or already executed");
        
        (, address newOwner, , , , ,) = governanceContract.proposals(proposalId);
        owners[newOwner] = true;
        
        emit OwnerAdded(newOwner);
        
        governanceContract.executeProposal(proposalId);
    }

    function executeRemoveOwnerProposal(uint256 proposalId) external onlyOwners {
        require(governanceContract.isProposalApproved(proposalId), "Proposal not approved or already executed");
        
        (, address ownerToRemove, , , , ,) = governanceContract.proposals(proposalId);
        owners[ownerToRemove] = false;
         
        emit OwnerRemoved(ownerToRemove);
        
        governanceContract.executeProposal(proposalId);
    }

    function executeSpreadProfitsProposal(uint256 proposalId) external nonReentrant onlyOwners {
        require(governanceContract.isProposalApproved(proposalId), "Proposal not approved or already executed");
        transfer();
        dealer.spreadProfits();
        emit SpreadProfitsExecuted();
        governanceContract.executeProposal(proposalId);
    }

    function executeChangeWalletToCollectProposal(uint256 proposalId) external onlyOwners {
        require(governanceContract.isProposalApproved(proposalId), "Proposal not approved or already executed");
        
        (, address walletToCollect, , , , ,) = governanceContract.proposals(proposalId);
        dealer.changeWalletToCollect(walletToCollect);
        governanceContract.executeProposal(proposalId);
    }
}

