// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployFunderContract} from "../../script/DeployFunderContract.s.sol";
import {FunderContract} from "../../src/FunderContract.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract TestFunderContract is Test {
    FunderContract private s_funderContract;
    HelperConfig private s_helperConfig;
    LinkTokenInterface private s_linkInterface;

    address private s_testerAddress = makeAddr("selone");
    address private s_linkAddress;
    address private constant REAL_ADD = address(0); // My real address here
    uint256 private constant TESTER_BALANCE = 10e18;
    uint private constant SEND_VALUE = 1e18;

    function setUp() external {
        DeployFunderContract deployFunderContract = new DeployFunderContract();
        (s_funderContract, s_helperConfig, s_linkAddress) = deployFunderContract
            .run();
        s_linkInterface = LinkTokenInterface(s_linkAddress);

        vm.deal(s_testerAddress, TESTER_BALANCE);
    }

    modifier addFunder() {
        vm.prank(msg.sender);
        vm.deal(msg.sender, 10e18);
        _;
    }

    function testFundContractPass() external addFunder {
        s_funderContract.fundContract{value: SEND_VALUE}();
        uint256 funderContractBalance = address(s_funderContract).balance;
        assert(funderContractBalance == SEND_VALUE);
    }

    function testFundContractFailedWithWrongMsgSender() external {
        vm.prank(s_testerAddress);
        vm.expectRevert();
        s_funderContract.fundContract{value: SEND_VALUE}();
    }

    function testFundContractFailedWithNotEnoughFund() external addFunder {
        vm.expectRevert();
        s_funderContract.fundContract{value: 1e16}();
    }

    function testRegisterAsInNeedFailedWithCloseRegistration() external {
        vm.prank(msg.sender);
        s_funderContract.modifierRegistrationStatus();
        vm.prank(msg.sender);
        vm.expectRevert();
        s_funderContract.registerAsInNeed();
    }

    function testRegisterAsInNeedFailedWithContractNotFunded()
        external
        addFunder
    {
        vm.expectRevert();
        s_funderContract.registerAsInNeed();
    }

    function testRegistrationSucceed() external addFunder {
        s_funderContract.fundContract{value: SEND_VALUE}();
        vm.prank(msg.sender);
        s_funderContract.registerAsInNeed();
        address registered = s_funderContract.getAccountRegistered(0);
        uint256 accountNumb = s_funderContract.getNumberOfAccountRegistered();
        assert(registered == msg.sender);
        assert(accountNumb == 1);
    }

    function testWithdrawFundFailedWithwrongCaller() external {
        vm.expectRevert();
        vm.prank(s_testerAddress);
        s_funderContract.withdrawFund();
    }

    function testWithdrawFundFailedWithContractNotFunded() external {
        vm.expectRevert();
        vm.prank(msg.sender);
        s_funderContract.withdrawFund();
    }

    function testWithdrawFundSucceed() external addFunder {
        s_funderContract.fundContract{value: SEND_VALUE}();
        uint256 contractBalanceBefore = address(s_funderContract).balance;
        vm.prank(msg.sender);
        s_funderContract.withdrawFund();
        uint256 contractBalanceAfter = address(s_funderContract).balance;
        assert(contractBalanceBefore > contractBalanceAfter);
        assert(contractBalanceAfter == 0);
    }

    function testCreateSubscriptionFailedWithWrongCaller() external {
        vm.expectRevert();
        vm.prank(s_testerAddress);
        s_funderContract.createNewSubscription();
    }

    function testCreateSubscriptionSucceed() external {
        vm.prank(msg.sender);
        vm.deal(msg.sender, TESTER_BALANCE);
        s_funderContract.createNewSubscription();
        uint64 subId = s_funderContract.getSubId();
        assert(subId != 0);
    }

    /**
     * I had to use my real address here and test it on a fork url
     */
    function testTopUpSubscription() external {
        // Create subscription
        vm.prank(msg.sender);
        vm.deal(msg.sender, TESTER_BALANCE);
        s_funderContract.createNewSubscription();
        uint64 subId = s_funderContract.getSubId();
        console.log("SubId: ", subId);

        // Lets fund s_funderContract with link
        vm.prank(REAL_ADD);
        bool success = s_linkInterface.transfer(
            address(s_funderContract),
            5e18
        );
        if (!success) {
            console.log("Link transfer failed");
            return;
        }

        uint256 funderContractLinkBalance = s_linkInterface.balanceOf(
            address(s_funderContract)
        );
        console.log(
            "FunderContract LINK balance is :",
            funderContractLinkBalance
        );

        // Top up the subscription
        vm.prank(msg.sender);
        s_funderContract.topUpSubscription(1e18);
        uint256 msgSenderLinkBalanceAfter = s_funderContract
            .getAddressLinkBalance(msg.sender);
        console.log(msgSenderLinkBalanceAfter);
        assert(msgSenderLinkBalanceAfter == 0);
    }

    function testAddConsumerRemoveConsumerCancelsubscription() external {
        // Create subscription
        vm.prank(msg.sender);
        vm.deal(msg.sender, TESTER_BALANCE);
        s_funderContract.createNewSubscription();

        // Add a new consumer
        vm.prank(msg.sender);
        s_funderContract.addConsumer(address(this));
        (address[] memory consumers, ) = s_funderContract.getSubscription();
        assert(consumers[1] == address(this));

        // Remove address(this)as consumer
        vm.prank(msg.sender);
        s_funderContract.removeConsumer(address(this));
        (address[] memory consumers1, ) = s_funderContract.getSubscription();
        assertEq(consumers1.length, 1);
        assert(address(s_funderContract) == consumers1[0]);

        // Cancel subscription
        vm.prank(msg.sender);
        s_funderContract.cancelSubscription(address(s_funderContract));
        vm.prank(msg.sender);
        uint64 subId = s_funderContract.getSubId();
        console.log("SubId :", subId);
        assert(subId == 0);
    }

    function testWithdrawLinkFailedWithWrongCaller() external {
        vm.prank(s_testerAddress);
        vm.expectRevert();
        s_funderContract.withdraw(SEND_VALUE, address(s_funderContract));
    }

    function testWithdrawLinkSucceed() external {
        vm.prank(REAL_ADD);
        bool succeed = s_linkInterface.transfer(
            address(s_funderContract),
            SEND_VALUE
        );
        if (!succeed) {
            console.log("Link Transfer Failed");
            return;
        }

        uint256 funderContractBalanceBefore = s_linkInterface.balanceOf(
            address(s_funderContract)
        );

        vm.prank(msg.sender);
        vm.deal(msg.sender, TESTER_BALANCE);
        s_funderContract.withdraw(SEND_VALUE, REAL_ADD);
        uint256 funderContractBalanceAfter = s_linkInterface.balanceOf(
            address(s_funderContract)
        );

        assert(funderContractBalanceBefore > funderContractBalanceAfter);
        assert(funderContractBalanceBefore == SEND_VALUE);
        assert(funderContractBalanceAfter == 0);
    }

    function testCallCheckUpKeepAndPerformUpkeepSucceed() external addFunder {
        // Fund the funder contract (shouldnt be doing it in a normal contract bcause of reantrancy)
        (bool success, ) = payable(address(s_funderContract)).call{
            value: SEND_VALUE
        }("");

        if (!success) return;

        // One participant as the registration is by default open
        vm.prank(msg.sender);
        s_funderContract.registerAsInNeed();

        // Create subscription
        vm.prank(msg.sender);
        s_funderContract.createNewSubscription();

        // Fund the subscription
        vm.prank(REAL_ADD);
        bool passed = s_linkInterface.transfer(address(s_funderContract), 5e18);
        if (!passed) {
            console.log("Link transfer failed");
            return;
        }
        vm.prank(msg.sender);
        s_funderContract.topUpSubscription(SEND_VALUE);

        // Set the right time
        vm.warp(block.timestamp + 30 + 1); // Tested with 30 seconds interval
        vm.roll(block.number + 1);

        vm.prank(msg.sender);
        s_funderContract.checkUpkeep("");
        vm.prank(msg.sender);
        s_funderContract.performUpkeep("");
    }
}

/*
PS: More testing could've been made there but i decided to stop here
and keep on learning more new stuffs as i already get what is happenning here.
*/
