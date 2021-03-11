pragma solidity ^0.6.12;

import "./Proxy.sol"; 
import "./niftyChess.sol"; 

contract Deployer {
    
    event NewContract(address _contract);
    
    address public logicA;
    address public logicB;

    address public lastDeployedProxy;
    
    function step1_launchNiftyChess(address mediator) public {
        logicA = address(new niftyChess());
        emit NewContract(logicA);
        lastDeployedProxy = address(new Proxy(abi.encodeWithSignature("constructor1(address)", mediator), logicA));
        emit NewContract(lastDeployedProxy);
        niftyChess(lastDeployedProxy).updateOwner(msg.sender);
    }
    
}