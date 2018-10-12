pragma solidity ^0.4.25;

contract ERC20 {
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
}

contract XEXHolder{
    mapping(uint=>address) private holders_;
    uint private holdersCount_;

    address private token_;
    uint256 private transactionNonce_;
    address private transactionTo_;
    uint256 private transactionValue_;
    mapping(uint=>bool) private transactionConfirms_;

    event HolderAdded(address indexed _address);
    event HolderRemoved(address indexed _address);
    event TransactionStarted(address indexed _address,uint _value);
    event TransactionConfirmed(address indexed _address);
    event TransactionSubmitted(address indexed _address,uint _value);
    
    modifier onlyHolder() {
        require(isHolder(msg.sender));
        _;
    }
    
    constructor() public{
        token_ = address(0x577Ee78c1E792506Be3524bDdaC932B1f1C262C7);
        holders_[holdersCount_]=msg.sender;
        holdersCount_++;
    }
    
    function startTransaction(address _address, uint256 _value) public onlyHolder{
        require(_address != address(0) && _value > 0);

        transactionNonce_ = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
        transactionTo_ = _address;
        transactionValue_ = _value;

        for(uint i=0;i<holdersCount_;i++) {
            if(holders_[i]==address(0)){
                transactionConfirms_[i]=true;
            }else if(holders_[i]==msg.sender){
                transactionConfirms_[i]=true;
            }else{
                transactionConfirms_[i]=false;
            }
        }
        
        emit TransactionStarted(_address,_value);
    }
    
    function showTransaction() public onlyHolder view returns(address _address, uint256 _value,uint256 _nonce){
        return (transactionTo_,transactionValue_,transactionNonce_);
    }

    function confirmTransaction(uint256 _nonce) public onlyHolder{
        require(transactionNonce_==_nonce);
        
        for(uint i=0;i<holdersCount_;i++) {
            if(holders_[i]==msg.sender){
                transactionConfirms_[i]=true;
                emit TransactionConfirmed(msg.sender);
                break;
            }
        }
    }

    function submitTransaction() public onlyHolder{
        require(transactionTo_ != address(0) && transactionValue_ > 0);
        
        for(uint i=0;i<holdersCount_;i++) {
            require(transactionConfirms_[i]);
        }
        
        ERC20 _token = ERC20(token_);
        _token.approve(this, transactionValue_);
        _token.transferFrom(this,transactionTo_,transactionValue_);
        
        emit TransactionSubmitted(transactionTo_,transactionValue_);
        
        transactionTo_=address(0);
        transactionValue_=0;
    }

    function isHolder(address _address) public view returns (bool) {
        if(_address==address(0)){
            return false;
        }
        for(uint i=0;i<holdersCount_;i++) {
            if(holders_[i]==_address){
                return true;
            }
        }
        return false;
    }

    function addHolder(address _address) public onlyHolder{
        require(_address!=address(0));

        if(isHolder(_address)){
            return;
        }

        holders_[holdersCount_]=_address;
        holdersCount_++;
        emit HolderAdded(_address);
    }
    
    function renouncePauser() public onlyHolder {
        for(uint i=0;i<holdersCount_;i++) {
            if(holders_[i] == msg.sender){
                holders_[i]=address(0);
            }
        }
        emit HolderRemoved(msg.sender);
    }
}