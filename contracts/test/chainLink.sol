// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract chainLink{
    function getRoundData(
        uint
    ) external view returns (uint, int256, uint, uint256, uint) {
        return (1e8, 1e8, 1e8, block.timestamp, 1);
    }
}