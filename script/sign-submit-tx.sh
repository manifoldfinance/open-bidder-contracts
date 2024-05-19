#!/usr/bin/env bash
set -x

# Script to sign a tx, send to bundle endpoint, open bid and poll bidder contract to submit for open slots
# Expect env vars TX_TO, TX_SIG, TX_ARGS, TX_VALUE, PRIVATE_KEY, RPC_L1, RPC_L2
source .env

# sign TX
TX=$(cast mktx --rpc-url $RPC_L1 --private-key $PRIVATE_KEY $TX_TO $TX_SIG ${TX_ARGS[*]} --value $TX_VALUE  --priority-gas-price 0)
echo $TX
AMOUNT_OF_GAS=$(cast estimate --rpc-url $RPC_L1 $TX_TO $TX_SIG ${TX_ARGS[*]} --value $TX_VALUE)
echo $AMOUNT_OF_GAS

# send to mev_sendBetaBundle
url="$RPC_BETA"
info=$(curl -d '{"jsonrpc": "2.0", "method":"mev_sendBetaBundle", "params":[{"txs":["'"$TX"'"], "slot": "100000000000000001"}], "id":1}' -H "Content-Type: application/json" -X POST -s "${url}" | jq '.')
BUNDLE_HASH=$(echo $info | /usr/bin/jq --raw-output '.result')
echo $BUNDLE_HASH

# open bid
BID_VALUE=$(($WEI_PER_GAS * $AMOUNT_OF_GAS))
cast send --rpc-url $RPC_L2 --private-key $PRIVATE_KEY $BIDDER_CONTRACT "openBid(uint128,uint120,bytes32)" $WEI_PER_GAS $AMOUNT_OF_GAS $BUNDLE_HASH --value $BID_VALUE

# poll submit
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