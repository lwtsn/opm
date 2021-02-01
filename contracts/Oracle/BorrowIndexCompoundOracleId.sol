pragma solidity 0.5.2;

import {ICToken} from "../Interface/ICToken.sol";
import {IOracleAggregator} from "../Interface/IOracleAggregator.sol";
import {OneSourceOracleId} from "./OneSourceOracleId.sol";

contract BorrowIndexCompoundOracleId is OneSourceOracleId {
    ICToken cToken;

    constructor(ICToken _cToken, address _registry) public OneSourceOracleId("", _registry) {
        cToken = _cToken;
        /*
        {
            "author": "DIB.ONE",
            "description": "Compound borrow index",
            "asset": "CMP-BRI",
            "type": "onchain",
            "source": "compound",
            "logic": "none",
            "path": "cToken.borrowIndex()"
        }
        */
        emit MetadataSet(
            '{"author":"DIB.ONE","description":"Compound borrow index","asset":"CMP-BRI","type":"onchain","source":"compound","logic":"none","path":"cToken.borrowIndex()"}'
        );
    }

    function _provideDataToOracleAggregator(bytes32 _queryId, string memory _result) internal {
        cToken.accrueInterest();

        uint256 result = cToken.borrowIndex();

        IOracleAggregator(registry.getOracleAggregator()).__callback(pendingQueries[_queryId], result);

        hasData[_queryId] = true;

        emit Provided(_queryId, pendingQueries[_queryId], result);

        _result;
    }
}
