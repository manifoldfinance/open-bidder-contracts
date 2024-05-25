#!/usr/bin/env bash

# Script to sign a tx given details
# Expect env vars TX_TO, TX_SIG, TX_ARGS, TX_VALUE, PRIVATE_KEY, RPC_L1
source .env

# eg cast mktx --ledger 0x... "deposit(address,uint256)" 0x... 1
cast mktx --rpc-url $RPC_L1 --private-key $PRIVATE_KEY $TX_TO $TX_SIG ${TX_ARGS[*]} --value $TX_VALUE --priority-gas-price 0