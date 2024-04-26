// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Auction Contract
import {WETH} from "solmate/tokens/WETH.sol";
import {LibSort} from "solady/utils/LibSort.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IBidder} from "src/interfaces/IBidder.sol";
import {IAuctioneer} from "src/interfaces/IAuctioneer.sol";
import {ISettlement} from "src/interfaces/ISettlement.sol";

/**
 * @title OpenBidder
 * @dev Contract for participating in L2 auctions by making bids for L1 gas space.
 */
contract OpenBidder is IBidder {
    using SafeTransferLib for WETH;

    struct Bid {
        uint120 amountOfGas;
        uint128 weiPerGas;
        address bidder;
        bytes32 bundleHash;
    }

    WETH public weth;
    IAuctioneer public auctioneer;
    ISettlement public house;
    uint256 public slotFinished;
    uint256 public bidCount;
    uint256 public wonBidCount;
    bytes32[] hashes;
    mapping(uint256 bidId => Bid bid) public openBids;
    mapping(uint256 bidId => Bid bid) public wonBids;

    /**
     * @dev Constructor function to initialize the contract.
     * @param _weth Address of the WETH token contract
     * @param _auctioneer Address of the auctioneer contract
     * @param settlement Address of the settlement contract
     */
    constructor(WETH _weth, address _auctioneer, address settlement) {
        weth = _weth;
        auctioneer = IAuctioneer(_auctioneer);
        house = ISettlement(settlement);
        weth.approve(_auctioneer, type(uint256).max);
    }

    /**
     * @dev Make a bid for a beta gas space with a bundle hash retreived from mev_sendBetaBundle. Pay up front. Unfilled bid funds can be reclaimed by cancelling.
     * @param weiPerGas Wei per gas in the bid
     * @param amountOfGas Amount of gas in the bid
     * @param bundleHash Hash of the L1 tx bundle
     */
    function openBid(uint128 weiPerGas, uint120 amountOfGas, bytes32 bundleHash) external payable {
        // check amount
        uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
        if (amount == 0) revert();
        if (msg.value < amount) revert();
        weth.deposit{value: msg.value}();

        // check this contract is a registered bidder
        uint8 bidderId = auctioneer.IdMap(address(this));
        if (bidderId == 0) revert();

        // save bid
        openBids[bidCount] = Bid(amountOfGas, weiPerGas, msg.sender, bundleHash);
        ++bidCount;
    }

    function _removeOpenBid(uint256 bidId) internal {
        // swap last bid with bid to remove, then remove last item
        openBids[bidId] = openBids[bidCount - 1];
        delete openBids[bidCount - 1];
        --bidCount;
    }

    /**
     * @dev Get the bid ID corresponding to a bundle hash.
     * @param bundleHash Hash of the L1 tx bundle
     * @return bidId ID of the bid
     */
    function getBidIdByBundleHash(bytes32 bundleHash) public view returns (uint256 bidId) {
        uint256 len = bidCount;
        for (bidId; bidId < len; bidId++) {
            if (openBids[bidId].bundleHash == bundleHash) break;
        }
    }

    /**
     * @dev Get the bid ID corresponding to a sender.
     * @param sender Address of sender
     * @return bidId ID of the bid
     */
    function getBidIdBySender(address sender) public view returns (uint256 bidId) {
        uint256 len = bidCount;
        for (bidId; bidId < len; bidId++) {
            if (openBids[bidId].bidder == sender) break;
        }
    }

    /**
     * @dev Get the bid ID corresponding to bid details.
     * @param amountOfGas Amount of gas to bid for
     * @param weiPerGas Price per gas
     * @return bidId ID of the bid
     */
    function getBidIdByDetails(uint120 amountOfGas, uint128 weiPerGas) public view returns (uint256 bidId) {
        uint256 len = bidCount;
        for (bidId; bidId < len; bidId++) {
            if (openBids[bidId].weiPerGas == weiPerGas && openBids[bidId].amountOfGas == amountOfGas) break;
        }
    }

    function _checkSender(uint256 bidId) internal view {
        if (msg.sender != openBids[bidId].bidder) revert();
    }

    function _amountPaid(uint256 bidId) internal view returns (uint256 amount) {
        return uint256(openBids[bidId].weiPerGas) * uint256(openBids[bidId].amountOfGas);
    }

    /**
     * @dev Cancel an open bid and reclaim funds.
     * @param bidId ID of the bid to cancel
     */
    function cancelOpenBid(uint256 bidId) external {
        // check sender is bidder
        _checkSender(bidId);

        // get amount paid
        uint256 amount = _amountPaid(bidId);

        // remove bid
        _removeOpenBid(bidId);

        // refund amount paid
        // use weth to avoid re-entrancy
        weth.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Get the packed representation of all open bids.
     * @return packedBids Array of packed bid information
     */
    function getBid(uint256) public view returns (uint256[] memory packedBids) {
        uint256 len = bidCount;
        uint8 bidderId = auctioneer.IdMap(address(this));
        packedBids = new uint256[](len);
        for (uint256 bidId; bidId < len; bidId++) {
            packedBids[bidId] = packBid(openBids[bidId].weiPerGas, openBids[bidId].amountOfGas, bidderId);
        }
    }

    /**
     * @dev Submit bundle hashes for a finished auction slot.
     * If the auction slot has already been submitted or is still open, the function reverts.
     * Once the submission is successful, the slot is marked as finished.
     * @param slot Slot number of the finished auction
     */
    function submitBundles(uint256 slot) external {
        if (slot <= slotFinished) return ();

        // check auction state
        (, bool isOpen, bool isSettled,,) = auctioneer.auctions(slot);
        if (isOpen) revert();
        if (!isSettled) revert();

        // check bidder info
        (uint120 itemsBought, uint128 amountOwed) = auctioneer.getBidderInfo(slot, address(this));
        if (itemsBought == 0) revert();

        // reset hashes
        delete hashes;

        // sort bids to determine who won
        uint256 bidCountLocal = bidCount;
        uint256[] memory roundBids = getBid(slot);
        LibSort.insertionSort(roundBids);
        uint256 cumAmount;
        for (uint256 bidIdx = bidCountLocal; bidIdx > 0; bidIdx--) {
            uint256 packedBid = roundBids[bidIdx - 1];
            (, uint120 amountOfGas, uint128 weiPerGas) = decodeBid(packedBid);
            uint256 amount = uint256(weiPerGas) * uint256(amountOfGas);
            cumAmount += amount;
            if (cumAmount > amountOwed) break;
            // get bidId by details
            uint256 bidId = getBidIdByDetails(amountOfGas, weiPerGas);
            Bid storage bid = openBids[bidId];
            // save hash
            hashes.push(bid.bundleHash);
            // add to won list
            wonBids[wonBidCount] = Bid(bid.amountOfGas, bid.weiPerGas, bid.bidder, bid.bundleHash);
            ++wonBidCount;
            // remove from open list
            _removeOpenBid(bidId);
        }

        slotFinished = slot;

        // approve future token spend and submit bundle hashes
        auctioneer.approve(address(house), slot, itemsBought);
        house.submitBundle(slot, itemsBought, hashes);
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

    /**
     * @dev Packed Bid details into a uint256 for submission.
     *
     * @param bidPrice Price per item.
     * @param itemsToBuy Items to buy in the auction.
     * @param bidderId Id for bidder
     * @return packedBid for auction submission
     */
    function packBid(uint128 bidPrice, uint120 itemsToBuy, uint8 bidderId) internal pure returns (uint256 packedBid) {
        packedBid = (uint256(bidPrice) << 128) + (uint256(itemsToBuy) << 8) + uint256(bidderId);
    }
}
