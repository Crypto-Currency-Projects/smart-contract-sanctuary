pragma solidity ^0.4.24;

contract AutomatedExchange{
  function buyTokens() public payable;
  function calculateTokenSell(uint256 tokens) public view returns(uint256);
  function calculateTokenBuy(uint256 eth,uint256 contractBalance) public view returns(uint256);
  function balanceOf(address tokenOwner) public view returns (uint balance);
}
contract VerifyToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    bool public activated;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
contract VRFBet is ApproveAndCallFallBack{
  using SafeMath for uint;
  struct Bet{
    uint blockPlaced;
    address bettor;
    uint betAmount;
  }
  mapping(uint => Bet) betQueue;
  uint public MAX_SIMULTANEOUS_BETS=20;
  uint public index=0;//index for processing bets
  uint public indexBetPlace=0;//index for placing bets
  address vrfAddress=0xe0832c4f024D2427bBC6BD0C4931096d2ab5CCaF; //0x5BD574410F3A2dA202bABBa1609330Db02aD64C2;
  VerifyToken vrfcontract=VerifyToken(vrfAddress);
  AutomatedExchange exchangecontract=AutomatedExchange(0x3F48Ad253D25aC0be2e357a9eBFED72313C4a9E8);

  event Payout(address indexed to, uint tokens);

  //Send tokens with ApproveAndCallFallBack, place a bet
  function receiveApproval(address from, uint256 tokens, address token, bytes data) public{
      require(msg.sender==vrfAddress);
      vrfcontract.transferFrom(from,this,tokens);
      _placeBet(tokens,from);
  }
  function placeBetEth() public payable{
    require(indexBetPlace-index<MAX_SIMULTANEOUS_BETS);//ensures you don&#39;t get a situation where there are too many existing bets to process, locking VRF in the contract
    uint tokensBefore=vrfcontract.balanceOf(this);
    exchangecontract.buyTokens.value(msg.value)();
    _placeBet(vrfcontract.balanceOf(this).sub(tokensBefore),msg.sender);
  }

/*


  REMOVE THIS FUNCTION BEFORE DEPLOYING IT IS ONLY FOR TESTING IT WILL MESS EVERYTHING UP

  ALSO SWAP THE COMMENTS IN PAYOUT

*/
  //function placeBetTESTONLY(uint numTokens){
  //  _placeBet(numTokens,msg.sender);
  //}
  function payout(address to,uint numTokens){
    vrfcontract.transfer(to,numTokens);
    //emit Payout(to,numTokens);
  }
  function _placeBet(uint numTokens,address from) private{
    resolvePriorBets();
    betQueue[indexBetPlace]=Bet({blockPlaced:block.number,bettor:from,betAmount:numTokens});
    indexBetPlace+=1;
  }
  function resolvePriorBets() public{
    while(betQueue[index].blockPlaced!=0){
      if(betQueue[index+1].blockPlaced!=0){
        if(betQueue[index+1].blockPlaced+250>block.number){//bet is not expired
          if(block.number>betQueue[index+1].blockPlaced){//bet was in the past, future blockhash can be safely used to compute random

          /*
            Bet is between two players.
            Outcome is computed as whether rand(bet1+bet2)<bet1. This makes the probability of winning proportional to the size of your bet, ensuring all bets are EV neutral.
          */
            uint totalbet=betQueue[index].betAmount+betQueue[index+1].betAmount;
            uint randval= random(totalbet,betQueue[index+1].blockPlaced,betQueue[index+1].bettor);
            if(randval < betQueue[index].betAmount){
              payout(betQueue[index].bettor,totalbet);
            }
            else{
              payout(betQueue[index+1].bettor,totalbet);
            }
            index+=2;
          }
          else{ //bet is in the current block, cannot be resolved, no point in continuing the loop
            return;
          }
        }
        else{//bet has expired, return tokens to users
          payout(betQueue[index+1].bettor,betQueue[index+1].betAmount);
          payout(betQueue[index].bettor,betQueue[index].betAmount);
          index+=2;
        }
      }
      else{ //single bet with no other to pair it to, must wait for another bet
        return;
      }
    }
  }
  function cancelBet() public{
    resolvePriorBets();
    require(indexBetPlace-index==1 && betQueue[index].bettor==msg.sender);
    index+=1;//skip the last remaining bet
  }
  /*
    requires an odd number of bets and your bet is the last one
  */
  function canCancelBet() public view returns(bool){
    return indexBetPlace>0 && !isEven(indexBetPlace-index) && betQueue[indexBetPlace-1].bettor==msg.sender;
  }
  function isEven(uint num) public view returns(bool){
    return 2*(num/2)==num;
  }
  function maxRandom(uint blockn, address entropy)
    internal
    returns (uint256 randomNumber)
  {
      return uint256(keccak256(
          abi.encodePacked(
            blockhash(blockn),
            entropy)
      ));
  }
  function random(uint256 upper, uint256 blockn, address entropy)
    internal
    returns (uint256 randomNumber)
  {
      return maxRandom(blockn, entropy) % upper + 1;
  }
}
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}