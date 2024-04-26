// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {OpenBidder} from "src/OpenBidder.sol";

contract OpenBidderScript is Script {
    error WrongChain();

    OpenBidder bidder;
    WETH constant weth = WETH(payable(0x4200000000000000000000000000000000000006));
    // todo: add mainnet details when deployed
    // testnet
    uint256 constant L2_CHAIN_ID = 42169;
    address constant auctioneer = 0x56e0B667f0279ff74Ed04632B5230D77B78fc704;
    address constant settlement = 0xa77c65DBfaCAd5FA2996A234D11a02CD8F43A991;

    function setUp() public {}

    function run() public {
        if (getChainID() != L2_CHAIN_ID) revert WrongChain();

        vm.startBroadcast();
        bidder = new OpenBidder(weth, auctioneer, settlement);
        vm.stopBroadcast();
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
