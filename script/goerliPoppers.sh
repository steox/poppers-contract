#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

maxSupply=30
price=1
maxMint=30
minPEPE=0
burnPercent=0

forge create --rpc-url ${GOERLI_RPC_URL} \
    --constructor-args $maxSupply $price $maxMint $minPEPE $burnPercent "POPPERS" "POPPERS" \
    --private-key ${PRIVATE_KEY} \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --verify \
    src/Poppers.sol:Poppers