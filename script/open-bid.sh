#!/usr/bin/env bash

source .env

BID_VALUE=$(($WEI_PER_GAS * $AMOUNT_OF_GAS))
cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "openBid(uint128,uint120,bytes32)" $WEI_PER_GAS $AMOUNT_OF_GAS $BUNDLE_HASH --value $BID_VALUE