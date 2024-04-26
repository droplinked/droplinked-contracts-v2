# Droplinked Solidity Contracts
This repository contains the droplinked's smart-contract source code for EVM chains that droplinked integrates with, including : Polygon, Binance, Hedera and Ripple sidechain

## Run tests
To run the tests on the contract you can run the following command in the dev branch: 
`npm run test`

```
  Shop
    Deployment
NFT deployed to: 0xbf9fBFf01664500A33080Da5d437028b07DFcC55
Shop deployed to: 0x379F6cc50026646dA9452610CD48d13A5d7fb6ae
Shop Owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 , owner account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
      ✔ Should deploy shop
      ✔ Should set the right fee
    Set & Update heartbeat
      ✔ Should update the heartbeat with owner account
      ✔ should not update the heartbeat with other account
    Set & update fee
      ✔ Should update the fee to given number using owner account
      ✔ Should not update the fee to given number using other account
    Mint
      ✔ Should mint 5000 tokens via ERC1155
      ✔ Should mint the same product with the same token_id (49ms)
      ✔ Should set the right product metadata
      ✔ should set the right beneficiaries when minting
    Publish request
      ✔ Should publish a request
      ✔ Should publish publish a request with the right data
      ✔ Should not publish a request twice
    AcceptRequest
      ✔ Should accept a request
      ✔ Should not accept a request if it is not the producer
    DisapproveRequest
      ✔ Should disapprove a request (40ms)
      ✔ Should not disapprove a request if it is not the producer (48ms)
    purchase
      ✔ Should purchase a product (103ms)
      ✔ Should purchase a product with native token as price (70ms)
      ✔ Should purchase a product which has beneficiaries (78ms)
      ✔ Should purchase a product which has beneficiaries & affiliate (102ms)
      ✔ Should purchase a product which has beneficiaries & affiliate with token (138ms)
    MultiProduct purchase
      ✔ Should purchase a product (79ms)
      ✔ Should purchase a product which has beneficiaries & affiliate with token through proxy (146ms)
      ✔ Should purchase a product with native token as price through proxy (68ms)
      ✔ Should purchase two products (136ms)


  26 passing (6s)
```
## Deploy
To deploy the contract to a network, follow these steps:

Add your network to the `hardhat.config.ts` file, by simply looking at the exapmles that are there
Put your etherscan `api key` in the etherscan part
Run the following command to deploy :
`npx hardhat run scripts/deploy.ts --network $network_name_here$`
For instance, running

npx hardhat run scripts/deploy.ts --network polygon_mumbai
would result in something like this

[ ✅ ] Deployer deployed to: 0x34C4db97cE4cA2cce48757F85C954C5647124106 with fee: 100 and heartbeat: 120

[ ✅ ] PaymentProxy deployed to: 0x34C4db97cE4cA2cce48757F85C954C5647124106

