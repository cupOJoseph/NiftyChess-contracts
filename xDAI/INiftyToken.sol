pragma solidity >=0.6.0 <0.7.0;

interface INiftyToken {
    function firstMint(address, string calldata, string calldata) external returns (uint256);
    function mintBoard(address, string calldata) external returns (uint256);
    function buyToken(uint256) external payable;
    function lock(uint256) external;
    function unlock(uint256, address) external;
    function ownerOf(uint256) external view returns (address);
    function getHashById(uint256) external returns (bytes32);
    function tokenURI(uint256) external returns (string memory);
}