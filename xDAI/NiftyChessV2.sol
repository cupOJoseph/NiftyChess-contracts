pragma solidity ^0.6.12;

import "./niftyChess.sol";

contract NiftyChessV2 is niftyChess {
    function newMintFunction() public pure returns (uint256) {
        return 1;
    }
}