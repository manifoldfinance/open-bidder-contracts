// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IBidder {
    /**
     * @dev Get the bid from a bidder for a specific slot and round.
     * @param slot The auction slot.
     * @return packedBids Array of bids (in a packed format). uint256(uint128(bidPrice),uint120(itemsToBuy),uint8(bidderId))
     */
    function getBid(uint256 slot) external view returns (uint256[] memory packedBids);
}
