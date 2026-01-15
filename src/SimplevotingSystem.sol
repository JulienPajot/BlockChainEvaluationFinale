// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem  is AccessControl {
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        address wallet;
    }

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }
    WorkflowStatus public currentStatus;
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(FOUNDER_ROLE, msg.sender);

        currentStatus = WorkflowStatus.REGISTER_CANDIDATES;
    }

    function addCandidate(string memory _name, address _wallet) external onlyRole(ADMIN_ROLE) {
        require (currentStatus == WorkflowStatus.REGISTER_CANDIDATES, "Candidate registration is not allowed at this stage");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0,_wallet);
        candidateIds.push(candidateId);
    }

    function vote(uint _candidateId) public {
        require(currentStatus == WorkflowStatus.VOTE, "Voting is not allowed at this stage");
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    // Optional: Function to get candidate details by ID
    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }

    function setWorkflowStatus(WorkflowStatus _status) external onlyRole(ADMIN_ROLE) {
        currentStatus = _status;
    }

    function fundCandidate(uint _candidateId) external payable onlyRole(FOUNDER_ROLE) {
        require(currentStatus == WorkflowStatus.FOUND_CANDIDATES, "Funding is not allowed at this stage");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(msg.value > 0, "No funds sent");
        
        address candidateAddress = candidates[_candidateId].wallet; 
        payable(candidateAddress).transfer(msg.value);
    }
}