# OpenBidder Contract
## Overview

The OpenBidder contract facilitates participation in auctions by allowing users to place bids for gas space bundles. It interacts with other contracts such as WETH (Wrapped Ether), an auctioneer, and a settlement contract.
## Features

- Bid Placement: Users can place bids for gas space bundles by specifying the amount of gas and the price per gas.
- Cancellation: Bidders can cancel their open bids and reclaim their funds.
- Bundle Submission: After an auction slot has ended, the contract automatically submits the bundle hashes to a settlement contract for processing.

## Scripts
Functional scripts have been provided for full interaction with `OpenBidder`.
- [Sign a tx](./script/sign-tx.sh)
- [Send bundle to `mev_sendBetaBundle`](./script/send-bundle.sh)
- [Open a bid](./script/open-bid.sh)
- [Poll submitting bundles](./script/poll-submit.sh)
- [Sign, send, bid and poll submit a tx](./script/sign-submit-tx.sh)

## Built with Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
