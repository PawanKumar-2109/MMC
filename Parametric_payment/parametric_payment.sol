pragma solidity ^0.5.0;

import "chainlink/v0.5/contracts/ChainlinkClient.sol";
import "chainlink/v0.5/contracts/vendor/Ownable.sol";
import "./mmctoken.sol";


interface mmctokenInterface {
    function balanceOf(address mmc_token_holder) external view returns (uint);
    function transferfrom(address _from, address _to, uint _amount) external returns (bool);
}


contract Parametric is ChainlinkClient, Ownable {
    
 
 
 address public insurer;
    address payable client;
    uint startDate;
    uint duration;
    uint premium;
    uint payoutValue;
    string cropLocation;
    string lat;
    string lon;
    //adding extra variables
    mmctokenInterface _token;
    
  uint256 constant private ORACLE_PAYMENT = 0 * LINK;
  uint public constant DROUGHT_DAYS_THRESDHOLD = 3 ;  //Number of consecutive days without rainfall to be defined as a drought

  address public LINKC = 0xc0268d92c9A5824FF5007206924f1eDF97809df6;
  address public ORACLE = 0xD3fB4f81Ff1A20a50816a9b4eFc43100074aBe44;
  string public JOBID = 'd65e04bd892f4b9796e14a460346d8e4';
  
  string constant WORLD_WEATHER_ONLINE_URL = "http://api.worldweatheronline.com/premium/v1/weather.ashx?";
  string constant WORLD_WEATHER_ONLINE_KEY = "458a4a7265f64f75b1c131533212804";
  string constant WORLD_WEATHER_ONLINE_PATH = "data.current_condition.0.precipMM";
  
  string constant WEATHERBIT_URL = "https://api.weatherbit.io/v2.0/current?";
  string constant WEATHERBIT_KEY = "1c3d6c4db5ea4ebd976f6da3816f9e4b";
  string constant WEATHERBIT_PATH = "data.0.dewpt";
    
  uint256[2] public currentRainfallList;
  
  uint daysWithoutRain;                   //how many days there has been with 0 rain
  bool contractActive;                    //is the contract currently active, or has it ended
  bool contractPaid = false;
  uint currentRainfall = 0;               //what is the current rainfall for the location
  uint currentRainfallDateChecked = now;  //when the last rainfall check was performed
  uint requestCount = 0;                  //how many requests for rainfall data have been made so far for this insurance contract
  uint dataRequestsSent = 0; 
  
  
  /**
     * @dev Prevents a function being run unless it's called by Insurance Provider
     */
    modifier onlyOwner() {
		require(insurer == msg.sender,'Only Insurance provider can do this');
        _;
    }

  constructor(address _mmctoken_contract_address,address payable _client, uint _duration, uint _premium, uint _payoutValue, string memory _cropLocation, string memory _lat, string memory _lon)  payable Ownable() public {
    setChainlinkToken(LINKC);
    setChainlinkOracle(ORACLE);
    
    //now initialize values for the contract
    insurer= msg.sender;
    client = _client;
    startDate = now ; //contract will be effective immediately on creation
    duration = _duration;
    premium = _premium;
    payoutValue = _payoutValue;
    daysWithoutRain = 0;
    contractActive = true;
    cropLocation = _cropLocation;
    lat = _lat;
    lon = _lon;
    
    //sending the mmc token from insurer address to contract address
    _token = mmctokenInterface(_mmctoken_contract_address);
    _token.transferfrom(msg.sender,address(this),_payoutValue);
    
  }
    event contractCreated(address _insurer, address _client, uint _duration, uint _premium, uint _totalCover);
    event dataRequestSent(bytes32 requestId);
    event dataReceived(uint _rainfall);
    event contractPaidOut(uint _paidTime, uint _totalPaid, uint _finalRainfall);
    event ranfallThresholdReset(uint _rainfall);
    
    /**
     * @dev Calls out to an Oracle to obtain weather data
     */ 
    function updateContract() public   {
        //first call end contract in case of insurance contract duration expiring, if it hasn't then this functin execution will resume
        
        //contract may have been marked inactive above, only do request if needed
            dataRequestsSent = 0;
            //First build up a request to World Weather Online to get the current rainfall
            string memory _url = string(abi.encodePacked(WORLD_WEATHER_ONLINE_URL, "key=",WORLD_WEATHER_ONLINE_KEY,"&q=",cropLocation,"&format=json&num_of_days=1"));
            checkRainfall(_url, WORLD_WEATHER_ONLINE_PATH);  

            
            //Now build up the second request to WeatherBit
            _url = string(abi.encodePacked(WEATHERBIT_URL, "lat=",lat,"&lon=",lon,"&key=",WEATHERBIT_KEY));
            checkRainfall( _url, WEATHERBIT_PATH);    
        }
    

  /**
     * @dev Calls out to an Oracle to obtain weather data
     */ 
    function checkRainfall(string memory _url, string memory _path) public returns (bytes32 requestId)   {
        
        
        //First build up a request to get the current rainfall
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOBID), address(this), this.checkRainfallCallBack.selector);
           
        req.add("get", _url); //sends the GET request to the oracle
        req.add("path", _path);
        req.addInt("times", 100);
        
        requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);
            
        emit dataRequestSent(requestId);
        
    }
    
    function checkRainfallCallBack(bytes32 _requestId, uint256 _rainfall) public recordChainlinkFulfillment(_requestId) {
        //set current temperature to value returned from Oracle, and store date this was retrieved (to avoid spam and gaming the contract)
       currentRainfallList[dataRequestsSent] = _rainfall; 
       dataRequestsSent = dataRequestsSent + 1;
       
       
       //set current rainfall to average of both values
       if (dataRequestsSent > 1) {
           //currentRainfall = currentRainfallList[0];
          currentRainfall = (currentRainfallList[0].add(currentRainfallList[1]).div(2));
          currentRainfallDateChecked = now;
          requestCount +=1;
        
          //check if payout conditions have been met, if so call payoutcontract, which should also end/kill contract at the end
          if (currentRainfall < 1000 ) { //temp threshold has been  met, add a day of over threshold
              daysWithoutRain += 1;
          } else {
              //there was rain today, so reset daysWithoutRain parameter 
              daysWithoutRain = 0;
              emit ranfallThresholdReset(currentRainfall);
          }
       
          if (daysWithoutRain >= DROUGHT_DAYS_THRESDHOLD) {  // day threshold has been met
              //need to pay client out insurance amount
              payOutContract();
          }
       }
       
       emit dataReceived(_rainfall);
        
    }
    
     /* @dev Insurance conditions have been met, do payout of total cover amount to client
     */ 
    function payOutContract() private   {
        
        //Transfer agreed amount to client
        //client.transfer(address(this).balance);
        
        //Transfer any remaining funds (premium) back to Insurer
        //LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        //require(link.transfer(insurer, link.balanceOf(address(this))), "Unable to transfer");
        
        _token.transferfrom(address(this),client,payoutValue);
        
        emit contractPaidOut(now, payoutValue, currentRainfall);
        
        //now that amount has been transferred, can end the contract 
        //mark contract as ended, so no future calls can be done
        contractActive = false;
        contractPaid = true;
    
    }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }
  
  /**
     * @dev Get the balance of the contract
     */ 
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    } 
    
    /**
     * @dev Get the Crop Location
     */ 
    function getLocation() external view returns (string memory) {
        return cropLocation;
    } 
    
    
    /**
     * @dev Get the Total Cover
     */ 
    function getPayoutValue() external view returns (uint) {
        return payoutValue;
    } 
    
    
    /**
     * @dev Get the Premium paid
     */ 
    function getPremium() external view returns (uint) {
        return premium;
    } 
    
    /**
     * @dev Get the status of the contract
     */ 
    function getContractStatus() external view returns (bool) {
        return contractActive;
    }
    
    /**
     * @dev Get whether the contract has been paid out or not
     */ 
    function getContractPaid() external view returns (bool) {
        return contractPaid;
    }
    
    
    /**
     * @dev Get the current recorded rainfall for the contract
     */ 
    function getCurrentRainfall() external view returns (uint) {
        return currentRainfall;
    }
    
    /**
     * @dev Get the recorded number of days without rain
     */ 
    function getDaysWithoutRain() external view returns (uint) {
        return daysWithoutRain;
    }
    
    /**
     * @dev Get the count of requests that has occured for the Insurance Contract
     */ 
    function getRequestCount() external view returns (uint) {
        return requestCount;
    }
    
    /**
     * @dev Get the last time that the rainfall was checked for the contract
     */ 
    function getCurrentRainfallDateChecked() external view returns (uint) {
        return currentRainfallDateChecked;
    }
    
    /**
     * @dev Get the contract duration
     */ 
    function getDuration() external view returns (uint) {
        return duration;
    }
    
    /**
     * @dev Get the contract start date
     */ 
    function getContractStartDate() external view returns (uint) {
        return startDate;
    }
    
    /**
     * @dev Get the current date/time according to the blockchain
     */ 
    function getNow() external view returns (uint) {
        return now;
    }
    
    /**
     * @dev Get address of the chainlink token
     */ 
    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }
    
    /**
     * @dev Helper function for converting a string to a bytes32 object
     */ 
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
         return 0x0;
        }

        assembly { // solhint-disable-line no-inline-assembly
        result := mload(add(source, 32))
        }
    }
    
    
    /**
     * @dev Helper function for converting uint to a string
     */ 
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    /**
     * @dev Fallback function so contrat can receive ether when required
     */ 
    function() external payable {  }

}