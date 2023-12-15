-include .env


deployOnMumbai:; forge script script/DeployFunderContract.s.sol:DeployFunderContract --rpc-url $(MUMBAI_RPC_URL) --broadcast --private-key $(PRIVATE_KEY)


transferLinkFromAccountToContract:; forge script script/Interactions.s.sol:TransferLinkToken --rpc-url $(MUMBAI_RPC_URL) --broadcast --private-key $(PRIVATE_KEY) 
createSub:; forge script script/Interactions.s.sol:CreateSubscription --rpc-url $(MUMBAI_RPC_URL) --broadcast --private-key $(PRIVATE_KEY)
register:; forge script script/Interactions.s.sol:RegisterAsInNeed --rpc-url $(MUMBAI_RPC_URL) --broadcast --private-key $(PRIVATE_KEY)
fundFunderContract:; forge script script/Interactions.s.sol:FundFunderContract --rpc-url $(MUMBAI_RPC_URL) --broadcast --private-key $(PRIVATE_KEY)
topUp:; forge script script/Interactions.s.sol:TopUpSubscription --rpc-url $(MUMBAI_RPC_URL) --broadcast --private-key $(PRIVATE_KEY) 

