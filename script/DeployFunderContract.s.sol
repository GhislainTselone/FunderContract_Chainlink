// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FunderContract} from "../src/FunderContract.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";

contract DeployFunderContract is Script {
    function run()
        external
        returns (
            FunderContract funderContract,
            HelperConfig helperConfig,
            address linkAddress
        )
    {
        helperConfig = new HelperConfig();
        uint256 interval = helperConfig.getItems()._interval;
        uint256 minFund = helperConfig.getItems()._minFund;
        address vrfCoordinatorV2 = helperConfig.getItems()._vrfCoordinatorV2;
        linkAddress = helperConfig.getItems()._linkAddress;
        bytes32 keyHash = helperConfig.getItems()._keyHash;
        uint16 requestConfirmations = helperConfig
            .getItems()
            ._requestConfirmations;
        uint32 callbackGasLimit = helperConfig.getItems()._callbackGasLimit;
        uint32 numWords = helperConfig.getItems()._numWords;

        vm.startBroadcast();
        funderContract = new FunderContract(
            interval,
            minFund,
            vrfCoordinatorV2,
            linkAddress,
            keyHash,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        vm.stopBroadcast();
    }
}
