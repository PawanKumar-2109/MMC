// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract InsuranceContract{
    address public insurer;
    address client;
    uint startdate;
    uint duration;
    uint premium;
    uint payoutvalue;
    bool contractActive;
    uint notrainfallcount;
    
    uint checker;
    
    modifier Onlyowner() {
        require(msg.sender == insurer);
        _;
    }
    
    modifier Contractended() {
        require(startdate + duration < block.timestamp);
        _;
    }
    
    modifier isContractActive() {
        require(contractActive == true);
        _;
    }
    
    constructor(address _client,uint _startdate,uint _duration,uint _premium,uint _payoutvalue) public {
        insurer = msg.sender;
        client = _client;
        startdate = _startdate;
        duration = _duration;
        premium = _premium;
        payoutvalue = _payoutvalue;
        contractActive = true;
        notrainfallcount = 0;
    }
    
  /*  function check_rainfall() private returns (bool) {
        //if there is rainfall update the notrainfallcount to 0 and return true
        //if there is no rainfall increment the notrainfallcount by 1 and return false
        if(rainfall_occurs){
            notrainfallcount = 0;
            return true;
        } else {
            notrainfallcount = notrainfallcount + 1;
            return false;
        }
    }
    
    function update_contract() public isContractActive() {
        if(startdate + duration > block.timestamp){
            check_rainfall();
            if(notrainfallcount >= 3){
                payoutcontract();
                //payoutcontract will pay the client and change the status of contractActive
            }
        }
    } */
    
    function set_checker(uint s) public {
        checker = s;
    }
    
    function payoutcontract() public isContractActive() returns (bool) {
        if(checker == 1){
            contractActive = false;
            return true;
        }
        return false;
    }
    
    function getPayoutValue() external view returns (uint) {
        return payoutvalue;
    }
    
    function getPremium() external view returns (uint) {
        return premium;
    }
    
    function getContractStatus() external view returns (bool) {
        return contractActive;
    }
}