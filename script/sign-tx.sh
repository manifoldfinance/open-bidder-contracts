#!/usr/bin/env bash

# Script to sign a tx given details
# Expect env vars TX_TO, TX_SIG, TX_ARGS, TX_VALUE, PRIVATE_KEY, RPC_L1
source .env

# eg cast mktx --ledger 0x... "deposit(address,uint256)" 0x... 1
# sign TX
echo "Getting current base fee"
BASE_FEE=$(cast base-fee --rpc-url $RPC_L1 latest)
echo "Signing tx"
TX=$(cast mktx --rpc-url $RPC_L1 --private-key $PRIVATE_KEY $TX_TO $TX_SIG ${TX_ARGS[*]} --value $TX_VALUE  --priority-gas-price 0 --gas-price $((2 * BASE_FEE)))
echo $TX
echo "Estimating gas"
AMOUNT_OF_GAS=$(cast estimate --rpc-url $RPC_L1 $TX_TO $TX_SIG ${TX_ARGS[*]} --value $TX_VALUE)
echo $AMOUNT_OF_GAS