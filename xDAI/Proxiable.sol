pragma solidity ^0.6.12;

contract Proxiable {
// Code position in storage is bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1) = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"    
    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }
}