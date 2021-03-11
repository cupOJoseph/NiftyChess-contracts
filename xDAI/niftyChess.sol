// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

//import "https://github.com/opengsn/gsn/blob/master/packages/contracts/src/BaseRelayRecipient.sol";
import "./Proxiable.sol";
import "./NiftyDataLayout.sol";
import "./LibraryLock.sol";


contract niftyChess is ERC721, Proxiable, NiftyDataLayout, LibraryLock {
    
    function updateCode(address newCode) public {
        require(msg.sender == owner);
        updateCodeAddress(newCode);
    }
    
    constructor() public ERC721("NiftyChess", "CHESS") {
        
    }
    
    function getOwner() public view returns(address){
        return owner;
    }
    
    //============= Registry Setters ===============//
    function setBridgeMediatorAddress(address newMediatorAddress) public{
        require(msg.sender == owner, "Only owner can update this.");
        bridgeMediatorAddress = newMediatorAddress;
    }
    
    function setTokenMainAddress(address newMainAddress) public{
        require(msg.sender == owner, "Only owner can update this.");
        tokenMainAddress = newMainAddress;
    }
    
    function setTrustedForwarderAddress(address newForwarder) public{
        require(msg.sender == owner, "Only owner can update this.");
        trustedForwarderAddress = newForwarder;
    }
    //============== End Registry ===================//

    function constructor1(address mediator) public{
        owner = msg.sender;
        minter = msg.sender;
        price = 0;
        bridgeMediatorAddress = mediator;
        initialize();
        /**
        name = "NiftyChess";
        symbol = "PAWN";

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);**/
    }
    
    function lock(uint256 _tokenId) external {
      //
      require(bridgeMediatorAddress == msg.sender, 'only the bridgeMediator can lock');
      address from = ownerOf(_tokenId);
      _transfer(from, msg.sender, _tokenId);
    }

    
    function unlock(uint256 _tokenId, address _recipient) external {
      require(msg.sender == bridgeMediatorAddress, 'only the bridgeMediator can unlock');
      require(msg.sender == ownerOf(_tokenId), 'the bridgeMediator does not hold this token');
      safeTransferFrom(_msgSender(), _recipient, _tokenId);
    }

    
    function updateMinter(address newMinter) public {
        require(msg.sender == owner, "Only the owner can do that.");
        minter = newMinter;
    }
    
    function updateOwner(address newOwner) public {
        require(msg.sender == owner, "Only the owner can do that.");
        owner = newOwner;
    }
    
    function updatePrice(uint256 newPrice) public{
        require(msg.sender == owner, "Only the owner can do that.");
        price = newPrice;
    }
    

    function mintBoard(address player, string memory tokenURI, bytes32 movesHash)
        public payable
        returns (uint256)
    {
        require(msg.value >= price, "You must include the award Price in your transaction.");
        //every set of moves must be a unique hash 
        require(movesTaken[movesHash] == 0, "This game has already been minted because its hash exists in Nifty Chess.");
        
        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        games[newItemId] = movesHash;
        movesTaken[movesHash] = newItemId;
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
    
    function minterMint(address player, string memory tokenURI, bytes32 movesHash)
        public payable
        returns (uint256)
    {
        require(msg.sender == minter, "You must be the minter to do this.");
        //every set of moves must be a unique hash 
        require(movesTaken[movesHash] == 0, "This game has already been minted because its hash exists in Nifty Chess.");
        
        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        games[newItemId] = movesHash;
        movesTaken[movesHash] = newItemId;
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
    
    function tokenHashLookup(bytes32 hash) public view returns(uint256){
        return movesTaken[hash];
    }
    
    function getHashById(uint256 id) external returns(bytes32){
        return games[id];
    }
    
    function getOwnerByHash(bytes32 hash) public view returns (address){
        return ownerOf(tokenHashLookup(hash));
    }
    
    function cashOut() public{
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
    
    
    /*function _msgSender() internal override(BaseRelayRecipient, Context) view returns (address payable) {
        return BaseRelayRecipient._msgSender();
    }*/
}