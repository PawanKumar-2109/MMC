// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract basic_token {
    mapping (address => uint) balances;
    uint total_supply;
    constructor(uint inital){
        total_supply = inital;
        balances[msg.sender] = inital;
    }
    
    function get_balance(address ofp) public view returns (uint) {
        return balances[ofp];
    }
    
    function transfer(address from,address to,uint amount) public {
        require(balances[from] >= amount);
        balances[from]=balances[from]-amount;
        balances[to]=balances[to]+amount;
    }
}