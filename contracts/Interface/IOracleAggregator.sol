pragma solidity 0.5.2;

interface IOracleAggregator {
    function __callback(uint256 query, uint256 returnData) external;
}
