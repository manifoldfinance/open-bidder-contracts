// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {OpenBidder} from "src/OpenBidder.sol";

contract OpenBidderScript is Script {
    error WrongChain();

    OpenBidder bidder;
    WETH constant weth = WETH(payable(0x4200000000000000000000000000000000000006));
    uint256 constant L2_CHAIN_ID = 7890785;
    uint256 constant L2_TESTNET_CHAIN_ID = 42169;
    address auctioneer;
    address settlement;

    function setUp() public {}

    function run() public {
        uint256 id = getChainID(); 
        if (id == L2_CHAIN_ID) {
            auctioneer = 0x86Bc75A43704E38f0FD94BdA423C50071fE17c99;
            settlement = 0x80C5FfF824d14c87C799D6F90b7D8e0a715bd33C;
        } else if (id == L2_TESTNET_CHAIN_ID) {
            auctioneer = 0x82052435119AedBEC6e237B5414880bF388F1B63;
            settlement = 0x513844F4425d54beC19B0594AE072e49bEbBF388;
        } else {
            revert WrongChain();
        }

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
