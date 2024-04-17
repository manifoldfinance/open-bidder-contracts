// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Auction Contract
import { WETH } from "solmate/tokens/WETH.sol";
import {LibSort} from "solady/utils/LibSort.sol";
import { IBidder } from "src/interfaces/IBidder.sol";
import { IAuctioneer } from "src/interfaces/IAuctioneer.sol";
import { ISettlement } from "src/interfaces/ISettlement.sol";

contract OpenBidder is IBidder {
    WETH public weth;
    IAuctioneer public auctioneer;
    ISettlement public house;
    mapping(address user => uint256 balance) public balances;
    mapping(uint256 slot => uint256[] slotBids) internal bids;
    mapping(address user => mapping(uint256 slot => uint256 bid)) internal bidUser;
    // mapping(address user => uint256[] userBids) internal bidsUser;

    constructor(WETH _weth, address _auctioneer, address settlement) {
        weth = _weth;
        auctioneer = IAuctioneer(_auctioneer);
        house = ISettlement(settlement);
        weth.approve(_auctioneer, type(uint256).max);
    }

    /// @dev Make a bid for a slot. Pay up front. Unfilled bid balances carry over for new bids.
    function makeBid(uint256 slot, uint128 weiPerGas, uint120 amountOfGas) external payable {
        // Check user bid. One bid allowed per user per slot. Custom security for open bidder contract.
        if (bidUser[msg.sender][slot] > 0) revert();

        // check auction state
        (uint120 itemsForSale, bool isOpen, bool isSettled) = auctioneer.auctions(slot);
        if (!isOpen) revert();
        if (isSettled) revert();
        if (amountOfGas > itemsForSale) revert();

        // check amount
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
        if (amount == 0) revert();
        if (msg.value + balances[msg.sender] < amount) revert();
        if (msg.value > 0)
            weth.deposit{value: msg.value}();
        uint8 bidderId = auctioneer.IdMap(address(this));
        uint256 packedBid = auctioneer.packBid(weiPerGas, amountOfGas, bidderId);
        bids[slot].push(packedBid);
        bidUser[msg.sender][slot] = packedBid;
        balances[msg.sender] += amount;
    }

    // /// @dev Make a bid for future slots until filled or cancelled. Pay up front. Unfilled bid balances carry over for new bids.
    // function goodTilCanceled(uint128 weiPerGas, uint120 amountOfGas) external payable {
    //     uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
    //     if (msg.value < amount) revert();
    //     if (msg.value > 0)
    //         weth.deposit{value: msg.value}();
    //     uint8 bidderId = auctioneer.IdMap(address(this));
    //     uint256 packedBid = auctioneer.packBid(weiPerGas, amountOfGas, bidderId);
    //     bidsUser[msg.sender].push(packedBid);
    //     balances[msg.sender] += amount;
    // }

    function getBid(uint256 slot) external view returns (uint256[] memory packedBids) {
        // uint256 lenGTC = bidsUser.length;
        // uint256 lenFOK = bids[slot].length;
        // uint256 lenBids = lenGTC + lenFOK;
        // packedBids = new uint256[](lenBids);
        // for (uint256 i = 0; i < lenBids; i++) {
            
        // }
        return bids[slot];
    }

    function submitBundles(uint256 slot, uint256 amountOfGas, bytes32[] calldata hashes) external {
        // check sender has balance
        if (balances[msg.sender] == 0) revert();

        // check auction state
        (, bool isOpen, bool isSettled) = auctioneer.auctions(slot);
        if (isOpen) revert();
        if (!isSettled) revert();

        // check bidder info
        (uint120 itemsBought, uint128 amountOwed) = auctioneer.getBidderInfo(slot, address(this));
        if (itemsBought == 0) revert();
        if (itemsBought < amountOfGas) revert();

        //  check user
        uint256 userBid = bidUser[msg.sender][slot];

        // sort bids to determine who won
        uint256 bidCountLocal = bids[slot].length;
        uint256[] memory roundBids = new uint256[](bidCountLocal);
        for (uint256 i; i < bidCountLocal; i++) {
            roundBids[i] = bids[slot][i];
        }        
        LibSort.insertionSort(roundBids);
        uint256 cumAmount;
        for (uint256 bidIdx = bidCountLocal; bidIdx > 0; bidIdx--) {
            uint256 packedBid = roundBids[bidIdx - 1];
            (, , uint128 weiPerGas) = decodeBid(packedBid);
            uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
            cumAmount += amount;
            if (cumAmount > amountOwed) revert();
            if (packedBid != userBid) continue;
            balances[msg.sender] -= amount;
            break;            
        }
        
        // approve future token spend and submit bundle hashes
        auctioneer.approve(address(house), slot, amountOfGas);
        house.submitBundle(slot, amountOfGas, hashes);
    }

    /**
     * @dev Decode the packed bid information.
     *
     * @param packedBid The packed bid information.
     * @return bidderId The bidder's ID.
     * @return itemsToBuy The number of items the bidder wants to buy.
     * @return bidPrice The price per item in the bid.
     */
    function decodeBid(uint256 packedBid)
        internal
        pure
        returns (uint8 bidderId, uint120 itemsToBuy, uint128 bidPrice)
    {
        bidderId = uint8(packedBid);
        itemsToBuy = uint120(packedBid >> 8);
        bidPrice = uint128(packedBid >> 128);
    }
}