// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.24;
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract Dollar is ChainlinkClient {
  
    uint256 public price;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor() public {
        setPublicChainlinkToken();
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        fee = 0.1 * 10 ** 18;
    }

    function checkprice() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.getprice.selector);
        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");
        request.add("path", "RAW.ETH.USD.PRICE");
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    function getprice(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId){
        price = _price;
    }
}