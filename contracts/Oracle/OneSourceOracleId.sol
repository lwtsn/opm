pragma solidity 0.5.2;

import {ICToken} from "../Interface/ICToken.sol";
import {IOracleId} from "../Interface/IOracleId.sol";
import {IOracleAggregator} from "../Interface/IOracleAggregator.sol";

import {WhitelistedWithGovernance} from "../Lib/WhitelistedWithGovernance.sol";
import {UsingRegistry} from "../Lib/UsingRegistry.sol";
import {UsingOraclize} from "../Lib/UsingOraclize.sol";

contract OneSourceOracleId is WhitelistedWithGovernance, IOracleId, UsingRegistry, UsingOraclize {
    event Requested(bytes32 indexed queryId, uint256 indexed timestamp);
    event Provided(bytes32 indexed queryId, uint256 indexed timestamp, uint256 result);

    mapping(bytes32 => uint256) public pendingQueries;
    mapping(bytes32 => bool) public hasData;

    string public DATA_SOURCE;

    uint256 public constant EMERGENCY_TIMELOCK = 2 days;

    uint256 public constant WHITELIST_TIMELOCK = 7 days;

    constructor(string memory _dataSource, address _registry)
        public
        UsingRegistry(_registry)
        WhitelistedWithGovernance(WHITELIST_TIMELOCK, msg.sender)
    {
        // TODO: Comment on testnet release
        // OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

        // FIXME: Uncomment when needed or move to other constructor
        // oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);

        DATA_SOURCE = _dataSource;
    }

    function fetchData(uint256 _timestamp) external payable {
        require(_timestamp > 0, "Timestamp must be nonzero");

        bytes32 queryId = oraclize_query(_timestamp, "URL", DATA_SOURCE);
        pendingQueries[queryId] = _timestamp;
        emit Requested(queryId, _timestamp);
    }

    function recursivelyFetchData(
        uint256 _timestamp,
        uint256 _period,
        uint256 _times
    ) external payable {
        require(_timestamp > 0, "Timestamp must be nonzero");

        for (uint256 i = 0; i < _times; i++) {
            uint256 moment = _timestamp + _period * i;
            bytes32 queryId = oraclize_query(moment, "URL", DATA_SOURCE);
            pendingQueries[queryId] = moment;
            emit Requested(queryId, moment);
        }
    }

    function __callback(bytes32 _queryId, string memory _result) public {
        __callback(_queryId, _result, "");
    }

    function __callback(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    ) public {
        require(msg.sender == oraclize_cbAddress(), "Only oraclize address allowed");
        require(pendingQueries[_queryId] != 0, "There was no query with this id");

        _provideDataToOracleAggregator(_queryId, _result);
        _proof;
    }

    function calculateFetchPrice() external returns (uint256) {
        return oraclize_getPrice("URL");
    }

    function emergencyCallback(bytes32 _queryId, string memory _result) public onlyWhitelisted {
        require(
            !hasData[_queryId] && (pendingQueries[_queryId] + EMERGENCY_TIMELOCK) < now,
            "Only when not data and after emergency timelock allowed"
        );

        _provideDataToOracleAggregator(_queryId, _result);
    }

    function _provideDataToOracleAggregator(bytes32 _queryId, string memory _result) internal {
        // Parse integer
        uint256 returnData = parseInt(_result, 2);
        // Convert to DAI
        returnData *= 10**16;
        IOracleAggregator(registry.getOracleAggregator()).__callback(pendingQueries[_queryId], returnData);
        hasData[_queryId] = true;
    }
}
