#!/usr/bin/env bash
# sudo apt install jq

# Send txs to mev_sendBetaBundle returning bundle hash for bid
# Expected env vars RPC_L1, TXS
source .env

url="$RPC_BETA"
info=$(curl -d '{"jsonrpc": "2.0", "method":"mev_sendBetaBundle", "params":[{"txs":["'"$TX"'"], "slot": "100000000000000001"}], "id":1}' -H "Content-Type: application/json" -X POST -s "${url}" | jq '.')
BUNDLE_HASH=$(echo $info | /usr/bin/jq --raw-output '.result')

echo $BUNDLE_HASH

