// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Fix Reentrancy using CEI Pattern
CONCEPT: Secure execution order
=========================================================

OBJECTIVE

- Fix reentrancy vulnerability
- Apply Checks → Effects → Interactions pattern
- Ensure secure ETH withdrawal flow
- Prevent recursive external calls exploitation

---------------------------------------------------------
CORE IDEA (CEI PATTERN)
---------------------------------------------------------

✔ CHECKS        → validate conditions
✔ EFFECTS       → update state FIRST
✔ INTERACTIONS  → external calls LAST

---------------------------------------------------------

This prevents reentrancy because:

state is already updated
before external contract can re-enter

=========================================================
SECURE BANK CONTRACT
=========================================================
*/

contract SecureBank {
    /*
        USER BALANCES
    */
    mapping(address => uint256) public balance;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    /*
    =====================================================
    SECURE WITHDRAW (FIXED)
    =====================================================
    */

    function withdraw(uint256 amount) external {

        /*
        =================================================
        1. CHECKS
        =================================================
        */
        require(balance[msg.sender] >= amount, "Insufficient balance");

        /*
        =================================================
        2. EFFECTS (STATE UPDATE FIRST) ✅ FIX
        =================================================
        */

        balance[msg.sender] -= amount;

        /*
        =================================================
        3. INTERACTIONS (EXTERNAL CALL LAST)
        =================================================
        */

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /*
    =====================================================
    VIEW BALANCE
    =====================================================
    */

    function getBalance(address user)
        external
        view
        returns (uint256)
    {
        return balance[user];
    }
}
/*
Audit Report

Title: CEI Pattern Implemented in withdraw()

Severity: Informational

Reason:
The withdraw() function follows the Checks → Effects → Interactions (CEI) pattern, reducing the risk of
classic reentrancy attacks.

Location:

Contract: SecureBank
Function: withdraw(uint256 amount)

Vulnerability Description:
No reentrancy vulnerability was identified in the current implementation.

The function first validates the user's balance, then updates the contract state, and only afterwards performs 
the external ETH transfer.

This execution order prevents recursive withdrawals from exploiting stale balance values.

Impact:
The contract is protected against the classic reentrancy scenario where an attacker repeatedly calls withdraw() before their balance is updated.

User balances are reduced before the external call occurs.

Proof of Concept:
        1.User deposits:
            1 ETH
        2.User calls:
            withdraw(1 ether)
        3.Execution order:
            Balance check passes.
            balance[msg.sender] is reduced.
            ETH is transferred.

If a malicious contract attempts to re-enter during the external call:

withdraw(1 ether)

The balance check fails because the balance was already reduced before the external interaction.

Root Cause:
The contract correctly applies the CEI pattern:

    Checks:
    require(balance[msg.sender] >= amount)

    Effects:
    balance[msg.sender] -= amount

    Interactions:
    msg.sender.call{value: amount}("")

Recommendation:
Continue using the CEI pattern for functions that perform external calls and modify state.
*/