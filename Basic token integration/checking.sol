// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./basic_token.sol";


contract checking {
    
    basic_token _token;
    
    constructor(address basic_token_address){
         _token = basic_token(basic_token_address);
    }
    
    function make_balance(address _of) public view returns (uint) {
        uint tokens;
        tokens = _token.get_balance(_of);
        return tokens;
    }
    
    function make_transfer(address _from,address _to,uint _amount) public {
        _token.transfer(_from,_to,_amount);
    }
}