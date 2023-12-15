# FUNDER CONTRACT PROJECT

## About
The Funder contract project is a smart contract that automatically and randomly funds one account among a bunch of accounts previously registered as "IN NEED" each 30 seconds. 


## Specific tools involve
The Funder contract use external computation to trigger automatically the whole mecanism. Two Chainlink oracle services are involved : 

1. Chainlink VRF (Randomness)
PS: Implementation made directly in the contract.

2. Chainlink Automation
PS: Manually created an upKeep + after making the contract compatible.



## Test Phase
The code will be test only on a forked POLYGON MUMBAI network. 



## Deployment
The smart contract will be then deployed on POLYGON MUMBAI NETWORK.