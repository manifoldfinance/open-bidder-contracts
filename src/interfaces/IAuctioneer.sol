// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAuctioneer {
    error AuctionAlreadyOpen(uint256 slot);
    error AuctionAlreadySettled(uint256 slot);
    error AuctionNotClosed(uint256 slot);
    error AuctionNotOpen(uint256 slot);
    error BidderAlreadyExists(address bidder);
    error BidderNotRegistered(address bidder);
    error InsufficientFunds();
    error InvalidBidItems();
    error InvalidId();
    error Unauthorized();

    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);
    event AuctionOpened(uint256 indexed slot, uint120 itemsForSale);
    event AuctionSettled(uint256 indexed slot);
    event BidderAdded(address indexed bidder, uint8 indexed bidderId);
    event BidderRemoved(address indexed bidder, uint8 indexed bidderId);
    event OperatorSet(address indexed owner, address indexed operator, bool approved);
    event OperatorUpdated(address indexed oldOperator, address indexed newOperator);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event Transfer(address caller, address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    function IdMap(address) external view returns (uint8);
    function WETH9() external view returns (address);
    function acceptOwnership() external;
    function accountant() external view returns (address);
    function allowance(address, address, uint256) external view returns (uint256);
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);
    function auctions(uint256) external view returns (uint120 itemsForSale, bool isOpen, bool isSettled, bool isPaidOut, bool isRefunded);
    function balanceOf(address, uint256) external view returns (uint256);
    function bid(uint256 slot, uint256[] memory packedBids) external;
    function bidderMap(uint8) external view returns (address);
    function changeOperator(address newOperator) external;
    function getBidderInfo(uint256 slot, address bidder)
        external
        view
        returns (uint120 itemsBought, uint128 amountOwed);
    function isOperator(address, address) external view returns (bool);
    function maxBidder() external view returns (uint8);
    function maxBids() external view returns (uint256);
    function minGasAmount() external view returns (uint120);
    function newBidder(address additionalBidder) external returns (uint8 newId);
    function openAuction(uint256 slot, uint120 itemsForSale) external;
    function operator() external view returns (address);
    function owner() external view returns (address);
    function packBid(uint128 bidPrice, uint120 itemsToBuy, uint8 bidderId) external pure returns (uint256 packedBid);
    function pendingOwner() external view returns (address);
    function removeBidder(uint8 bidderId) external;
    function runAndSettle(uint256 slot) external;
    function setOperator(address operator, bool approved) external returns (bool);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner) external;
    function updateAccountant(address newAccountant) external;
    function updateMaxBids(uint256 newMaxBids) external;
    function updateMinGasAmount(uint120 newAmount) external;
}
