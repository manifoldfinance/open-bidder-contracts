#!/usr/bin/env bash

# poll submitting pending bundles for each open slot
# Expects env var AUCTION_CONTRACT, RPC_L2
source .env

BID_ID=1
count=0

until [[ $BID_ID == 0 ]]; do
    slot_count=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsCount()(uint256)")
    slot_count=$(expr $slot_count - 1)
    SLOT=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsAuctioned(uint256)(uint256)" $slot_count)
    cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "submitBundles(uint256)" $SLOT
    BID_ID=$(cast call --rpc-url $RPC_L2 $BIDDER_CONTRACT "getBidIdByBundleHash(bytes32)(uint256)" $BUNDLE_HASH)
    ((count++))
    sleep 10
done

printf '\n%s\n' "Command completed successfully after $count attempts."
