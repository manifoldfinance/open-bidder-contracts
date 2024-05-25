#!/usr/bin/env bash
set -x

# Script to sign a tx, send to bundle endpoint, open bid and poll bidder contract to submit for open slots
# Expect env vars TX_TO, TX_SIG, TX_ARGS, TX_VALUE, PRIVATE_KEY, RPC_L1, RPC_L2
source .env

# set url for mev_sendBetaBundle
url="$RPC_BETA"

# sign TX
echo "Getting current base fee"
BASE_FEE=$(cast base-fee --rpc-url $RPC_L1 latest)
echo "Signing tx"
TX=$(cast mktx --rpc-url $RPC_L1 --private-key $PRIVATE_KEY $TX_TO $TX_SIG ${TX_ARGS[*]} --value $TX_VALUE  --priority-gas-price 0 --gas-price $((2 * BASE_FEE)))
echo $TX
echo "Estimating gas"
AMOUNT_OF_GAS=$(cast estimate --rpc-url $RPC_L1 $TX_TO $TX_SIG ${TX_ARGS[*]} --value $TX_VALUE)
echo $AMOUNT_OF_GAS

# send to mev_sendBetaBundle
echo "Sending bundle"
info=$(curl -d '{"jsonrpc": "2.0", "method":"mev_sendBetaBundle", "params":[{"txs":["'"$TX"'"], "slot": "100000000000000001"}], "id":1}' -H "Content-Type: application/json" -X POST -s "${url}" | jq '.')
BUNDLE_HASH=$(echo $info | /usr/bin/jq --raw-output '.result')
echo $BUNDLE_HASH

# # clear pending bids
# echo "Clear pending bids"
# cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "checkPendingBids(uint256)" 1

# open bid
echo "Open bid for auction"
BID_VALUE=$(($WEI_PER_GAS * $AMOUNT_OF_GAS))
cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "openBid(uint128,uint120,bytes32)" $WEI_PER_GAS $AMOUNT_OF_GAS $BUNDLE_HASH --value $BID_VALUE

# poll submit
BID_ID=$(cast call --rpc-url $RPC_L2 $BIDDER_CONTRACT "getBidIdByBundleHash(bytes32)(uint256)" $BUNDLE_HASH)
status=0
count=0

slot_count=0
last_slot=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsCount()(uint256)")
last_slot=$(expr $last_slot - 1)

until [[ $status == 1 ]]; do
    slot_count=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsCount()(uint256)")
    slot_count=$(expr $slot_count - 1)
    if ((slot_count > last_slot)); then
        last_slot=$slot_count
        SLOT=$(cast call --rpc-url $RPC_L2 $AUCTION_CONTRACT "slotsAuctioned(uint256)" $slot_count | cast --to-dec)
        # re-send bundle with correct slot for correct offline retreival
        # note the hash is the same regardless of slot number
        curl -d '{"jsonrpc": "2.0", "method":"mev_sendBetaBundle", "params":[{"txs":["'"$TX"'"], "slot":"'"$SLOT"'" }], "id":1}' -H "Content-Type: application/json" -X POST -s "${url}"
        cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "submitBundles(uint256)" $SLOT
        status=$(cast call --rpc-url $RPC_L2 $BIDDER_CONTRACT "bids(uint256)(uint8)" $BID_ID)
    fi
    ((count++))
    sleep 10
done

printf '\n%s\n' "Submit completed successfully after $count attempts."

# wait 10 mins for slot confirmation
sleep 600

# confirm pending txs
cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "checkPendingBids(uint256)" 1

# check status
status=$(cast call --rpc-url $RPC_L2 $BIDDER_CONTRACT "bids(uint256)(uint8)" $BID_ID)

if (( status == 2 )); then
    echo "Successfully won auction, submitted txs and landed on L1"
    exit 0
done

# status not complete
# cancel tx for refund or poll to submit again
cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "cancelOpenBid(uint256)" $BID_ID

echo "Cancelled tx due to beta block being missed on L1"