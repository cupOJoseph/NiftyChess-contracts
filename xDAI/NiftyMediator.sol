pragma solidity >=0.6.0 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/access/Ownable.sol";
import "./AMBMediator.sol";
import "./INiftyToken.sol";

contract NiftyMediator is Ownable, AMBMediator {

    constructor() public {
    }

    event tokenSentViaBridge(uint256 _tokenId, bytes32 _msgId);
    event failedMessageFixed(bytes32 _msgId, address _recipient, uint256 _tokenId);
    event newPrice(uint256 price);

    uint256 public relayPrice;
    address public niftyChessAddress;
    address payable public feeReceiverAddress;
    
    function setFeeR(address payable feeReceiver) public onlyOwner{
        feeReceiverAddress = feeReceiver;
    }
    
    function setNiftyChessAddress(address tokenAddress) public onlyOwner{
        niftyChessAddress = tokenAddress;
    }

    function setRelayPrice(uint256 _price) public onlyOwner {
      relayPrice = _price;
      emit newPrice(_price);
    }


    function niftyToken() private view returns (INiftyToken) {
      return INiftyToken(niftyChessAddress);
    }


    mapping (bytes32 => uint256) private msgTokenId;
    mapping (bytes32 => address) private msgRecipient;

    function _relayToken(uint256 _tokenId) internal returns (bytes32) {
      niftyToken().lock(_tokenId);
        
      bytes32 gameHash = niftyToken().getHashById(_tokenId);
      string memory tokenURI = niftyToken().tokenURI(_tokenId);

      bytes4 methodSelector = ITokenManagement(address(0)).mint.selector;
      bytes memory data = abi.encodeWithSelector(methodSelector,msg.sender, _tokenId, tokenURI, gameHash);
      bytes32 msgId = bridgeContract().requireToPassMessage(
          mediatorContractOnOtherSide(),
          data,
          requestGasLimit
      );

      msgTokenId[msgId] = _tokenId;
      msgRecipient[msgId] = _msgSender();

      emit tokenSentViaBridge(_tokenId, msgId);

      return msgId;
    }

    function relayToken(uint256 _tokenId) external payable returns (bytes32) {
      require(msg.sender == niftyToken().ownerOf(_tokenId), 'only the owner can upgrade!');
      require(msg.value >= relayPrice, "Amount sent too small");
      feeReceiverAddress.transfer(msg.value);

      return _relayToken(_tokenId);
    }

    function fixFailedMessage(bytes32 _msgId) external {
      require(msg.sender == address(bridgeContract()));
      require(bridgeContract().messageSender() == mediatorContractOnOtherSide());
      require(!messageFixed[_msgId]);

      address _recipient = msgRecipient[_msgId];
      uint256 _tokenId = msgTokenId[_msgId];

      messageFixed[_msgId] = true;
      niftyToken().unlock(_tokenId, _recipient);

      emit failedMessageFixed(_msgId, _recipient, _tokenId);
    }


  	
  	address public trustedForwarder;

    function setTrustedForwarder(address _trustedForwarder) public onlyOwner {
      trustedForwarder = _trustedForwarder;
    }

    function getTrustedForwarder() public view returns(address) {
      return trustedForwarder;
    }

}
 