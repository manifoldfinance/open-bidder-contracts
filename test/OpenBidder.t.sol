// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {OpenBidder} from "../src/OpenBidder.sol";
import {IAuctioneer} from "src/interfaces/IAuctioneer.sol";

contract OpenBidderTest is Test {
    OpenBidder public bidder;
    string RPC_L2 = vm.envString("RPC"); // L2 RPC url, default testnet
    uint256 FORK_ID;
    WETH constant weth = WETH(payable(0x4200000000000000000000000000000000000006));
    // todo: add mainnet details when deployed
    // testnet
    IAuctioneer constant auctioneer = IAuctioneer(0x56e0B667f0279ff74Ed04632B5230D77B78fc704);
    address constant settlement = 0xa77c65DBfaCAd5FA2996A234D11a02CD8F43A991;
    // auction operator
    address operator;
    uint256 constant slot = 101;

    function setUp() public {
        FORK_ID = vm.createSelectFork(RPC_L2);
        bidder = new OpenBidder(weth, address(auctioneer), settlement);

        // add new bidder to auctioneer
        operator = auctioneer.operator();
        vm.prank(operator);
        auctioneer.newBidder(address(bidder));
        vm.prank(operator);
        auctioneer.openAuction(slot, 5000000);
    }

    function testOpenBid() public {
        uint128 weiPerGas = 20000000000;
        uint120 amountOfGas = 100000;
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
        // mock return tx bundle hash received from mev_sendBetaBundle
        bytes32 bundleHash = bytes32(uint256(1));
        vm.deal(address(this), amount);
        bidder.openBid{value: amount}(weiPerGas, amountOfGas, bundleHash);

        (uint120 amountOfGas2, uint128 weiPerGas2, address bidder2, bytes32 bundleHash2) = bidder.openBids(0);
        assertEq(bidder2, address(this));
        assertEq(weiPerGas2, weiPerGas);
        assertEq(amountOfGas2, amountOfGas);
        assertEq(bundleHash2, bundleHash);
    }

    function testGetBid() public {
        uint128 weiPerGas = 20000000000;
        uint120 amountOfGas = 100000;
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
        bytes32 bundleHash = bytes32(uint256(1));

        vm.deal(address(this), amount);
        bidder.openBid{value: amount}(weiPerGas, amountOfGas, bundleHash);

        uint256[] memory bids = bidder.getBid(slot);
        assertEq(bids.length, 1);
    }

    function testSubmitBundles() public {
        uint128 weiPerGas = 20000000000;
        uint120 amountOfGas = 100000;
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
        bytes32 bundleHash = bytes32(uint256(1));

        vm.deal(address(this), amount);
        bidder.openBid{value: amount}(weiPerGas, amountOfGas, bundleHash);

        vm.prank(operator);
        auctioneer.runAndSettle(slot);

        bidder.submitBundles(slot);

        (,, address bidder3,) = bidder.openBids(0);
        assertEq(bidder3, address(0));
        (,, address bidder2,) = bidder.wonBids(0);
        assertEq(bidder2, address(this));
    }
}
