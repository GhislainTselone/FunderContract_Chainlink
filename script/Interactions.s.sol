//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FunderContract} from "../src/FunderContract.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract FundFunderContract is Script {
    // I decided to add these variables manually
    address private constant FUNDER_CONTRACT_ADDRESS = address(0);
    uint256 private constant VALUE_SEND = 1e18;

    function fundContract(address _funderContract) public {
        FunderContract funderContract = FunderContract(
            payable(_funderContract)
        );
        vm.startBroadcast();
        funderContract.fundContract{value: VALUE_SEND}();
        vm.stopBroadcast();
    }

    function run() external {
        fundContract(FUNDER_CONTRACT_ADDRESS);
    }
}

contract RegisterAsInNeed is Script {
    // I decided to add this variable manually
    address private constant FUNDER_CONTRACT_ADDRESS = address(0);

    function register(address _funderContract) public {
        FunderContract funderContract = FunderContract(
            payable(_funderContract)
        );
        vm.startBroadcast();
        funderContract.registerAsInNeed();
        vm.stopBroadcast();
    }

    function run() external {
        register(FUNDER_CONTRACT_ADDRESS);
    }
}

contract CreateSubscription is Script {
    // I decided to add this variable manually
    address private constant FUNDER_CONTRACT_ADDRESS = address(0);

    function createSubscription(address _funderContract) public {
        FunderContract funderContract = FunderContract(
            payable(_funderContract)
        );
        vm.startBroadcast();
        funderContract.createNewSubscription();
        vm.stopBroadcast();
    }

    function run() external {
        createSubscription(FUNDER_CONTRACT_ADDRESS);
    }
}

contract TopUpSubscription is Script {
    // I decided to add these variables manually
    address private constant FUNDER_CONTRACT_ADDRESS = address(0);
    uint256 private constant Amount_TO_SEND = 10e18;

    function topUpSubscription(
        address _funderContract,
        uint256 _amount
    ) public {
        FunderContract funderContract = FunderContract(
            payable(_funderContract)
        );
        vm.startBroadcast();
        funderContract.topUpSubscription(_amount);
        vm.stopBroadcast();
    }

    function run() external {
        topUpSubscription(FUNDER_CONTRACT_ADDRESS, Amount_TO_SEND);
    }
}

contract TransferLinkToken is Script {
    // I decided to add these variables manually
    address private constant TO = address(0);
    address private constant LINK_ADDRESS =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    uint256 private constant Amount_TO_SEND = 10e18;

    function transferLinkToken(
        address _linkToken,
        address _to,
        uint256 _amountToSend
    ) public {
        LinkTokenInterface linkToken = LinkTokenInterface(_linkToken);
        vm.startBroadcast();
        linkToken.transfer(_to, _amountToSend);
        vm.stopBroadcast();
    }

    function run() external {
        transferLinkToken(LINK_ADDRESS, TO, Amount_TO_SEND);
    }
}
