// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FomoFaucet} from "../src/FomoFaucet.sol";

contract FomoFaucetTest is Test {
    FomoFaucet public faucet;
    uint256 scale = 1e18;
    uint256 SECONDS_PER_DAY = 86400;

    address public constant OWNER = address(0xABCD);
    address public constant SENDER = address(0xCAFE);
    address public constant ALICE = address(0x1111);

    function setUp() public {
        vm.prank(OWNER);

        uint256 baseRate = scale / (SECONDS_PER_DAY * 7);
        uint256 claimRate = 200000000000000000;
        uint256 minClaim = 10000000000000000;
        vm.warp(1704067200);
        faucet = new FomoFaucet(baseRate, claimRate, minClaim);

        vm.deal(address(faucet), 100 ether);

        vm.warp(block.timestamp + 1 hours);
    }

    function test_revertDeployBaseRate() public {
        uint256 claimRate = 200000000000000000;
        uint256 minClaim = 10000000000000000;

        vm.expectRevert();
        FomoFaucet faucet2 = new FomoFaucet(0, claimRate, minClaim);
    }

    function test_revertDeployClaimRate() public {
        uint256 baseRate = scale / (SECONDS_PER_DAY * 7);
        uint256 minClaim = 10000000000000000;

        vm.expectRevert();
        FomoFaucet faucet2 = new FomoFaucet(baseRate, 0, minClaim);
    }

    function test_revertDeployMinClaim() public {
        uint256 baseRate = scale / (SECONDS_PER_DAY * 7);
        uint256 claimRate = 200000000000000000;

        vm.expectRevert();
        FomoFaucet faucet2 = new FomoFaucet(baseRate, claimRate, 0);
    }

    function test_canClaimFunds() public {
        vm.prank(SENDER);
        faucet.claim();
        assertGt(SENDER.balance, 0);
    }

    function test_revertMultiDayClaim() public {
        uint256 timeNow = block.timestamp;
        vm.startPrank(SENDER);
        faucet.claim();
        vm.warp(timeNow + 1 hours);

        vm.expectRevert();
        faucet.claim();
    }

    function test_claimDaily() public {
        uint256 timeNow = block.timestamp;
        vm.startPrank(SENDER);
        faucet.claim();

        vm.warp(timeNow + 1 days);
        faucet.claim();
    }

    function test_claimAmount() public {
        vm.prank(SENDER);
        faucet.claim();

        uint256 sClaim = SENDER.balance;

        vm.warp(block.timestamp + 30 minutes);
        vm.prank(ALICE);
        faucet.claim();

        uint256 aClaim = ALICE.balance;

        assertNotEq(sClaim, aClaim);
    }

    function test_revertLowClaim() public {
        vm.prank(ALICE);
        faucet.claim();

        vm.warp(block.timestamp + 1 seconds);
        vm.prank(SENDER);
        vm.expectRevert();

        faucet.claim();
    }

    function test_finalSweep() public {
        vm.warp(block.timestamp + 6 days + 22 hours + 59 minutes + 10 seconds);
        uint256 claimAmount = faucet.calculateClaim();
        uint256 balance = address(faucet).balance;

        vm.prank(SENDER);
        faucet.claim();

        uint256 remainder = balance - claimAmount;

        vm.warp(block.timestamp + 1 seconds);
        vm.prank(ALICE);
        faucet.claim();

        assertEq(ALICE.balance, remainder);
    }

    function test_revertBaseRate() public {
        vm.expectRevert();

        vm.prank(OWNER);
        faucet.updateBaseRate(0);
    }

    function test_revertUpdateMinClaimAmount() public {
        vm.expectRevert();

        vm.prank(OWNER);
        faucet.updateBaseRate(0);
    }

    function test_revertSlowDownPerClaim() public {
        vm.expectRevert();

        vm.prank(OWNER);
        faucet.updateSlowDownPerClaim(0);
    }
}
