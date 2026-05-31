// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trigger receive() with ETH
CONCEPT: ETH reception
=========================================================

OBJECTIVE

- Learn how receive() works
- Understand ETH reception mechanics
- Learn empty calldata behavior
- Understand automatic ETH handling

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

receive() executes automatically when:

1. ETH is sent
AND
2. calldata is EMPTY

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

receive() is a special function.

---------------------------------------------------------

It does NOT require:
explicit function call.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

ETH reception is fundamental to:

- deposits
- staking
- treasury systems
- refunds
- vaults
- bridges

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

receive() used in:

- ETH vaults
- DAO treasuries
- DeFi pools
- staking contracts
- exchanges

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- ETH acceptance logic
- unexpected ETH reception
- fallback/receive behavior
- reentrancy risks
- locked ETH scenarios

=========================================================
RECEIVER CONTRACT
=========================================================
*/

contract ETHReceiverVul {

    /*
        TRACK TOTAL ETH RECEIVED
    */
    uint256 public totalReceived;

    /*
        TRACK LAST SENDER
    */
    address public lastSender;

    /*
        TRACK NUMBER OF RECEIVES
    */
    uint256 public receiveCounter;

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Automatically executes when:
    - ETH sent
    - calldata EMPTY
    */

    receive()
        external
        payable
    {

        /*
            msg.sender:
            address sending ETH
        */
        lastSender = msg.sender;

        /*
            msg.value:
            ETH amount received
        */
        totalReceived += msg.value;

        /*
            Track receive executions
        */
        receiveCounter++;
    }

    /*
    =====================================================
    CHECK CONTRACT ETH BALANCE
    =====================================================
    */

    function contractBalance()
        external
        view
        returns (uint256)
    {

        return address(this).balance;
    }
}

/*
=========================================================
SENDER CONTRACT
=========================================================
*/

contract ETHSenderVul {

    /*
        STORE RECEIVER ADDRESS
    */
    address payable public receiver;

    /*
        TRACK LAST STATUS
    */
    bool public lastSuccess;

    /*
        CONSTRUCTOR
    */
    constructor(address payable _receiver)
    {

        receiver = _receiver;
    }

    /*
    =====================================================
    SEND ETH
    =====================================================
    */

    function sendETH()
        external
        payable
    {

        /*
            ETH sent with EMPTY calldata.

            This triggers:
            receive()
        */
        (bool success, ) =
            receiver.call{
                value: msg.value
            }("");

        /*
            Save result
        */
        lastSuccess = success;

        /*
            Ensure success
        */
        require(
            success,
            "ETH transfer failed"
        );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy ETHReceiver

---------------------------------------------------------

STEP 2:
Deploy ETHSender

Constructor input:
Receiver address

=========================================================
TRACE:
sendETH()
=========================================================

VALUE:
1 ETH

=========================================================

STEP 1:
User calls:
sendETH()

---------------------------------------------------------

msg.value = 1 ETH

=========================================================
STEP 2
=========================================================

Low-level call executes:

receiver.call{
    value: 1 ETH
}("")

---------------------------------------------------------

IMPORTANT:

"" = EMPTY calldata

=========================================================
STEP 3
=========================================================

Execution jumps into:
ETHReceiver contract

---------------------------------------------------------

EVM checks:

- Is calldata empty?
YES

- Does receive() exist?
YES

---------------------------------------------------------

RESULT:
receive() executes automatically.

=========================================================
INSIDE receive()
=========================================================

STEP 1:
lastSender = msg.sender

---------------------------------------------------------

IMPORTANT:

msg.sender =
ETHSender contract

NOT original user.

=========================================================
STEP 2
=========================================================

totalReceived += msg.value

---------------------------------------------------------

msg.value = 1 ETH

---------------------------------------------------------

NEW VALUE:
1 ETH

=========================================================
STEP 3
=========================================================

receiveCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
FINAL RESULT
=========================================================

Receiver contract balance:
1 ETH

---------------------------------------------------------

receive() executed successfully.

=========================================================
IMPORTANT receive() UNDERSTANDING
=========================================================

receive() triggers ONLY when:

---------------------------------------------------------
CONDITION 1
---------------------------------------------------------

ETH sent

AND

---------------------------------------------------------
CONDITION 2
---------------------------------------------------------

calldata EMPTY

=========================================================
IF CALLDATA EXISTS?
=========================================================

Then:
fallback() may execute instead.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy ETHReceiver

---------------------------------------------------------

STEP 2:
Copy receiver address

---------------------------------------------------------

STEP 3:
Deploy ETHSender

Input:
receiver address

---------------------------------------------------------

STEP 4:
In VALUE field:
enter 1 ether

---------------------------------------------------------

STEP 5:
Call:
sendETH()

---------------------------------------------------------

STEP 6:
Open ETHReceiver

---------------------------------------------------------

STEP 7:
Call:
totalReceived()

EXPECTED:
1 ETH in wei

---------------------------------------------------------

STEP 8:
Call:
receiveCounter()

EXPECTED:
1

---------------------------------------------------------

STEP 9:
Call:
contractBalance()

EXPECTED:
1 ETH in wei

=========================================================
VERY IMPORTANT msg.sender UNDERSTANDING
=========================================================

FLOW:

User
  ->
Sender Contract
  ->
Receiver Contract

---------------------------------------------------------

Inside receive():

msg.sender =
Sender contract address

=========================================================
ETH BALANCE UNDERSTANDING
=========================================================

ETH stored inside contract:

address(this).balance

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNEXPECTED ETH RECEPTION
---------------------------------------------------------

Contracts may accidentally receive ETH.

---------------------------------------------------------
2. LOCKED ETH
---------------------------------------------------------

No withdrawal mechanism exists.

---------------------------------------------------------
3. REENTRANCY
---------------------------------------------------------

receive() may execute malicious logic.

---------------------------------------------------------
4. DOS VIA REVERT
---------------------------------------------------------

receive() may intentionally revert.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Receiving ETH =
external execution point.

---------------------------------------------------------

Never assume:
receiver behavior is safe.

=========================================================
RECEIVE VS FALLBACK
=========================================================

---------------------------------------------------------
receive()
---------------------------------------------------------

- ETH received
- empty calldata

---------------------------------------------------------
fallback()
---------------------------------------------------------

- unknown function
- non-empty calldata

=========================================================
GAS OBSERVATION
=========================================================

receive() should remain:
simple + lightweight.

---------------------------------------------------------

Complex logic increases:
attack surface.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can ETH become locked?
- Does receive() reenter?
- Is ETH acceptance intended?
- Is fallback safer?
- Can attacker abuse ETH reception?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Victim sends ETH.

---------------------------------------------------------

Malicious receive() executes.

---------------------------------------------------------

receive() reenters vulnerable function.

---------------------------------------------------------

Result:
fund theft.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. ETH reception paths
2. receive()/fallback execution
3. External execution timing
4. State-update ordering
5. Reentrancy windows

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add fallback()
2. Compare receive vs fallback
3. Add ETH withdrawal
4. Add event logging

BONUS:
Create malicious receive()
for reentrancy testing.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- receive() handles plain ETH transfers
- receive() requires empty calldata
- ETH transfer triggers external execution
- msg.value stores ETH amount
- msg.sender changes across contracts
- Contracts can store ETH internally
- receive() creates security attack surface
- ETH reception must be audited carefully
- fallback() differs from receive()
- External ETH flow is critical in Solidity security

=========================================================
*/

// patched code 
