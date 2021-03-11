pragma solidity ^0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC721/ERC721.sol";
import "./LibraryLockDataLayout.sol";

contract NiftyDataLayout is LibraryLockDataLayout{
    
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    mapping(bytes32 => uint256) public movesTaken;
    mapping(uint256 => bytes32) public games;
    address owner;
    address minter;
    uint256 price;
    
    address public niftyRegistry;
    uint256 public relayPrice;
    address payable public feeReceiver;
    
    address public bridgeMediatorAddress;
    address public tokenMainAddress; 
    address public trustedForwarderAddress;
}