pragma solidity >=0.6.0 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC721/IERC721Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/utils/Counters.sol";
import "./AMBMediator.sol";
import "./ITokenManagement.sol";
import "./IAMB.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC20/IERC20.sol";


contract NiftyMain is ERC721, Ownable, AMBMediator, IERC721Receiver {
    
    address mainRelayer;
    address ownerChess;
    
    address openSeaTokenContract;
    
    using Counters for Counters.Counter;
    Counters.Counter public reverseTokenId;
    
    uint256 top = type(uint256).max;


    constructor() ERC721("Nifty Chess", "CHESS") public {
      _setBaseURI('ipfs://ipfs/');
      mainRelayer = 0x0000000000000000000000000000000000000000;
      openSeaTokenContract = 0x0000000000000000000000000000000000000000;
      ownerChess = msg.sender;
    }
    
    event rescuedERC20Tokens(address tokenAddress, address to, uint amount);
    event mintedGame(uint256 id, string gameURL, bytes32 gameHash, address to, bytes32 msgId);
    event redeemedOS(address user, uint256 tokenID, string URI);

    mapping (bytes32 => EnumerableSet.UintSet) private _gameTokens;
    mapping (uint256 => bytes32) public tokenGame;
    

    function mint(address to, uint256 tokenId, bytes32 _gameHash, string calldata gameURL) external returns (uint256) {
      require(msg.sender == address(bridgeContract()));
      require(bridgeContract().messageSender() == mediatorContractOnOtherSide());

      _gameTokens[_gameHash].add(tokenId); //make games lookup able by hash
      tokenGame[tokenId] = _gameHash;
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, gameURL);
      bytes32 msgId = messageId();


      emit mintedGame(tokenId, gameURL, _gameHash, to, msgId);

      return tokenId;
    }

    function gameTokenCount(bytes32 _gamehash) public view returns(uint256) {
      return _gameTokens[_gamehash].length();
    }

    function gameTokenByIndex(bytes32 _gamehash, uint256 index) public view returns (uint256) {
      return _gameTokens[_gamehash].at(index);
    }
    
    //======== for future use with unimplimented main net relayer to send back to xdai. ========//
    function downgradeToXdai(address to, uint256 tokenId) public{
        require(mainRelayer != 0x0000000000000000000000000000000000000000 , "No mainRelayer Set.");
        require(msg.sender == ownerOf(tokenId)); //you are allowed to move this token 
        require(mainRelayer == to); //you have to send to the to address.
        
    }
    
    //update mainRelayer address. owner only
    function setMainRelayer(address newRelayer) public{
        require(msg.sender == ownerChess);
        mainRelayer = newRelayer;
    }
    
    //============ OpenSea Controller ============//
    
    function setOpenSeaContract(address newOS) public{
        require(msg.sender == ownerChess);
        openSeaTokenContract = newOS;
    }
    
    function getOpenSeaContract() public view returns(address){
        return openSeaTokenContract;
    }
    
    
    
    //required.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) override
    public virtual returns (bytes4){
        
        return 0x150b7a02;
    }
    
    //user has to approve this contract to move their 721s on OSea.
    function redeemFromOS(uint _id) public{
        //create 721 object for OS contract
        IERC721 OSea = IERC721(openSeaTokenContract);
        require(OSea.ownerOf(_id) == msg.sender, "You can't redeem a token you don't own.");//sender owns their transfering token
        
        //move, with users permission, to here. There is no generic 721 transfer function on this contract, 
        //so NFTs are essentially burned by sending them here
        OSea.safeTransferFrom(msg.sender, address(this), _id); //address here must be payable
        
        //Get metadata from opensea. 
        //see https://docs.opensea.io/docs/metadata-standards
        string memory data = OSea.tokenURI(_id);
       
        //mainnet NFT id's are top (2^256)-1 - counter, to avoid any possible overlap with tokens moved from xdai
        uint256 niftyID = top - reverseTokenId;
        
        // mint a new token for use here, using same metadata.
        //also emit.
        _gameTokens[bytes32(data)].add(niftyID); //make games lookup able by hash
        tokenGame[niftyID] = bytes32(data);
        _safeMint(msg.sender, niftyID);
        _setTokenURI(niftyID, data);
        bytes32 msgId = messageId();

    }
    
    
    // ==== optional erc20 rescue function === //
    function rescueERC20(address tokenAddress, address to, uint amount) public {
        require(msg.sender == ownerChess);
        IERC20 c = IERC20(tokenAddress);
        
        c.transfer(to, amount);
        emit rescuedERC20Tokens(tokenAddress, to, amount);
    }

}