// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Send ETH using transfer
CONCEPT: ETH transfer mechanics
=========================================================

OBJECTIVE

- Learn how transfer() sends ETH
- Understand native ETH movement
- Learn payable mechanics
- Understand transfer limitations + risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

transfer() sends native ETH
from one contract/address to another.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

ETH transfers:
trigger external execution.

---------------------------------------------------------

Receiving contracts may execute:
receive() or fallback().

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

ETH transfers are fundamental to:

- withdrawals
- payments
- staking
- refunds
- treasury systems
- DeFi protocols

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

ETH transfer logic used in:

- exchanges
- vaults
- DAOs
- staking systems
- NFT marketplaces
- lending protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- transfer ordering
- reentrancy risk
- failed transfer handling
- locked ETH risks
- DOS vectors

=========================================================
*/

contract EthTransferMechanicsVul {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================

    payable:
    function can receive ETH.
    */

    function deposit()external payable{
        /*
            msg.value:
            ETH sent with transaction.
        */
        require(msg.value > 0,"No ETH sent");

        /*
            Store deposited ETH amount.
        */
        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    SEND ETH USING transfer()
    =====================================================
    */

    function withdraw(uint256 _amount ) external{
        /*
            CHECK:
            user must have balance.
        */
        require(balances[msg.sender] >= _amount,"Insufficient balance");

        /*
            EFFECTS:
            update storage BEFORE transfer.

            CEI pattern:
            Checks -> Effects -> Interactions
        */
        balances[msg.sender] -= _amount;

        /*
            INTERACTION:
            send ETH externally.

            transfer():
            - sends ETH
            - forwards 2300 gas
            - reverts automatically if failed
        */
        payable(msg.sender).transfer(_amount);
    }

    /*
    =====================================================
    CHECK CONTRACT ETH BALANCE
    =====================================================
    */

    function contractBalance()external view returns (uint256){
        /*
            address(this).balance

            Native ETH stored
            inside this contract.
        */
        return address(this).balance;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
User deposits ETH.

---------------------------------------------------------

CALL:
deposit()

VALUE:
1 ETH

=========================================================
DEPOSIT TRACE
=========================================================

STEP 1:
Transaction carries ETH.

---------------------------------------------------------

msg.value = 1 ETH

---------------------------------------------------------

STEP 2:
require(msg.value > 0)

RESULT:
true

---------------------------------------------------------

STEP 3:
Storage updated.

balances[Alice] += 1 ETH

---------------------------------------------------------

STEP 4:
Contract receives ETH.

---------------------------------------------------------

CONTRACT BALANCE:
1 ETH

=========================================================
WITHDRAW TRACE
=========================================================

CALL:
withdraw(1 ETH)

=========================================================

STEP 1:
Balance validation.

---------------------------------------------------------

balances[Alice] >= 1 ETH

RESULT:
true

---------------------------------------------------------
STEP 2:
Storage updated FIRST.

balances[Alice] -= 1 ETH

---------------------------------------------------------

NEW VALUE:
0

---------------------------------------------------------
STEP 3:
ETH transfer executes.

payable(msg.sender).transfer(1 ETH)

---------------------------------------------------------

ETH leaves contract.

---------------------------------------------------------

Alice receives ETH.

=========================================================
IMPORTANT transfer() UNDERSTANDING
=========================================================

transfer():

- sends native ETH
- forwards ONLY 2300 gas
- auto-reverts on failure

=========================================================
VERY IMPORTANT:
2300 GAS LIMIT
=========================================================

Receiving contract gets:

ONLY 2300 gas

---------------------------------------------------------

This usually prevents:
complex execution.

---------------------------------------------------------

Historically helped reduce:
reentrancy risk.

=========================================================
WHAT HAPPENS INTERNALLY
=========================================================

transfer():

1. deducts ETH from sender contract
2. sends ETH externally
3. triggers receiver execution
4. reverts if receiver fails

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Expand VALUE field in Remix

---------------------------------------------------------

STEP 3:
Enter:
1 ether

---------------------------------------------------------

STEP 4:
Call:
deposit()

---------------------------------------------------------

STEP 5:
Call:
contractBalance()

EXPECTED:
1000000000000000000

(1 ETH in wei)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
1 ETH in wei

---------------------------------------------------------

STEP 7:
Call:
withdraw(500000000000000000)

(0.5 ETH)

---------------------------------------------------------

STEP 8:
Call:
balances(your_address)

EXPECTED:
0.5 ETH remaining

=========================================================
IMPORTANT PAYABLE UNDERSTANDING
=========================================================

Functions receiving ETH
must be marked:

payable

---------------------------------------------------------

Otherwise:
transaction reverts.

=========================================================
WEI UNDERSTANDING
=========================================================

1 ETH =
1,000,000,000,000,000,000 wei

---------------------------------------------------------

Solidity stores ETH in:
wei internally.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

External ETH transfer dangerous
if state updated too late.

---------------------------------------------------------
2. DOS VIA transfer()
---------------------------------------------------------

2300 gas may break receivers.

---------------------------------------------------------
3. LOCKED ETH
---------------------------------------------------------

No withdraw path exists.

---------------------------------------------------------
4. FAILED TRANSFER ASSUMPTIONS
---------------------------------------------------------

Receiver may revert intentionally.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External ETH transfer =
external interaction.

---------------------------------------------------------

Treat as:
UNTRUSTED execution.

=========================================================
CEI PATTERN
=========================================================

SAFE ORDER:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Used in withdraw() above.

=========================================================
WHY transfer() BECAME LESS PREFERRED
=========================================================

Modern Solidity often prefers:

call{value: amount}()

---------------------------------------------------------

Reason:
2300 gas assumptions became unreliable.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Is ETH transfer ordered safely?
- Can receiver reenter?
- Can transfer fail unexpectedly?
- Is ETH permanently lockable?
- Are balances updated before transfer?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

State updated AFTER transfer.

---------------------------------------------------------

Attacker contract:
reenters withdraw repeatedly.

---------------------------------------------------------

Result:
fund theft.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. ETH movement
2. State-update ordering
3. External interaction timing
4. Revert behavior
5. Receiver execution flow

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add vulnerable withdraw()
2. Move transfer BEFORE balance update
3. Analyze reentrancy risk
4. Fix using CEI pattern

BONUS:
Implement withdraw using:
call{value: amount}()

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- transfer() sends native ETH
- payable functions receive ETH
- msg.value contains sent ETH
- transfer() forwards 2300 gas
- External ETH transfers are dangerous
- CEI pattern improves security
- State must update before transfer
- ETH stored internally as wei
- Auditors trace ETH movement carefully
- Interactions create reentrancy risk

=========================================================
*/

/*
Audit Report

Title: Denial of Service Risk Due to transfer() Gas Limitation

Severity: Low

Reason:
The contract uses transfer(), which forwards only 2300 gas to the recipient.

Location:

Contract: EthTransferMechanicsVul
Function: withdraw()

Vulnerability Description:

The withdraw() function sends ETH using:
payable(msg.sender).transfer(_amount);
The transfer() method forwards only 2300 gas.
If the recipient is a smart contract whose receive() or fallback() function requires more than 2300 gas, 
the transfer will revert.
As a result, certain contract users may be unable to withdraw their ETH.

Impact:
Users interacting through contracts may be unable to receive withdrawals.

If the recipient contract:

- performs storage writes
- emits events
- executes complex logic

then transfer() may fail and revert the transaction.
This can create a denial-of-service condition for specific users.

Proof of Concept:
        1. Deploy EthTransferMechanicsVul.
        2. Deposit 1 ETH.
        3. Deploy a contract with a receive() function that consumes more than 2300 gas.
        4. Call:
            withdraw(1 ether)
        5. transfer() reverts.
        6. Withdrawal fails even though the user has sufficient balance.

Root Cause:
The contract uses:
transfer()
which forwards only 2300 gas to the recipient.
Modern smart contracts may require more gas to process incoming ETH.

Recommendation:
Use low-level call instead of transfer().

Example:

(bool success,) =
    payable(msg.sender).call{value: _amount}("");

require(success, "Transfer failed");
*/

//patched code
contract EthTransferMechanics {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================

    payable:
    function can receive ETH.
    */

    function deposit()external payable{
        /*
            msg.value:
            ETH sent with transaction.
        */
        require(msg.value > 0,"No ETH sent");

        /*
            Store deposited ETH amount.
        */
        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    SEND ETH USING call() and following CEI pattern
    =====================================================
    */

    function withdraw(uint256 _amount ) external{
        /*
            CHECK:
            user must have balance.
        */
        require(balances[msg.sender] >= _amount,"Insufficient balance");

        /*
            EFFECTS:
            update storage BEFORE transfer.

            CEI pattern:
            Checks -> Effects -> Interactions
        */
        balances[msg.sender] -= _amount;
        /*
            INTERACTION:
            send ETH externally.

            transfer():
            - sends ETH
            - forwards 2300 gas
            - reverts automatically if failed
        */
        (bool success,)=payable (msg.sender).call{value:_amount}("");
        require(success,"Failed to send ETH");
    }

    // vulnerable withdraw
   function withdrawVul(uint256 _amount ) external{
        /*
            CHECK:
            user must have balance.
        */
        require(balances[msg.sender] >= _amount,"Insufficient balance");

        /*
            INTERACTION:
            send ETH externally.

            transfer():
            - sends ETH
            - forwards 2300 gas
            - reverts automatically if failed
        */
        (bool success,)=payable (msg.sender).call{value:_amount}("");
        require(success,"Failed to send ETH");

        /*
            EFFECTS:
           STATE UPDATED TOO LATE

            CEI VIOLATION:
            Interaction occurred before Effects.
        */
        balances[msg.sender] -= _amount;
    }


    /*
    =====================================================
    CHECK CONTRACT ETH BALANCE
    =====================================================
    */

    function contractBalance()external view returns (uint256){
        /*
            address(this).balance

            Native ETH stored
            inside this contract.
        */
        return address(this).balance;
    }
}