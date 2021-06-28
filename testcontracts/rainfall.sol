// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.24;

import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.4/ChainlinkClient.sol";

contract checkrainfall is ChainlinkClient {
    address private oracle;
    bytes32 private jobId;
    uint256 private oracle_fee;
    uint256 public rainfall;
    string croplocation;
    string constant WORLD_WEATHER_ONLINE_URL = "http://api.worldweatheronline.com/premium/v1/weather.ashx?";
    string constant WORLD_WEATHER_ONLINE_KEY = "629c6dd09bbc4364b7a33810200911";
    string constant WORLD_WEATHER_ONLINE_PATH = "data.current_condition.0.precipMM";
    
    constructor(string _croplocation) public {
        setPublicChainlinkToken();
        croplocation = _croplocation;
        oracle_fee = 0.1 * 10 ** 18;
        oracle = 0x240bae5a27233fd3ac5440b5a598467725f7d1cd;
        jobId = '1bc4f827ff5942eaaa7540b7dd1e20b9';
    }
    
    function updateContract() public returns (bytes32) {
        string memory url = string(abi.encodePacked(WORLD_WEATHER_ONLINE_URL, "key=",WORLD_WEATHER_ONLINE_KEY, "&q=",croplocation,"&format=json&num_of_days=1"));
        CheckRainfall(oracle,jobId,url,WORLD_WEATHER_ONLINE_PATH);
    }
    
    function CheckRainfall(address _oracle,bytes32 _jobId,string _url,string _path) private returns (bytes32 requestId) {
        Chainlink.Request memory myrequest = buildChainlinkRequest(_jobId,address(this),this.CallBack.selector);
        myrequest.add("get",_url);
        myrequest.add("path",_path);
        myrequest.addInt("times", 10000);
        return sendChainlinkRequestTo(_oracle,myrequest,oracle_fee);
    }
    
    function CallBack(bytes32 _requestId,uint256 _rainfall) public recordChainlinkFulfillment(_requestId) {
        rainfall = _rainfall;
    }
    
    function get_rainfall() public view returns (uint256) {
        return rainfall;
    }
}