pragma solidity ^0.7.0;
contract TaxiShare{
   
    struct Participant{ 
        address payable participantId;
        uint balance;
        bool isVoted;
    }
    
    struct TaxiDriver {   // 1 taxi driver and salary
        address payable driveId;
        uint salary;
        uint account;
        uint approvalState;
        uint salaryTime;
    }
    
    struct ProposedCar{ // such as CarID, price, offer valid time and approval state (to 0)
        uint carID;
        uint price;
        uint validTime;
        uint approvalState;
        uint expenseDay;
    }
    
    address payable manager; // a manager that is decided offline who creates the contract initially.
    address payable carDealer; // An identity to buy/sell car, also handles maintenance and tax
    
    uint fixxedExpenses = 10 ether;// In an every 6 months
    uint contractBalance; //Current total money in the contract that has not been distributed
    uint participationFee = 100 ether ; // An amount that participants needs to pay for entering the taxi business, it is fixed and 100 Ether.
    uint driverCount;
    uint dividendTime;
    
    
    Participant[] participants;
    
    ProposedCar ownedCar; /* identified with a 32 digit number, CarID  bence string tutmak daha mantikli*/
    ProposedCar proposedCar;
    ProposedCar proposedPurchasedCar;
    

    TaxiDriver proposedTaxiDriver;
    TaxiDriver taxiDriver;
    
    
    
    /*Constructor ,construct to initial values*/
    
    constructor() public{  // sets the manager and other initial values for state variables
        manager = msg.sender;
        contractBalance = 0 ether;
        driverCount = 0;
        dividendTime = block.timestamp ; 
    }
    
    /*I used msg ,it corresponds to information of caller
    Called by participants, max 9  poeple,Participants needs to pay the participation fee set in the contract to be a member in the taxi investment*/
    
    function join() public payable{
        
        require(participants.length < 9,'Only 9 people can join,not enough empty space');
        require(msg.value == participationFee,'You should send exactly 100 ether for join'); 
        // 1 ether = 10^18 wei so fee is 100 ether but msg.value returns wei, so I adjusted to numbers
        
        contractBalance += participationFee; //contractBalance keeps value of money as ether
        participants.push(Participant(msg.sender,0,false));
        
    }
    
    /* Only Manager can call this function, Sets the CarDealer’s address */
    function setCarDealer(address payable newCarDealer ) public{
        
        require(msg.sender == manager,' Only manager can set car dealer ');
        carDealer = newCarDealer;    
    } 
    /*Only CarDealer can call this, sets Proposed Car values, such as CarID, price, offer valid time and approval state (to 0)
    I assume that there is one car in proposed situation*/
    /*I tested on Remix you should use valit time as seconds like 600 sec as 10 min */
    function carProposeToBusiness(uint  carId, uint  price , uint  validTime) public{
        require(msg.sender == carDealer,' Only car dealer can propose car to Business ');
        
        uint offerTime = validTime  + block.timestamp;
        
        proposedCar = ProposedCar(carId,price,offerTime,0,block.timestamp);
        
        for (uint i = 0 ; i < participants.length; i++){//Reinitialize for every new proposal
            participants[i].isVoted = false;
        }
        
    }
    /*Participants can call this function, approves the Proposed Purchase with incrementing the approval
    state. Each participant can increment once.*/
    function approvePurchaseCar() public {
        
        for (uint i = 0 ; i < participants.length; i++){
            if(msg.sender == participants[i].participantId){//Only use participants I didnt track of addresses in a array so ,i solved with this way
                
                if(participants[i].isVoted == false){// If s/he never used vote
                    
                    proposedCar.approvalState++;//approvalState is incremented by 1
                    participants[i].isVoted = true;// s/he used vote
                    
                    break;
                    }
                }
                
            
            }
    }
    /*Only Manager can call this function, sends the CarDealer the price of the proposed car if the offer valid
    time is not passed yet and approval state is approved by more than half of the participants.*/
    
    function purchaseCar()  public payable {
        require(msg.sender == manager,'Only manager purchase a car');
        require(block.timestamp < proposedCar.validTime,"Proposed Car's valid time passed");                // 0.7.0 higher user block.timestap instead of now 
        require(proposedCar.approvalState > participants.length / 2,'Majority cannot be achieved'); //It should be 50 + 1
        if(contractBalance >= proposedCar.price){// Ethere donuyor mu kendi baba burasi nasil olacak
            
            carDealer.transfer(proposedCar.price* (10**18));//Etherium Conversion wei to ether you should enter the price of propose car 100 that means 100 ether
            contractBalance-= proposedCar.price* (10**18);
        }
        
        
        ownedCar.carID = proposedCar.carID;
        ownedCar.price = proposedCar.price* (10**18);
        ownedCar.expenseDay = block.timestamp;
        delete proposedCar;
        
    }
    
    /*Only CarDealer can call this, sets Proposed Purchase values, such as CarID, price, offer valid time and approval state (to 0)*/
    
    function RepurchaseCarPropose(uint256 carId, uint price, uint validTime) public{
        require(msg.sender == carDealer,'Only CarDealer can repurchase propose');
        uint offerTime = validTime  + block.timestamp;
        proposedPurchasedCar = ProposedCar(carId,price,offerTime,0,block.timestamp);
        
        for (uint i = 0 ; i < participants.length; i++){//Reinitialize for new proposal
            participants[i].isVoted = false;
        }
    }
    /*Participants can call this function, approves the Proposed Sell with incrementing the approval state. Each participant can increment once.*/
    
    function approveSellProposal() public{
        for (uint i = 0 ; i < participants.length; i++){
            if(msg.sender == participants[i].participantId){//Only participants join this approvement operation
                
                if(participants[i].isVoted == false){// If s/he never used vote
                    
                    proposedPurchasedCar.approvalState++;//approvalState is incremented by 1
                    participants[i].isVoted = true;// s/he used vote
                    
                    break;
                    }
                }
            }    
    }
    /*Only CarDealer can call this function, sends the proposed car price to contract if the offer valid time is
    not passed yet and approval state is approved by more than half of the participants*/
    function repurchaseCar() public{//I guess, It is selling process
        require(msg.sender == carDealer,'Only car dealer repurchase car');
        require(block.timestamp < proposedPurchasedCar.validTime,"Proposed Car's valid time passed");
        require(proposedPurchasedCar.approvalState > (participants.length / 2),'Majority cannot be achieved');
        
        contractBalance += proposedPurchasedCar.price * (10**18);
        
        delete ownedCar;
        delete proposedPurchasedCar;
    }
    /*Only Manager can call this function, sets driver address, and salary.*/
    
    function proposeDriver(address payable driverId,uint salary) public{
        require(msg.sender == manager,'Only manager propose driver');
        proposedTaxiDriver.driveId = driverId;
        proposedTaxiDriver.salary = salary;
        proposedTaxiDriver.approvalState = 0;
        
        for (uint i = 0 ; i < participants.length; i++){//Reinitialize for new proposal
            participants[i].isVoted = false;
        }
    }
    /*Participants can call this function, approves the Proposed Driver with incrementing the approval state.
    Each participant can increment once.*/
    
    function approveDriver() public{
        for (uint i = 0 ; i < participants.length; i++){
            if(msg.sender == participants[i].participantId){//Only participants join this approvement operation
                
                if(participants[i].isVoted == false){// If s/he never used vote
                    
                    proposedTaxiDriver.approvalState++;//approvalState is incremented by 1
                    participants[i].isVoted = true;// s/he used vote
                    
                    break;
                    }
                }
        }    
    }
    /*Only Manager can call this function, sets the Driver info if approval state is approved by more than half of the participants. Assume there is only 1 driver. */
    function setDriver() public{
        require(msg.sender == manager,'Only manager can set driver');
        require(driverCount == 0,'There is only 1 driver quota.');
        require(proposedTaxiDriver.approvalState > (participants.length / 2),'Majority cannot be achieved');
        
        taxiDriver.driveId = proposedTaxiDriver.driveId;
        taxiDriver.salary = proposedTaxiDriver.salary;
        taxiDriver.salaryTime = block.timestamp;
        
        delete proposedTaxiDriver;
        driverCount++;
    }
    /*Only Manager can call this function, gives the full month of salary to current driver’s account.*/
    
    function fireDriver() public{
        taxiDriver.account += taxiDriver.salary * (10**18);
        contractBalance -= taxiDriver.salary * (10**18);
        delete taxiDriver;
        driverCount = 0;
    }
    /*Public, customers who use the taxi pays their ticket through this function. Charge is sent to contract.Takes no parameter*/
    
    function payTaxiCharge() public payable{
        contractBalance += msg.value; //wei to ether,transcation process as ether
       
    }
    
    /*Only Manager can call this function, releases the salary of the Driver to his/her account monthly. Make
    sure Manager is not calling this function more than once in a month.*/
    function releaseSalary() public{
        require(msg.sender == manager,'Only manager can release salary');
        
        if((block.timestamp - taxiDriver.salaryTime) >= 30 days ){
            
            taxiDriver.salaryTime = block.timestamp;
            contractBalance -= taxiDriver.salary  * (10**18) ;
            taxiDriver.account += taxiDriver.salary  * (10**18);
            
        }
        
    }
    
    /*Only Driver can call this function, if there is any money in Driver’s account, it will be send to his/her address*/
    function GetSalary() public payable{
        require(msg.sender == taxiDriver.driveId,'Only taxi driver can demands his/her salary');
        if(taxiDriver.account>0){
            
            taxiDriver.driveId.transfer(taxiDriver.account);
            taxiDriver.account = 0;
            
        }
    }
    /*Only Manager can call this function, sends the CarDealer the price of the expenses every 6 month.
    Make sure Manager is not calling this function more than once in the last 6 months*/    
    
    function PayCarExpenses()  public {
        require(msg.sender == manager,'Only manager can pay car expenses');
        if((block.timestamp - ownedCar.expenseDay) >= 180 days ){
            carDealer.transfer(fixxedExpenses);
            contractBalance-= fixxedExpenses;
            ownedCar.expenseDay = block.timestamp;
        }
        
        
    }
    /*Only Manager can call this function, calculates the total profit after expenses and Driver salaries,
    calculates the profit per participant and releases this amount to participants in every 6 month. Make sure
    Manager is not calling this function more than once in the last 6 months.*/
    function PayDividend() public payable{
        require(msg.sender == manager,'Only manager can pay dividend');
        //expenses and driver salary paid

        releaseSalary();
        PayCarExpenses();
        
        if(block.timestamp - dividendTime > 180 days){
            if(contractBalance > 0){
                dividendTime = block.timestamp;
                uint per_participant = contractBalance / participants.length;
                for (uint i = 0 ; i < participants.length ; i++){
                    participants[i].balance+= per_participant;
                    contractBalance-= per_participant;
                }    
            }
            
        }        
                
                
    }
    /* GetDividend:
    Only Participants can call this function, if there is any money in participants’ account, it will be send to
    his/her address*/
    
    function getDividend() public payable{
        for (uint i = 0 ; i < participants.length; i++){
            if(msg.sender == participants[i].participantId){ //Only participants join this approvement operation
                
                if(participants[i].balance>0){
                    
                    participants[i].participantId.transfer(participants[i].balance);
                    participants[i].balance = 0 ;
                }
                
               
            }    
        } 
    
    }

    fallback() external {
        revert ();
    }
}
