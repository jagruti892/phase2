// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: tx.origin Authentication Contract
CONCEPT: Dangerous authentication pattern
=========================================================

WARNING:
This contract demonstrates a BAD PRACTICE.

DO NOT use tx.origin for authentication in production.
=========================================================
*/

contract TxOriginAuthVul {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /*
    =====================================================
    DANGEROUS AUTH CHECK
    =====================================================
    */

    function withdrawAll() external {

        /*
         BAD PRACTICE:
        using tx.origin for authentication
        */

        require(tx.origin == owner, "Not owner");

        payable(owner).transfer(address(this).balance);
    }
    /*
    =====================================================
    NORMAL DEPOSIT
    =====================================================
    */

    function deposit() external payable {}
}

/*
Audit Report

Title: Authentication Using tx.origin

Severity: High

Reason:
The contract uses tx.origin for authorization instead of msg.sender.
This allows phishing-style attacks where a malicious contract can execute privileged actions on behalf 
 of the owner.

Location:

Contract: TxOriginAuthVul
Function: withdrawAll()

Vulnerability Description:
The withdrawAll() function authenticates users using:

require(tx.origin == owner, "Not owner");

tx.origin returns the original externally owned account (EOA)
that started the transaction.

If the owner interacts with a malicious contract, that contract
can call withdrawAll() and the tx.origin check will still pass,
because tx.origin remains the owner's address.

Impact:
An attacker can trick the owner into interacting with a malicious contract.

The malicious contract can then invoke withdrawAll() and drain
all ETH stored in the contract.

Proof of Concept:
        1. Deploy TxOriginAuthVul.
        2. Owner deposits ETH into the contract.
        3. Attacker deploys a malicious contract.
        4. Owner interacts with the malicious contract.
        5. The malicious contract calls:
        withdrawAll()
        6. The check:
        tx.origin == owner
        evaluates to true.
        7. All ETH is transferred out successfully.

Root Cause:
Authorization is performed using tx.origin.

tx.origin represents the original transaction sender and should
not be used for access control.

Recommendation:
Use msg.sender for authentication instead of tx.origin.

Example:
require(msg.sender == owner, "Not owner");
*/

// patched code
contract TxOriginAuth {

    address public owner;

    constructor() {
        owner = msg.sender;
    }


    mapping (address=>uint256)public balances;

       /*
    =====================================================
    NORMAL DEPOSIT
    =====================================================
    */

    function deposit() external payable {
        balances[msg.sender]+=msg.value;
    }

    function withdrawAll() external {
        require(msg.sender == owner, "Not owner");

        payable(owner).transfer(address(this).balance);
    }
}



