pragma solidity ^0.5.0;

contract Fundraiser {
    address public owner;
    
    struct Request {
        address payable recipient;
        uint amount;
        string cause;
        bool complete;
        uint approvalCount;
        mapping (address => bool) approvals;
    }
    
    mapping (uint => Request) private requests;
    uint[] public pendingRequests;
    uint private requestIdx;
    
    uint public MIN_CONTRIBUTIONS = 10;
    mapping(address => bool) public donors;
    uint public donorsCount;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyDonor(){
        require(msg.sender == owner || donors[msg.sender] == true);
        _;
    }
    
    event RequestCreated(address from, address recipient, uint amount, uint requestId);
    event RequestCompleted(address from, address recipient, uint amount, uint requestId);
    
    function donate() payable public {
        require(msg.value > MIN_CONTRIBUTIONS);
        donors[msg.sender] = true;
        donorsCount += 1;
    }
    function createRequest(address payable _recipient, uint _amount, string memory _cause) public onlyOwner {
        require(_amount <= MIN_CONTRIBUTIONS);
        uint requestId = requestIdx + 1;
        Request memory newRequest;
        newRequest.recipient = _recipient;
        newRequest.amount = _amount;
        newRequest.cause = _cause;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
        
        requests[requestId] = newRequest;
        pendingRequests.push(requestId);
        emit RequestCreated(msg.sender, _recipient, _amount, requestId);
    }
    function approveRequest(uint _requestId) public {
        Request storage request = requests[_requestId];
        require(donors[msg.sender]);
        require(!request.approvals[msg.sender]);
        request.approvals[msg.sender] = true;
        request.approvalCount += 1;
    }
    function finalizeRequest(uint _requestId) public payable onlyDonor {
        Request storage request= requests[_requestId] ;
        require(!request.complete);
        request.recipient.transfer(request.amount);
        request.complete = true;
        emit RequestCompleted(msg.sender, request.recipient,request.amount, _requestId);
    }
    function deleteRequest (uint _requestId) onlyOwner public {
        uint8 replace = 0;
        for (uint i=0 ; i< pendingRequests.length; i++) {
            if (1 == replace) {
                pendingRequests[i-1] = pendingRequests[i];
            }
            else if(_requestId == pendingRequests[i]) {
                replace =1;
            }
        }
        delete pendingRequests[pendingRequests.length -1 ];
        pendingRequests.length -=1 ;
        delete requests[_requestId];
    }
    
    //for viewing purpose
    function getReport() view public returns ( uint, uint, uint, address) {
        return ( address(this).balance, pendingRequests.length, donorsCount, owner);
    }
    
}