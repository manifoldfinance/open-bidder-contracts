#!/usr/bin/env bash

# Script to register bidder contract on auctioneer
# Expect env var PRIVATE_KEY to be operator
source .env

echo "Registering new bidder"
cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $AUCTION_CONTRACT "newBidder(address)(uint8)" $BIDDER_CONTRACT
