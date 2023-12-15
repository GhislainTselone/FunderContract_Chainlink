// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2} from "@chainlink/contracts/src/v0.8/VRFCoordinatorV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {console} from "forge-std/console.sol";

contract FunderContract is AutomationCompatibleInterface, VRFConsumerBaseV2 {
    /**Custom Errors */
    error FunderContract__CantRegisterForNow();
    error FunderContract__ContractIsNotFunded();
    error FunderContract__OnlyOwnerCanCallIt();
    error FunderContract__FundNotEnough();
    error FunderContract__TransactionFailed();
    error FundContract__UpkeepNeededFalse();

    /**Events */
    event EmitRequestId(uint256 indexed _requestId);
    event EmitWinner(address indexed _winner);

    /**Constant variables */
    address payable private immutable i_owner;
    uint256 private immutable i_interval;
    uint256 private immutable i_minFund;
    VRFCoordinatorV2 private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint16 private immutable i_requestConfirmations;
    uint32 private immutable i_callbackGasLimit;
    uint32 private immutable i_numWords;
    LinkTokenInterface private immutable i_linkToken;
    uint256 private immutable i_topUpSubAmount;

    /**State variables */
    Registration private s_registrationStatus;
    address[] private s_accountsRegistered;
    mapping(address => AccountInfo) private s_addressInfos;
    uint256 private s_startTime;
    uint64 private s_subId;
    address private s_lastWinner;

    /**Type declaration variables */
    enum Registration {
        isOpen,
        isClose
    }

    struct AccountInfo {
        uint256 _amountReceived;
        uint256 _timePick;
    }

    /**Modifiers */
    modifier onlyWhenOpen() {
        if (s_registrationStatus != Registration.isOpen)
            revert FunderContract__CantRegisterForNow();
        _;
    }

    modifier onlyWhenContractisFunded() {
        if (address(this).balance == 0)
            revert FunderContract__ContractIsNotFunded();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FunderContract__OnlyOwnerCanCallIt();
        _;
    }

    constructor(
        uint256 _interval,
        uint256 _minFund,
        address _vrfCoordinatorV2,
        address _linkAddress,
        bytes32 _keyHash,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        i_owner = payable(msg.sender);
        s_registrationStatus = Registration.isOpen;
        s_startTime = block.timestamp;
        i_interval = _interval;
        i_minFund = _minFund;
        i_vrfCoordinator = VRFCoordinatorV2(_vrfCoordinatorV2);
        i_linkToken = LinkTokenInterface(_linkAddress);
        i_keyHash = _keyHash;
        i_requestConfirmations = _requestConfirmations;
        i_callbackGasLimit = _callbackGasLimit;
        i_numWords = _numWords;
    }

    receive() external payable {}

    fallback() external payable {}

    /**State modifing functions */
    function fundContract() external payable onlyOwner {
        if (msg.value < i_minFund) revert FunderContract__FundNotEnough();
    }

    function registerAsInNeed() external onlyWhenContractisFunded onlyWhenOpen {
        s_accountsRegistered.push(msg.sender);
    }

    function withdrawFund() external onlyOwner onlyWhenContractisFunded {
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if (!success) revert FunderContract__TransactionFailed();
    }

    function createNewSubscription() external onlyOwner {
        uint64 subscriptionId = i_vrfCoordinator.createSubscription();
        i_vrfCoordinator.addConsumer(subscriptionId, address(this));
        s_subId = subscriptionId;
    }

    function topUpSubscription(uint256 _amount) external onlyOwner {
        i_linkToken.transferAndCall(
            address(i_vrfCoordinator),
            _amount,
            abi.encode(s_subId)
        );
    }

    function addConsumer(address _consumerAddress) external onlyOwner {
        i_vrfCoordinator.addConsumer(s_subId, _consumerAddress);
    }

    function removeConsumer(address _consumerAddress) external onlyOwner {
        i_vrfCoordinator.removeConsumer(s_subId, _consumerAddress);
    }

    function cancelSubscription(address _receivingWallet) external onlyOwner {
        i_vrfCoordinator.cancelSubscription(s_subId, _receivingWallet);
        s_subId = 0;
    }

    function withdraw(uint256 _amount, address _to) external onlyOwner {
        i_linkToken.transfer(_to, _amount);
    }

    function performUpkeep(bytes calldata /*performData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) revert FundContract__UpkeepNeededFalse();

        s_registrationStatus = Registration.isClose;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            s_subId,
            i_requestConfirmations,
            i_callbackGasLimit,
            i_numWords
        );
        console.log("SubId : ", requestId);
        emit EmitRequestId(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        // modulo
        uint256 accountNumb = s_accountsRegistered.length;
        uint256 chosenIndex = randomWords[0] % accountNumb;
        address winner = s_accountsRegistered[chosenIndex];
        uint256 winnerAmountToReceive = s_addressInfos[winner]._amountReceived +
            address(this).balance;
        uint256 winnerTimesPick = s_addressInfos[winner]._timePick + 1;
        s_addressInfos[winner] = AccountInfo(
            winnerAmountToReceive,
            winnerTimesPick
        );
        s_lastWinner = winner;
        s_accountsRegistered = new address[](0);
        s_registrationStatus = Registration.isOpen;
        (bool sucess, ) = payable(winner).call{value: address(this).balance}(
            ""
        );
        console.log("Winner : ", winner);
        emit EmitWinner(winner);
        if (!sucess) revert FunderContract__TransactionFailed();
    }

    function modifierRegistrationStatus() external onlyOwner {
        if (s_registrationStatus == Registration.isOpen) {
            s_registrationStatus = Registration.isClose;
        } else {
            s_registrationStatus = Registration.isOpen;
        }
    }

    /**Read only functions */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory performData) {
        bool checkRegistrationStatus = s_registrationStatus ==
            Registration.isOpen;
        bool checkParticipantNumber = s_accountsRegistered.length > 0;
        bool checkContractBalance = address(this).balance > 0;
        bool checkTimeInterval = (block.timestamp - s_startTime) >= i_interval;

        upkeepNeeded =
            checkContractBalance &&
            checkRegistrationStatus &&
            checkParticipantNumber &&
            checkTimeInterval;

        performData = "";
    }

    function getOwnerAddress() external view returns (address payable _owner) {
        _owner = i_owner;
    }

    function getRegistrationStatus()
        public
        view
        returns (Registration _status)
    {
        _status = s_registrationStatus;
    }

    function getAccountRegistered(
        uint256 _index
    ) external view returns (address _address) {
        _address = s_accountsRegistered[_index];
    }

    function getNumberOfAccountRegistered()
        external
        view
        returns (uint256 _accountNumb)
    {
        _accountNumb = s_accountsRegistered.length;
    }

    function checkAccountInfo(
        address _account
    ) external view returns (AccountInfo memory _infos) {
        _infos = s_addressInfos[_account];
    }

    function getSubId() external view returns (uint64 _subId) {
        _subId = s_subId;
    }

    function getAddressLinkBalance(
        address _account
    ) external view returns (uint256 _balance) {
        _balance = i_linkToken.balanceOf(_account);
    }

    function getSubscription()
        external
        view
        returns (address[] memory consumers, address owner)
    {
        (, , owner, consumers) = i_vrfCoordinator.getSubscription(s_subId);
    }
}
