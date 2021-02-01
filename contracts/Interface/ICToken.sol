pragma solidity 0.5.2;

contract ICToken {
    uint256 public borrowIndex;

    function accrueInterest() public;
}
