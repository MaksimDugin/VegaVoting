// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VVToken} from "../src/VVToken.sol";
import {VoteResultNFT} from "../src/VoteResultNFT.sol";
import {Voting} from "../src/Voting.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingTest is Test {
    using SafeERC20 for IERC20;
    VVToken token;
    VoteResultNFT nft;
    Voting voting;

    address owner = address(0xA11CE);
    address alice = address(0xB0B);
    address bob = address(0xCAFE);

    function setUp() public {
        vm.prank(owner);
        token = new VVToken(owner, 1_000_000 ether);

        vm.prank(owner);
        nft = new VoteResultNFT(owner);

        vm.prank(owner);
        voting = new Voting(owner, token, nft);

        vm.prank(owner);
        nft.setMinter(address(voting));

        vm.prank(owner);
        IERC20(address(token)).safeTransfer(alice, 1_000 ether);

        vm.prank(owner);
        IERC20(address(token)).safeTransfer(bob, 1_000 ether);
    }

    function testCreateVoteOnlyOwner() public {
        bytes32 voteId = keccak256("vote-1");

        vm.prank(alice);
        vm.expectRevert();
        voting.createVote(voteId, uint64(block.timestamp + 1 days), 100 ether, "Question");

        vm.prank(owner);
        voting.createVote(voteId, uint64(block.timestamp + 1 days), 100 ether, "Question");
    }

    function testStakeVoteAndFinalizeEarly() public {
        bytes32 voteId = keccak256("vote-2");

        vm.prank(owner);
        voting.createVote(voteId, uint64(block.timestamp + 1 days), 1_500 ether, "Pass with yes threshold");

        vm.startPrank(alice);
        token.approve(address(voting), 100 ether);
        voting.stake(100 ether, 4);
        voting.vote(voteId, true);
        vm.stopPrank();

        (, , , , uint256 yesVotes, , bool finalized, bool passed, ) = voting.getVote(voteId);
        assertTrue(finalized);
        assertTrue(passed);
        assertGt(yesVotes, 0);

        uint256 tokenId = uint256(voteId);
        VoteResultNFT.ResultData memory result = nft.resultOf(tokenId);
        assertEq(result.yesVotes, yesVotes);
        assertTrue(result.passed);
    }

    function testVoteByTwoAddresses() public {
        bytes32 voteId = keccak256("vote-3");

        vm.prank(owner);
        voting.createVote(voteId, uint64(block.timestamp + 1 days), 3_200 ether, "Two-address demo");

        vm.startPrank(alice);
        token.approve(address(voting), 100 ether);
        voting.stake(100 ether, 4);
        voting.vote(voteId, true);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(voting), 100 ether);
        voting.stake(100 ether, 4);
        voting.vote(voteId, true);
        vm.stopPrank();

        (, , , , uint256 yesVotes, uint256 noVotes, bool finalized, bool passed, ) = voting.getVote(voteId);
        assertTrue(finalized);
        assertTrue(passed);
        assertEq(noVotes, 0);
        assertGt(yesVotes, 0);
    }

    function testWithdrawAfterUnlock() public {
        vm.startPrank(alice);
        token.approve(address(voting), 100 ether);
        uint256 stakeId = voting.stake(100 ether, 1);
        vm.stopPrank();

        vm.expectRevert();
        vm.prank(alice);
        voting.withdraw(stakeId);

        vm.warp(block.timestamp + 1 days + 1);

        uint256 balanceBefore = token.balanceOf(alice);
        vm.prank(alice);
        voting.withdraw(stakeId);
        uint256 balanceAfter = token.balanceOf(alice);

        assertEq(balanceAfter, balanceBefore + 100 ether);
    }
}
