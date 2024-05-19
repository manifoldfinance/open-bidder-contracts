#!/usr/bin/env bash

source .env

forge script script/OpenBidder.s.sol:OpenBidderScript --rpc-url $RPC_L2 --private-key $PRIVATE_KEY --broadcast -vvv
