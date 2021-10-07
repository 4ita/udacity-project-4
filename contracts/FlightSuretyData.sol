pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    // Each airline need to fund 10ETH at least
    uint256 private constant MINIMUM_THRESHOLD_OF_FUND = 10 ether;

    address[] registeredAirlines = new address[](0);
    // Can only be called from FlightSuretyApp contract
    mapping(address => uint256) private authorizedContracts;
    // The airline need to submit 10ETH if participate in contract
    mapping(address => uint256) private fundOfEachAirline;
    // If flight is delayed due to airline fault, passenger receives credit of 1.5X the amount they paid
    mapping(bytes32 => uint256) private insurances;
    // Passenger can withdraw any funds owed to them as a result of receiving credit for insurance payout
    mapping(bytes32 => uint256) private credits;
    // Passenger who buy the insurance of each airline
    mapping(bytes32 => address[]) private insurees;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address airline
                                ) 
                                public 
    {
        contractOwner = msg.sender;

        // First airline is registered when contract is deployed
        registeredAirlines.push(airline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier isCallerAuthorized() {
        require(authorizedContracts[msg.sender] == 1, "Caller is not authorized");
        _;
    }

    modifier hasSufficientFund(address airline) {
        require(fundOfEachAirline[airline] >= MINIMUM_THRESHOLD_OF_FUND, "Airline doesn't have sufficient fund");
        _;
    }

    modifier hasBoughtInsurance(address airline, string flight) {
        bytes32 key = keccak256(abi.encodePacked(airline, flight, msg.sender));
        require(insurances[key] > 0, "Passenger did not buy the insurance");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function authorizeCaller(address contractAddress) external requireContractOwner {
        authorizedContracts[contractAddress] = 1;
    }

    function deauthorizeCaller(address contractAddress) external requireContractOwner {
        delete authorizedContracts[contractAddress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address airline
                            )
                            external
                            isCallerAuthorized
    {
        registeredAirlines.push(airline);
    }

    /**
     * Return true if the airline has fund
     */
    function isAirline(address airline) external view returns(bool) {
        return fundOfEachAirline[airline] >= MINIMUM_THRESHOLD_OF_FUND;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                                address airline,
                                string flight,
                                uint256 amount
                            )
                            external
                            payable
                            hasSufficientFund(airline)
    {
        require(msg.value < amount, "Unsufficient amount");

        if (msg.value > amount) {
            msg.sender.transfer(msg.value.sub(amount));
        }

        bytes32 key = keccak256(abi.encodePacked(airline, flight, msg.sender));

        // Insurance fee of each passenger
        insurances[key] = amount;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address airline,
                                    string flight
                                )
                                external
                                hasBoughtInsurance(airline, flight)
    {
        bytes32 key = keccak256(abi.encodePacked(airline, flight, msg.sender));
        require(insurances[key] != 0, "Passenger doesn't pay");

        credits[key] = insurances[key].div(2).mul(3);
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address airline,
                                string flight
                            )
                            external
    {
        bytes32 key = keccak256(abi.encodePacked(airline, flight, msg.sender));

        // Amount to pay to passenger
        uint256 amount = credits[key];

        require(credits[key] > 0, "Passenger have no credit");
        credits[key] = 0;

        // Withdraw
        msg.sender.transfer(amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (
                            )
                            public
                            payable
    {
        fundOfEachAirline[msg.sender] = fundOfEachAirline[msg.sender].add(msg.value);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function getAirlines() external view returns (address[]) {
        return registeredAirlines;
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

