//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Box} from "../src/Box.sol";
import {BoxGovernor} from "../src/BoxGovernor.sol";
import {BoxGovToken} from "../src/BoxGovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract BoxGoveranceTest is Test {
    Box box;
    BoxGovernor boxGovernor;
    BoxGovToken boxGovToken;
    TimeLock timeLock;
    address USER = makeAddr("USER");
    uint256 AMOUNT = 100e18;
    uint256 TIMELOCK_DELAY = 3600; // 1hour
    uint256 VOTING_DELAY = 1; // how many blocks to wait before voting
    uint256 VOTING_PERIOD = 50400;
    uint256 VOTING_DELAY_DAY = 7200;
    address[] proposer;
    address[] executor;

    bytes[] calldatas;
    address[] targets;
    uint256[] values;

    function setUp() public {
        boxGovToken = new BoxGovToken();
        boxGovToken.mint(USER, AMOUNT);
        vm.prank(USER);
        boxGovToken.delegate(USER);
        vm.startPrank(USER);
        timeLock = new TimeLock(TIMELOCK_DELAY, proposer, executor);
        boxGovernor = new BoxGovernor(boxGovToken, timeLock);
        bytes32 properRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();
        timeLock.grantRole(properRole, address(boxGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timeLock));
    }

    function testBoxCantUpdateWithoutGovernace() public {
        vm.expectRevert();
        box.set(2);
    }

    function testGovernance() public {
        uint256 updateValue = 111;
        string memory description = "update value of the box by 111";
        bytes memory data = abi.encodeWithSignature("set(uint256)", updateValue);
        values.push(0);
        targets.push(address(box));
        calldatas.push(data);
        // propose
        uint256 proposerId = boxGovernor.propose(targets, values, calldatas, description);
        console.log("Proper state:", uint256(boxGovernor.state(proposerId)));
        vm.warp(block.timestamp + VOTING_DELAY_DAY + 1);
        vm.roll(block.number + VOTING_DELAY_DAY + 1);
        console.log("Propsal state:", uint256(boxGovernor.state(proposerId)));
        //vote
        string memory reason = "Change is good";
        uint8 votingWay = 1; // For yes
        vm.prank(USER);
        boxGovernor.castVoteWithReason(proposerId, votingWay, reason);
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        //Queue the txn
        console.log("Propsal state:", uint256(boxGovernor.state(proposerId)));
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        boxGovernor.queue(targets, values, calldatas, descriptionHash);
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.roll(block.number + TIMELOCK_DELAY + 1);
        //Execute
        boxGovernor.execute(targets, values, calldatas, descriptionHash);
        //Assert
        assertEq(box.value(), updateValue);
    }
}
