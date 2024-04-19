// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ISettlement {
    function submitBundle(uint256 slot, uint256 amountOfGas, bytes32[] calldata bundleHashes) external;
}
