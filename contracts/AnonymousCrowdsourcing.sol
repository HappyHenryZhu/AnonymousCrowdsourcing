// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Pedersen.sol";
import "./ZeroCoin.sol";

struct Zkp1oMWithX{
    uint x; 
    Zkp1N1 zkp1;
    Zkp1N2 zkp2;
    uint8 nbits;
}

contract AnonymousCrowdsourcing{
    //requester parameters
    address private requester;
    uint private rewardCredits;
    uint private noOfRewards;
    uint private parkingSpaceNo;
    uint private dataCount;
    uint private taskEndTime; //t_ver
    uint private refundStartTime; //t_ref
    uint Obv;
    address[] private workerStakedEther;
    uint[] public Cmm; //T_Cm(m)
    uint[] public Cmq; //T_Cm(q)
    uint[] public Tm; //T_m
    uint[] public Tq; //T_q
    uint[] public Cms; //T_Cm(s)
    uint[] public Cmqprime; //T_Cm(q')
    uint[] public revealedQPrime; //T_q'
    uint[] public Tak; //T_ak => shortlisted T_Cm(s)
    uint public akTm; //aggregated result a_k(T_m)
    //Pedersen parameters
    uint private k = 1173792922; 
    uint private q = 29645808988800697353566862307331691561207478437311896149463650348773872465515;
    uint private g = 2090583907;
    uint private h = 642996076579571851939547582363769362446679167969816015137470108219624530351;
    address payable zeroCoinAddr;
    Pedersen private pedersen;


    modifier isRequester(){
        require(msg.sender == requester);
        _;
    }

    modifier notRequester(){
        require(msg.sender != requester);
        _;
    }

    modifier endTimePast(){
        require(block.timestamp > taskEndTime, "Workers can still submit data.");
        _;
    }

    //events
    event AcceptingData();
    event ProvingData(address addr);
    event etherRefund(address addr, uint amount);
    event AggregatedData();
    event RewardGenerated();
    event Withdrawn();
    event CreditsIncreased();
    event CreditsReceived(address addr, uint value);
    //constructor
    constructor(uint _parkingSpaceNo, uint _sensingTime, uint _refundTime, address payable _zeroCoinAddr) payable{
        require (msg.value > 0 ether, "Please send credits for rewards.");
        rewardCredits = msg.value;
        noOfRewards = rewardCredits/1e18;
        parkingSpaceNo = _parkingSpaceNo;
        requester = msg.sender;
        taskEndTime = block.timestamp + _sensingTime; //t_ver
        refundStartTime = block.timestamp + _refundTime; //t_ref
        zeroCoinAddr = _zeroCoinAddr;
        pedersen = new Pedersen(g,h,q,k);
    }

    function getAggregatedResults() public isRequester returns(string memory){
        uint countAvailable = 0;
        uint countUnavailable = 0;
        string memory result;
        for (uint i = 0; i < Tm.length; i++) {  
            if (Tm[i] == 1){
                countAvailable ++;
            }else if (Tm[i] == 0){
                countUnavailable ++;
            }
        }

        if (countAvailable >= countUnavailable){
            akTm = 1; //For simplicity, we consider this situation as available. 
            result = "Available";
        } else {
            akTm = 0;
            result = "Unavailable";
        }

        for(uint j = 0; j < Tm.length; j ++){
            if(Tm[j] == akTm && Tak.length < noOfRewards){
                Tak.push(Cms[j]);
            }
        }
        //mint new coins on behalf of workers
        mintNewCoin(zeroCoinAddr, Tak);
        // refund requester the ether(s) left
        if(Tak.length < noOfRewards){
            uint ethersLeft = (noOfRewards - Tak.length)*1e18; 
            payable(requester).transfer(ethersLeft);
        }

        return result;
    }

    function mintNewCoin(address payable addrZoinCoin, uint[] memory coins) internal {
        ZeroCoin ZC = ZeroCoin(addrZoinCoin);
        for(uint i = 0; i < coins.length; i++){
            ZC.mint{value: 1 ether}(coins[i]);
        }
        
    }

    function getDataCount() public isRequester returns(uint){
        dataCount = Tm.length;
        return dataCount;
    }
    // requester can add more rewards
    function addRewardCredits() public isRequester payable{
        rewardCredits += msg.value;
        noOfRewards = rewardCredits/1e18;
        emit CreditsIncreased();
    }

    // workers' functions
    function getSensingTask() public view returns(uint, uint, uint, uint){
        return (parkingSpaceNo, taskEndTime, refundStartTime, noOfRewards);
    }

    function submitSensingData(ZkpCm memory Cm1, ZkpCm memory Cm2) public notRequester payable{
        require (msg.value == 1 ether, "You need to stake 1 Ether to submit data!"); //workers need to stake 1 ether in order to submit data
        require (pedersen.verifyZkpCm(Cm1) == true && pedersen.verifyZkpCm(Cm2) == true);
        workerStakedEther.push(msg.sender);
        uint Cm = Cm1.c;
        uint Cq = Cm2.c;
        Cmm.push(Cm);
        Cmq.push(Cq);
    }

    function proveSubmittedData(uint obs, Zkp1N1 memory zkp1obs, Zkp1N2 memory zkp2obs, uint8 nbitsobs, uint _q, Zkp1N1 memory zkp1q, Zkp1N2 memory zkp2q, uint8 nbitsq, uint _Cms, ZkpCm memory _Cmqprime ) public notRequester { //prove the committed value 
        require(pedersen.verifyZkpOneOfMany(zkp1obs,zkp2obs,nbitsobs) == true);
        require(pedersen.verifyZkpOneOfMany(zkp1q, zkp2q,nbitsq) == true);
        require(pedersen.verifyZkpCm(_Cmqprime) == true);
        require(obs == 1 || obs == 0);
        for(uint i = 0; i < Tq.length; i ++){ //check q has been revealed or not
            require(Tq[i] != _q, "q has been revealed before");
        }
        Tm.push(obs);
        Tq.push(_q);
        Cms.push(_Cms);
        Cmqprime.push(_Cmqprime.c);
        emit ProvingData(msg.sender);
    }


    function getEtherBack(uint _qprime, Zkp1N1 memory zkp1qprime, Zkp1N2 memory zkp2qprime, uint8 nbitsqprime) public notRequester{
        for(uint i = 0; i < revealedQPrime.length; i++){
            require(revealedQPrime[i] != _qprime);
        }
        require(pedersen.verifyZkpOneOfMany(zkp1qprime, zkp2qprime, nbitsqprime) == true);
        revealedQPrime.push(_qprime);
        payable(msg.sender).transfer(1 ether);
        emit etherRefund(msg.sender, 1 ether);
    }
    //fallback function
    receive() payable external{
        emit CreditsReceived(msg.sender, msg.value);
    }
}