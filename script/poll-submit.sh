#!/usr/bin/env bash
set -x

# poll submitting pending bundles for each open slot
# Expects env var AUCTION_CONTRACT, RPC_L2
source .env

# clear pending bids
cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "checkPendingBids(uint256)" 1


BID_ID=$(cast call --rpc-url $RPC_L2 $BIDDER_CONTRACT "getBidIdByBundleHash(bytes32)(uint256)" $BUNDLE_HASH)
status=0
count=0
last_slot=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsCount()(uint256)")
last_slot=$(expr $last_slot - 1)

until [[ $status == 1 ]]; do
    slot_count=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsCount()(uint256)")
    slot_count=$(expr $slot_count - 1)
    SLOT=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsAuctioned(uint256)(uint256)" $slot_count)
    cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "submitBundles(uint256)" $SLOT
    status=$(cast call --rpc-url $RPC_L2 $BIDDER_CONTRACT "bids(uint256)(uint8)" $BID_ID)
    ((count++))
    sleep 10
done

printf '\n%s\n' "Command completed successfully after $count attempts."
