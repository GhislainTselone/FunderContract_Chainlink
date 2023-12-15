// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract HelperConfig {
    NeededItems private s_items;

    uint256 private constant INTERVAL = 30; // can be modify
    uint256 private constant MIN_FUND = 1e18;
    address private constant MUMBAI_VRF_COORDINATOR_V2 =
        0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    address private constant MAINNET_VRF_COORDINATOR_V2 =
        0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    address private constant MUMBAI_LINK_ADDRESS =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address private constant MAINNET_LINK_ADDRESS =
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    bytes32 private constant MUMBAI_KEY_HASH =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    bytes32 private constant MAINNET_KEY_HASH =
        0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;
    uint16 private constant CONFIRMATIONS = 3;
    uint32 private constant CALLBACK_GASLIMIT = 5e5;
    uint32 private constant NUM_WORDS = 1;

    struct NeededItems {
        uint256 _interval;
        uint256 _minFund;
        address _vrfCoordinatorV2;
        address _linkAddress;
        bytes32 _keyHash;
        uint16 _requestConfirmations;
        uint32 _callbackGasLimit;
        uint32 _numWords;
    }

    constructor() {
        uint256 activeNetwork = block.chainid;
        if (activeNetwork == 80001) {
            s_items = whenOnPolygonMumbai();
        }

        if (activeNetwork == 137) {
            s_items = whenOnMainnet();
        }
    }

    function whenOnPolygonMumbai()
        private
        pure
        returns (NeededItems memory _items)
    {
        _items = NeededItems(
            INTERVAL,
            MIN_FUND,
            MUMBAI_VRF_COORDINATOR_V2,
            MUMBAI_LINK_ADDRESS,
            MUMBAI_KEY_HASH,
            CONFIRMATIONS,
            CALLBACK_GASLIMIT,
            NUM_WORDS
        );
    }

    function whenOnMainnet() private pure returns (NeededItems memory _items) {
        _items = NeededItems(
            INTERVAL,
            MIN_FUND,
            MAINNET_VRF_COORDINATOR_V2,
            MAINNET_LINK_ADDRESS,
            MAINNET_KEY_HASH,
            CONFIRMATIONS,
            CALLBACK_GASLIMIT,
            NUM_WORDS
        );
    }

    function getItems() external view returns (NeededItems memory _items) {
        _items = s_items;
    }
}
