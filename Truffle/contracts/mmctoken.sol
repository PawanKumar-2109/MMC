// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;

contract mmctoken {
    
    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowed;
    uint private total_flow;
    address private minter;
    
    event Transfer(address from, address to, uint amount);
    event Approval(address from, address to, uint amount);
    
    constructor(uint intial_balance) public{
        balances[msg.sender] = intial_balance;
        total_flow = intial_balance;
        minter = msg.sender;
    }
    
  function mint(uint amount,address to) public {
        require(msg.sender == minter);
        total_flow = total_flow + amount;
        balances[to] = balances[to] + amount;
    }
    
    function burn(uint amount,address from) public {
        require(msg.sender == minter);
        require(balances[from] >= amount);
        total_flow = total_flow - amount;
        balances[from] = balances[from] - amount;
    }
    
    function totalSupply() public view returns (uint) {
        return total_flow;
    }
    
    function balanceOf(address mmc_token_holder) public view returns (uint) {
        return balances[mmc_token_holder];
    }
    
    function transfer (address reciever, uint amount) public returns (bool) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[reciever] = balances[reciever] + amount;
        emit Transfer(msg.sender, reciever, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        if (owner == spender){
            return balances[owner];
        } else {
            return allowed[owner][spender];
        }
    }
    
   function approve(address reciever, uint amount) public returns (bool) {
        require(msg.sender != reciever);
        allowed[msg.sender][reciever] = amount;
        emit Approval(msg.sender, reciever, amount);
        return true;
    }
    
    function transferfrom(address from, address to, uint amount) public returns (bool) {
        require(balances[from] >= amount);
        require(allowed[msg.sender][from] >= amount || msg.sender == from);
        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        allowed[msg.sender][from] = allowed[msg.sender][from] - amount;
        return true;
    }
}