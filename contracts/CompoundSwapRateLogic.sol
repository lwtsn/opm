/**

  Source code of Opium Protocol: SwapRate IRS Logic
  Web https://swaprate.finance
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.5.2;
pragma experimental ABIEncoderV2;

import {ExecutableByThirdParty} from "./ExecutableByThirdParty.sol";
import {HasCommission} from "./HasCommission.sol";
import {LibDerivative} from "./Lib/LibDerivative.sol";
import {SafeMath} from "./Lib/SafeMath.sol";

import {IDerivativeLogic} from "./Interface/IDerivativeLogic.sol";
import {IERC20} from "./Interface/IERC20.sol";

// File: contracts/Logic/CompoundSwapRate/CompoundSwapRateLogic.sol

contract CompoundSwapRateLogic is IDerivativeLogic, ExecutableByThirdParty, HasCommission {
    using SafeMath for uint256;

    uint256 public constant YEAR_DAYS = 360 days;

    constructor() public {
        /*
        {
            "author": "DIB.ONE",
            "type": "swap",
            "subtype": "swaprate",
            "description": "SwapRate Compound logic contract"
        }
        */
        emit MetadataSet(
            '{"author":"DIB.ONE","type":"swap","subtype":"swaprate","description":"SwapRate Compound logic contract"}'
        );
    }

    // LONG pays floating
    // params[0] - payFixed - SHOULD BE 0
    // params[1] - fixedRate
    // params[2] -
    // params[3] -
    // params[4] -
    // params[5] -
    // params[6] -
    // params[7] -
    // params[8] -
    // params[9] -

    // SHORT pays fixed
    // params[10] - payFixed - SHOULD BE 1
    // params[11] - fixedRate
    // params[12] -
    // params[13] -
    // params[14] -
    // params[15] -
    // params[16] -
    // params[17] -
    // params[18] -
    // params[19] -

    // Settlement params
    // params[20] - fixedRate - in base of 1e18
    // params[21] - initialParam (could be `borrowIndex` or `exchangeRate`)
    // params[22] - initialTimestamp
    // params[23] - margin
    function validateInput(Derivative memory _derivative) public view returns (bool) {
        return (// Derivative
        _derivative.endTime > now &&
            _derivative.params.length == 24 &&
            // LONG
            _derivative.params[0] == 0 && // longPayFixed == 0
            _derivative.params[1] <= _derivative.params[20] && // longPayFixed <= fixedRate
            // SHORT
            _derivative.params[10] == 1 && // shortPayFixed == 1
            _derivative.params[11] >= _derivative.params[20] && // shortFixedRate >= fixedRate
            // IRS
            _derivative.params[20] > 0 && // fixedRate > 0
            _derivative.params[21] > 0 && // initialParam > 0
            _derivative.params[22] <= now && // initialTimestamp <= now
            _derivative.params[23] > 0);
    }

    function getMargin(Derivative memory _derivative) public view returns (uint256 buyerMargin, uint256 sellerMargin) {
        uint256 margin = _derivative.params[23];
        buyerMargin = margin;
        sellerMargin = margin;
    }

    function getExecutionPayout(Derivative memory _derivative, uint256 _currentParam)
        public
        view
        returns (uint256 buyerPayout, uint256 sellerPayout)
    {
        uint256 nominal = 10**IERC20(_derivative.token).decimals();

        uint256 fixedRate = _derivative.params[20];
        uint256 initialParam = _derivative.params[21];
        uint256 initialTimestamp = _derivative.params[22];
        uint256 margin = _derivative.params[23];

        // timeElapsed = endTime - initialTimestamp
        uint256 timeElapsed = _derivative.endTime.sub(initialTimestamp);

        // fixedAmount = fixedRate * nominal * timeElapsed / YEAR_DAYS / 1e18 + nominal
        uint256 fixedAmount = fixedRate.mul(nominal).mul(timeElapsed).div(YEAR_DAYS).div(10**18).add(nominal);

        // accumulatedAmount = nominal * currentParam / initialParam
        uint256 accumulatedAmount = nominal.mul(_currentParam).div(initialParam);

        uint256 profit;
        if (fixedAmount > accumulatedAmount) {
            // Buyer earns
            profit = fixedAmount - accumulatedAmount;

            if (profit > margin) {
                buyerPayout = margin.mul(2);
                sellerPayout = 0;
            } else {
                buyerPayout = margin.add(profit);
                sellerPayout = margin.sub(profit);
            }
        } else {
            // Seller earns
            profit = accumulatedAmount - fixedAmount;

            if (profit > margin) {
                buyerPayout = 0;
                sellerPayout = margin.mul(2);
            } else {
                buyerPayout = margin.sub(profit);
                sellerPayout = margin.add(profit);
            }
        }
    }

    function isPool() public view returns (bool) {
        return false;
    }

    // Override
    function thirdpartyExecutionAllowed(address derivativeOwner) public view returns (bool) {
        derivativeOwner;
        return true;
    }
}
