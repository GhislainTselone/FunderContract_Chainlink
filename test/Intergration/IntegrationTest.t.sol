// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployFunderContract} from "../../script/DeployFunderContract.s.sol";
import {FunderContract} from "../../src/FunderContract.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {FundFunderContract, RegisterAsInNeed, CreateSubscription, TopUpSubscription, TransferLinkToken} from "../../script/Interactions.s.sol";

contract IntegragtionTest is Test {
    FunderContract private s_funderContract;
    HelperConfig private s_helperConfig;
    LinkTokenInterface private s_linkInterface;
    FundFunderContract private s_fundFunderContract;
    RegisterAsInNeed private s_registerAsInNeed;
    CreateSubscription private s_createSubscription;
    TopUpSubscription private s_topUp;
    TransferLinkToken private s_transferLink;
    address private s_funderContractAddress;

    address private s_testerAddress = makeAddr("selone");
    address private s_linkAddress;
    address private constant REAL_ADD = address(0); // My real address here

    uint256 private constant TESTER_BALANCE = 10e18;
    uint private constant SEND_VALUE = 1e18;

    function setUp() external {
        DeployFunderContract deployFunderContract = new DeployFunderContract();
        s_fundFunderContract = new FundFunderContract();
        s_createSubscription = new CreateSubscription();
        s_topUp = new TopUpSubscription();
        s_transferLink = new TransferLinkToken();
        s_registerAsInNeed = new RegisterAsInNeed();

        (s_funderContract, s_helperConfig, s_linkAddress) = deployFunderContract
            .run();
        s_linkInterface = LinkTokenInterface(s_linkAddress);
        s_funderContractAddress = address(s_funderContract);

        vm.deal(s_testerAddress, TESTER_BALANCE);
    }

    function testFundFunderContractAndRegisterAndCreateSubAndTopUp() external {
        s_fundFunderContract.fundContract(s_funderContractAddress);
        assert(address(s_funderContract).balance == 1e18);
        s_registerAsInNeed.register(s_funderContractAddress);
        assert(s_funderContract.getNumberOfAccountRegistered() == 1);
        s_createSubscription.createSubscription(s_funderContractAddress);
        assert(s_funderContract.getSubId() != 0);
        vm.prank(REAL_ADD);
        bool success = s_linkInterface.transfer(s_funderContractAddress, 1e18);
        if (!success) {
            console.log("Link Transfer Failed");
            return;
        }
        uint256 funderContractLinkBalanceBefore = s_linkInterface.balanceOf(
            s_funderContractAddress
        );
        s_topUp.topUpSubscription(s_funderContractAddress, 1e18);
        uint256 funderContractLinkBalanceAfter = s_linkInterface.balanceOf(
            s_funderContractAddress
        );
        assert(
            funderContractLinkBalanceBefore > funderContractLinkBalanceAfter
        );
        assert(s_linkInterface.balanceOf(s_funderContractAddress) == 0);
    }
}
