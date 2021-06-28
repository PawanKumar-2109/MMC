// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./basic_token.sol";

interface basic_tokenInterface {
    function get_balance(address ofp) external view returns (uint);
    function transfer(address from,address to,uint amount) external;
}

contract interface_checking {
    
    basic_tokenInterface _token;
    
    constructor(address basic_token_address,address token_admin){
         _token = basic_tokenInterface(basic_token_address);
         _token.transfer(token_admin,address(this),10);
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