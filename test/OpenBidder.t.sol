// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { WETH } from "solmate/tokens/WETH.sol";
import {OpenBidder} from "../src/OpenBidder.sol";
import { IAuctioneer } from "src/interfaces/IAuctioneer.sol";

contract OpenBidderTest is Test {
    OpenBidder public bidder;
    string RPC_L2 = vm.envString("RPC"); // L2 RPC url, default testnet
    uint256 FORK_ID;
    WETH constant weth = WETH(payable(0x4200000000000000000000000000000000000006));
    // todo: add mainnet details when deployed
    // testnet
    IAuctioneer constant auctioneer = IAuctioneer(0x10DeC79E201FE7b27b8c4A1524d9733727D60ea4);
    address constant settlement = 0x46bb4fE80C04b5C28C761ADdd43FD10fFCcB57CE;
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

    function testMakeBid() public {
        uint128 weiPerGas = 20000000000;
        uint120 amountOfGas = 100000;
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
        vm.deal(address(this), amount);
        bidder.makeBid{value: amount}(slot, weiPerGas, amountOfGas);
        assertEq(bidder.balances(address(this)), amount);
    }

    function testGetBid() public {
        uint128 weiPerGas = 20000000000;
        uint120 amountOfGas = 100000;
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);

        vm.deal(address(this), amount);
        bidder.makeBid{value: amount}(slot, weiPerGas, amountOfGas);
        
        uint256[] memory bids = bidder.getBid(slot);
        assertEq(bids.length, 1);
    }

    function testSubmitBundles() public {
        uint128 weiPerGas = 20000000000;
        uint120 amountOfGas = 100000;
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);

        vm.deal(address(this), amount);
        bidder.makeBid{value: amount}(slot, weiPerGas, amountOfGas);

        vm.prank(operator);
        auctioneer.runAndSettle(slot);

        bytes32[] memory hashes = new bytes32[](1);
        hashes[0] = bytes32(uint256(1));
        bidder.submitBundles(slot, amountOfGas, hashes);
        assertEq(bidder.balances(address(this)), 0);
    }
}
