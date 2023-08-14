// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProposalGovernance.sol";
import "./IBarnajeSpreadProfits.sol";

contract DAOWallet {
    ProposalGovernance public governanceContract;
    address public barnajeSpreadProfits;
    mapping(address => bool) public owners;

    event OwnerAdded(address newOwner);
    event OwnerRemoved(address exOwner);
    
    modifier onlyOwners() {
        require(owners[msg.sender], "Only owners can call this");
        _;
    }
    
    constructor(address _governanceContract, address _barnajeSpreadProfits) {
        governanceContract = new ProposalGovernance(_governanceContract);
        barnajeSpreadProfits = _barnajeSpreadProfits;
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
    
    function executeChangeContractProposal(uint256 proposalId) external onlyOwners {
        require(governanceContract.isProposalApproved(proposalId), "Proposal not approved or already executed");
        
        (, address newContract, , , , ,) = governanceContract.proposals(proposalId);
        barnajeSpreadProfits = newContract;
        
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
    
    function run() external onlyOwners {
        IBarnajeSpreadProfits(barnajeSpreadProfits).spreadProfits();
    }
}

