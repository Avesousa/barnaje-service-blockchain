// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalGovernance {
    enum ProposalType { ChangeContract, AddOwner, RemoveOwner, SpreadProfits, ChangeWalletToCollect }
    
    struct Proposal {
        ProposalType proposalType;
        address proposedData;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool approved;
    }
    
    Proposal[] public proposals;
    
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposedData);
    event ProposalApproved(uint256 proposalId);
    
    address public DAOWallet;
    
    modifier onlyDAOWallet() {
        require(msg.sender == DAOWallet, "Only DAOWallet can call this");
        _;
    }
    
    constructor(address _DAOWallet) {
        DAOWallet = _DAOWallet;
    }
    
    function propose(ProposalType proposalType, address proposedData) external onlyDAOWallet returns (uint256) {
        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            proposalType: proposalType,
            proposedData: proposedData,
            endTime: block.timestamp + 3 days,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            approved: false
        }));

        emit ProposalCreated(proposalId, proposalType, proposedData);
        return proposalId;
    }
    
    function vote(uint256 proposalId, bool inFavor) external onlyDAOWallet {
        require(proposals[proposalId].endTime > block.timestamp, "Voting period has ended");
        require(!proposals[proposalId].executed, "Proposal already executed");
        
        // Logic for voting, for simplicity we're not tracking individual votes in this example.
        if (inFavor) {
            proposals[proposalId].forVotes += 1;
        } else {
            proposals[proposalId].againstVotes += 1;
        }

        if (proposals[proposalId].forVotes > proposals[proposalId].againstVotes) {
            proposals[proposalId].approved = true;
            emit ProposalApproved(proposalId);
        }
    }
    
    function isProposalApproved(uint256 proposalId) external view returns (bool) {
        return proposals[proposalId].approved && !proposals[proposalId].executed;
    }
    
    function executeProposal(uint256 proposalId) external onlyDAOWallet {
        require(proposals[proposalId].approved, "Proposal not approved");
        require(!proposals[proposalId].executed, "Proposal already executed");
        
        proposals[proposalId].executed = true;
    }
}
