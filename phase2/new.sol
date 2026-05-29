// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {

    mapping(address => uint256) public balances;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function changeOwner(address newOwner) external {
        owner = newOwner;
    }

    function withdraw(uint256 amount) external {

        require(
            balances[msg.sender] >= amount,
            "Insufficient balance"
        );

        (bool success,) = msg.sender.call{value: amount}("");

        require(success, "Transfer failed");

        balances[msg.sender] -= amount;
    }

    function deleteBalance(address user) external {
        delete balances[user];
    }

    receive() external payable {}
}




contract BankPatch {

    mapping(address => uint256) public balances;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit()  external payable {
        balances[msg.sender] += msg.value;
    }

     function changeOwner(address newOwner) external {
        require(msg.sender==owner,"Not owner");
        owner = newOwner;
    }
    function withdraw(uint256 amount) external {
        require(msg.sender==owner,"Not owner");
        require(
            balances[msg.sender] >= amount,
            "Insufficient balance"
        );

         balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");

        require(success, "Transfer failed");

    }

    function deleteBalance(address user) external {
        require(msg.sender==owner,"Not owner");
        delete balances[user];
    }

    receive() external payable {}
}

// report 
/*
Vulnerabilities :
    Missing Access Control and Reentrancy 

Location:
    Contract: contract Bank
    Function: withdraw()
            changeOwner(address newOwner)
            deleteBalance(address user)

Vulnerability Description:

    withdraw()
    changeOwner(address newOwner)
    deleteBalance(address user)
            has no access control anyone can  withdraw also anyone can change the owner and delete balance

also withdraw() has not followed proper CEI rule amount is transfered before balance is updated which may cause
Reentrancy issue(funds can be drained) 
*/