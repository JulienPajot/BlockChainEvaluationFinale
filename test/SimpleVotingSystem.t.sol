// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimplevotingSystem.sol";
import "../src/VotingNFT.sol";

contract SimpleVotingSystemTest is Test {
  SimpleVotingSystem public votingSystem;
  VotingNFT public votingNFT;
  address public constant OWNER = address(0x1234567890123456789012345678901234567890);
  address public voter1;
  address public voter2;
  address public voter3;

  event CandidateAdded(uint indexed candidateId, string name);
  event VoteCast(address indexed voter, uint indexed candidateId);

  function setUp() public {
    voter1 = makeAddr("voter1");
    voter2 = makeAddr("voter2");
    voter3 = makeAddr("voter3");

    // Créditer tous les comptes avec de l'ETH pour payer le gas des transactions
    vm.deal(OWNER, 100 ether);
    vm.deal(voter1, 10 ether);
    vm.deal(voter2, 10 ether);
    vm.deal(voter3, 10 ether);
    
    vm.startPrank(OWNER);
    VotingNFT _votingNFT = new VotingNFT();
    votingSystem = new SimpleVotingSystem(address(_votingNFT));
    _votingNFT.transferOwnership(address(votingSystem));
    votingNFT = _votingNFT;
    vm.stopPrank();
  }
  
  function startVote() internal {
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.warp(block.timestamp + 3600); // Simule 1h d’attente
}


  // ============ Tests pour Initialisation ============

  function test_Initialisation() public {
    assertEq(votingSystem.getCandidatesCount(), 0);
    assertEq(
    uint(votingSystem.currentStatus()),
    uint(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES)
);
  }


  // ============ Tests pour addCandidate ============

  function test_AddCandidate_AsOwner() public {
    string memory candidateName = "Alice";
    vm.startPrank(OWNER);
    votingSystem.addCandidate(candidateName,voter1);
    vm.stopPrank();

    assertEq(votingSystem.getCandidatesCount(), 1);
    SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
    assertEq(candidate.id, 1);
    assertEq(candidate.name, candidateName);
    assertEq(candidate.voteCount, 0);
  }

  function test_AddCandidate_MultipleCandidates() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    votingSystem.addCandidate("Charlie",voter3);
    vm.stopPrank();

    assertEq(votingSystem.getCandidatesCount(), 3);

    SimpleVotingSystem.Candidate memory candidate1 = votingSystem.getCandidate(1);
    assertEq(candidate1.name, "Alice");
    assertEq(candidate1.id, 1);

    SimpleVotingSystem.Candidate memory candidate2 = votingSystem.getCandidate(2);
    assertEq(candidate2.name, "Bob");
    assertEq(candidate2.id, 2);

    SimpleVotingSystem.Candidate memory candidate3 = votingSystem.getCandidate(3);
    assertEq(candidate3.name, "Charlie");
    assertEq(candidate3.id, 3);
  }

  function test_AddCandidate_OnlyOwner() public {
    vm.startPrank(voter1);
    vm.expectRevert();
    votingSystem.addCandidate("Unauthorized Candidate",voter1);
    vm.stopPrank();
  }

  function test_AddCandidate_EmptyName() public {
    vm.startPrank(OWNER);
    vm.expectRevert("Candidate name cannot be empty");
    votingSystem.addCandidate("",voter1);
    vm.stopPrank();
  }

  function test_AddCandidate_WithWhitespace() public {
    // Un nom avec seulement des espaces devrait être accepté (selon l'implémentation actuelle)
    // Mais testons avec un nom valide contenant des espaces
    vm.startPrank(OWNER);
    votingSystem.addCandidate("John Doe",voter1);
    vm.stopPrank();
    assertEq(votingSystem.getCandidatesCount(), 1);
    SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
    assertEq(candidate.name, "John Doe");
  }

  function test_AdminRole_CanAddCandidate() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();

    assertEq(votingSystem.getCandidatesCount(), 1);
  }

  function test_NonAdmin_CannotAddCandidate() public {
    vm.startPrank(voter1);
    vm.expectRevert();
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();
  }
  function test_AddCandidate_WrongWorkflow_Revert() public {
    vm.startPrank(OWNER);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.expectRevert("Candidate registration is not allowed at this stage");
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();
}


  // ============ Tests pour vote ============

  function test_Vote_ValidCandidate() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    assertTrue(votingSystem.voters(voter1));
    assertEq(votingSystem.getTotalVotes(1), 1);
    assertEq(votingSystem.getTotalVotes(2), 0);
  }

  function test_Vote_MultipleVoters() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    vm.startPrank(voter2);
    votingSystem.vote(1);
    vm.stopPrank();

    vm.startPrank(voter3);
    votingSystem.vote(2);
    vm.stopPrank();

    assertEq(votingSystem.getTotalVotes(1), 2);
    assertEq(votingSystem.getTotalVotes(2), 1);
    assertTrue(votingSystem.voters(voter1));
    assertTrue(votingSystem.voters(voter2));
    assertTrue(votingSystem.voters(voter3));
  }

  function test_Vote_DuplicateVote() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    vm.startPrank(voter1);
    vm.expectRevert("You have already voted");
    votingSystem.vote(1);
    vm.stopPrank();
  }

  function test_Vote_InvalidCandidateId_Zero() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    vm.expectRevert("Invalid candidate ID");
    votingSystem.vote(0);
    vm.stopPrank();
  }

  function test_Vote_InvalidCandidateId_TooHigh() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    vm.expectRevert("Invalid candidate ID");
    votingSystem.vote(2);
    vm.stopPrank();
  }

  function test_Vote_InvalidCandidateId_TooHigh_WithMultipleCandidates() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    vm.expectRevert("Invalid candidate ID");
    votingSystem.vote(3);
    vm.stopPrank();
  }

  function test_Vote_OwnerCanVote() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    vm.startPrank(OWNER);
    votingSystem.vote(1);
    vm.stopPrank();

    assertTrue(votingSystem.voters(OWNER));
    assertEq(votingSystem.getTotalVotes(1), 1);
  }
  function test_Vote_WrongWorkflow_Revert() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();

    vm.startPrank(voter1);
    vm.expectRevert("Voting is not allowed at this stage");
    votingSystem.vote(1);
    vm.stopPrank();
}

function test_Vote_BeforeAllowedTime_Revert() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    vm.startPrank(voter1);
    vm.expectRevert("Voting is not allowed at this stage");
    votingSystem.vote(1);
    vm.stopPrank();
}
function test_voteAfterAnHour_Success() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    vm.warp(block.timestamp + 1 hours + 1 seconds);

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    assertTrue(votingSystem.voters(voter1));
    assertEq(votingSystem.getTotalVotes(1), 1);
  
}

function test_Vote_AlreadyOwnsNFT_Revert() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice", voter1);
    startVote();
    vm.stopPrank();

    vm.startPrank(address(votingSystem));
    votingNFT.mint(voter1);
    vm.stopPrank();

    vm.startPrank(voter1);
    vm.expectRevert("Already owns a voting NFT");
    votingSystem.vote(1); 
    vm.stopPrank();
}
function test_VotingMintsNFT() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice", voter1);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();
    assertEq(votingNFT.balanceOf(voter1), 1);
}

  // ============ Tests pour getTotalVotes ============

  function test_GetTotalVotes_InitialState() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();

    assertEq(votingSystem.getTotalVotes(1), 0);
  }

  function test_GetTotalVotes_AfterVotes() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    vm.startPrank(voter2);
    votingSystem.vote(1);
    vm.stopPrank();

    vm.startPrank(voter3);
    votingSystem.vote(2);
    vm.stopPrank();

    assertEq(votingSystem.getTotalVotes(1), 2);
    assertEq(votingSystem.getTotalVotes(2), 1);
  }

  function test_GetTotalVotes_InvalidCandidateId_Zero() public {
    vm.expectRevert("Invalid candidate ID");
    votingSystem.getTotalVotes(0);
  }

  function test_GetTotalVotes_InvalidCandidateId_TooHigh() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();

    vm.expectRevert("Invalid candidate ID");
    votingSystem.getTotalVotes(2);
  }

  // ============ Tests pour getCandidatesCount ============

  function test_GetCandidatesCount_Initial() public view {
    assertEq(votingSystem.getCandidatesCount(), 0);
  }

  function test_GetCandidatesCount_AfterAdding() public {
    assertEq(votingSystem.getCandidatesCount(), 0);

    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();
    assertEq(votingSystem.getCandidatesCount(), 1);

    vm.startPrank(OWNER);
    votingSystem.addCandidate("Bob",voter2);
    vm.stopPrank();
    assertEq(votingSystem.getCandidatesCount(), 2);

    vm.startPrank(OWNER);
    votingSystem.addCandidate("Charlie",voter3);
    vm.stopPrank();
    assertEq(votingSystem.getCandidatesCount(), 3);
  }

  // ============ Tests pour getCandidate ============

  function test_GetCandidate_ValidId() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    vm.stopPrank();

    SimpleVotingSystem.Candidate memory candidate1 = votingSystem.getCandidate(1);
    assertEq(candidate1.id, 1);
    assertEq(candidate1.name, "Alice");
    assertEq(candidate1.voteCount, 0);

    SimpleVotingSystem.Candidate memory candidate2 = votingSystem.getCandidate(2);
    assertEq(candidate2.id, 2);
    assertEq(candidate2.name, "Bob");
    assertEq(candidate2.voteCount, 0);
  }

  function test_GetCandidate_WithVotes() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    vm.startPrank(voter2);
    votingSystem.vote(1);
    vm.stopPrank();

    SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
    assertEq(candidate.id, 1);
    assertEq(candidate.name, "Alice");
    assertEq(candidate.voteCount, 2);
  }

  function test_GetCandidate_InvalidId_Zero() public {
    vm.expectRevert("Invalid candidate ID");
    votingSystem.getCandidate(0);
  }

  function test_GetCandidate_InvalidId_TooHigh() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    vm.stopPrank();

    vm.expectRevert("Invalid candidate ID");
    votingSystem.getCandidate(2);
  }

  // ============ Tests de cas limites ============

  function test_CompleteVotingScenario() public {
    // Ajouter plusieurs candidats
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    votingSystem.addCandidate("Charlie",voter3);
    startVote();
    vm.stopPrank();

    // Plusieurs votants votent
    vm.startPrank(voter1);
    votingSystem.vote(1); // Alice
    vm.stopPrank();

    vm.startPrank(voter2);
    votingSystem.vote(1); // Alice
    vm.stopPrank();

    vm.startPrank(voter3);
    votingSystem.vote(2); // Bob
    vm.stopPrank();

    // Vérifier les résultats
    assertEq(votingSystem.getTotalVotes(1), 2); // Alice
    assertEq(votingSystem.getTotalVotes(2), 1); // Bob
    assertEq(votingSystem.getTotalVotes(3), 0); // Charlie

    // Vérifier que tous ont voté
    assertTrue(votingSystem.voters(voter1));
    assertTrue(votingSystem.voters(voter2));
    assertTrue(votingSystem.voters(voter3));

    // Vérifier les détails des candidats
    SimpleVotingSystem.Candidate memory alice = votingSystem.getCandidate(1);
    assertEq(alice.voteCount, 2);

    SimpleVotingSystem.Candidate memory bob = votingSystem.getCandidate(2);
    assertEq(bob.voteCount, 1);

    SimpleVotingSystem.Candidate memory charlie = votingSystem.getCandidate(3);
    assertEq(charlie.voteCount, 0);
  }

  function test_VoteCount_IncrementsCorrectly() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    // Voter plusieurs fois avec différents votants
    for (uint i = 0; i < 10; i++) {
      address voter = makeAddr(string(abi.encodePacked("voter", i)));
      vm.deal(voter, 1 ether);
      vm.startPrank(voter);
      votingSystem.vote(1);
      vm.stopPrank();
    }

    assertEq(votingSystem.getTotalVotes(1), 10);
  }



  // ============ Tests de fuzzing ============

  function testFuzz_AddCandidate(string memory _name) public {
    // Filtrer les noms vides
    vm.assume(bytes(_name).length > 0);

    vm.startPrank(OWNER);
    votingSystem.addCandidate(_name,voter1);
    vm.stopPrank();

    assertEq(votingSystem.getCandidatesCount(), 1);
    SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
    assertEq(candidate.name, _name);
    assertEq(candidate.voteCount, 0);
  }

  function testFuzz_Vote_ValidCandidateId(uint8 _candidateId) public {
    // Créer plusieurs candidats
    uint8 numCandidates = 10;
    vm.startPrank(OWNER);
    for (uint8 i = 1; i <= numCandidates; i++) {
      votingSystem.addCandidate(string(abi.encodePacked("Candidate", i)),voter1);
    }
    startVote();
    vm.stopPrank();

    // Borner l'ID du candidat à une plage valide
    _candidateId = uint8(bound(_candidateId, 1, numCandidates));

    address voter = makeAddr("fuzzVoter");
    vm.deal(voter, 1 ether);
    vm.startPrank(voter);
    votingSystem.vote(_candidateId);
    vm.stopPrank();

    assertTrue(votingSystem.voters(voter));
    assertEq(votingSystem.getTotalVotes(_candidateId), 1);
  }

  function testFuzz_MultipleVotes(uint8 _numVotes) public {
    // Limiter le nombre de votes pour éviter les problèmes de gas
    _numVotes = uint8(bound(_numVotes, 1, 50));

    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    // Créer plusieurs votants et faire voter chacun une fois
    for (uint8 i = 0; i < _numVotes; i++) {
      address voter = makeAddr(string(abi.encodePacked("voter", i)));
      vm.deal(voter, 1 ether);
      vm.startPrank(voter);
      votingSystem.vote(1);
      vm.stopPrank();
    }

    assertEq(votingSystem.getTotalVotes(1), _numVotes);
  }

  // ============ Tests de mapping public ============

  function test_CandidatesMapping_Public() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    votingSystem.addCandidate("Bob",voter2);
    vm.stopPrank();

    (uint id1, string memory name1, uint voteCount1,address owner1) = votingSystem.candidates(1);
    assertEq(id1, 1);
    assertEq(name1, "Alice");
    assertEq(voteCount1, 0);
    assertEq(owner1, voter1);

    (uint id2, string memory name2, uint voteCount2,address owner2) = votingSystem.candidates(2);
    assertEq(id2, 2);
    assertEq(name2, "Bob");
    assertEq(voteCount2, 0);
    assertEq(owner2, voter2);
  }

  function test_VotersMapping_Public() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice",voter1);
    startVote();
    vm.stopPrank();

    assertFalse(votingSystem.voters(voter1));

    vm.startPrank(voter1);
    votingSystem.vote(1);
    vm.stopPrank();

    assertTrue(votingSystem.voters(voter1));
    assertFalse(votingSystem.voters(voter2));
  }

  // ============ Tests pour setWorkflowStatus ============
  function test_SetWorkflowStatus_AsOwner() public {
    vm.startPrank(OWNER);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();

    assertEq(
    uint(votingSystem.currentStatus()),
    uint(SimpleVotingSystem.WorkflowStatus.VOTE)
    );
  }
  function test_NonAdminCannotChangeWorkflow() public {
    vm.startPrank(voter1);
    vm.expectRevert();
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    vm.stopPrank();
  }

  // ============ Tests pour fundCandidate ============
  function test_FounderCanFundCandidate() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice", voter1);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
    vm.stopPrank();

    uint amount = 1 ether;
    vm.startPrank(OWNER); 
    votingSystem.fundCandidate{value: amount}(1);
    vm.stopPrank();
    assertEq(voter1.balance, 10 ether + amount); 
  }
  function test_NonFounderCannotFundCandidate() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice", voter1);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
    vm.stopPrank();

    uint amount = 1 ether;

    vm.startPrank(voter2);
    vm.expectRevert();
    votingSystem.fundCandidate{value: amount}(1);
    vm.stopPrank();
  }

  function test_FundCandidate_ZeroValueRevert() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice", voter1);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
    vm.stopPrank();

    vm.startPrank(OWNER);
    vm.expectRevert("No funds sent");
    votingSystem.fundCandidate{value: 0}(1);
    vm.stopPrank();
  }


// ============ Tests pour getWinner ============
function test_GetWinner_AfterCompletion() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice", voter1);
    votingSystem.addCandidate("Bob", voter2);
    startVote();
    vm.stopPrank();

    vm.startPrank(voter1);
    votingSystem.vote(1); 
    vm.stopPrank();

    vm.startPrank(voter2);
    votingSystem.vote(2); 
    vm.stopPrank();

    vm.startPrank(voter3);
    votingSystem.vote(1); 
    vm.stopPrank();

    vm.startPrank(OWNER);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);
    vm.stopPrank();

    SimpleVotingSystem.Candidate memory winner = votingSystem.getWinner();
    assertEq(winner.id, 1);        
    assertEq(winner.name, "Alice");
    assertEq(winner.voteCount, 2);
}

// ============ Tests pour withdrawFunds ============
function test_WithdrawerCanWithdrawAfterCompletion() public {
    vm.startPrank(OWNER);
    votingSystem.addCandidate("Alice", voter1);
    votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);
    vm.stopPrank();

    vm.deal(OWNER, 1 ether);
    vm.startPrank(OWNER);
    payable(address(votingSystem)).transfer(1 ether);
    vm.stopPrank();
    uint initialBalance = address(OWNER).balance;

    vm.startPrank(OWNER); // owner a tous les rôles
    votingSystem.withdrawFunds(payable(OWNER), 1 ether);
    vm.stopPrank();

    assertEq(address(OWNER).balance, initialBalance + 1 ether);
}

function test_NonWithdrawerCannotWithdraw() public {
    address nonWithdrawer = voter1;

    vm.startPrank(nonWithdrawer);
    vm.expectRevert();
    votingSystem.withdrawFunds(payable(nonWithdrawer), 1 ether);
    vm.stopPrank();
}

function test_WithdrawBeforeCompletionReverts() public {
    address withdrawer = OWNER; 

    vm.startPrank(withdrawer);
    vm.expectRevert("Funds can only be withdrawn after completion");
    votingSystem.withdrawFunds(payable(withdrawer), 1 ether);
    vm.stopPrank();
}
}
