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
/*
=========================================================
RECEIVER CONTRACT
=========================================================
*/

/*
Audit Report

Title: Locked ETH, Missing Receiver Validation, and Missing Event Logging

Severity: Medium

Reason: ETH can become permanently locked, receiver configuration is not validated, and ETH transfers are not traceable through events.

Location:

Contract: ETHReceiverVul
Function: receive()

Contract: ETHSenderVul
Function: constructor()

Contract: ETHSenderVul
Function: sendETH()

Vulnerability Description:

The system contains multiple security and operational issues:
Locked ETH Risk
The ETHReceiverVul contract accepts ETH through the receive() function and tracks received funds internally.
However, no withdrawal mechanism exists.
Any ETH received by the contract becomes permanently locked inside the contract.

Missing Receiver Address Validation
The ETHSenderVul constructor accepts any receiver address without validation.

A zero address or unintended address may be supplied during deployment.
This can result in failed transfers or incorrect configuration.

Missing Event Logging
ETH transfers and ETH reception occur without emitting any events.

This reduces visibility for:
users
auditors
monitoring tools
analytics systems
and makes ETH movement harder to track.

Impact:

Locked ETH Risk:
ETH stored inside ETHReceiverVul cannot be recovered.
Users may permanently lose access to deposited funds.

Missing Receiver Validation:
Incorrect receiver configuration may cause ETH transfer failures or unexpected behavior.

Missing Event Logging:
Protocol activity cannot be easily monitored or audited.
Off-chain systems cannot reliably track ETH transfers.

Proof of Concept:
        1.Deploy ETHReceiverVul.
        2.Deploy ETHSenderVul using the ETHReceiverVul address.
        3.Call:sendETH()
            with 1 ETH.
        4.Call:
            contractBalance()
        Result:
        Contract balance becomes 1 ETH.
        5.Attempt to withdraw ETH.
            Result:
                No withdrawal function exists.
                ETH remains permanently locked.

        6.Deploy ETHSenderVul using:
            address(0) as constructor input.
        7.Call:
            sendETH()
            Result:
                Transfer configuration is invalid.
        8.Execute successful ETH transfers.
            Result:
        No custom event is emitted for either:
            ETH reception
            ETH transfer

Root Cause:
    ETHReceiverVul accepts ETH but provides no withdrawal mechanism.
    ETHSenderVul constructor does not validate receiver addresses.
    Neither contract emits events for critical ETH-related actions.

Recommendation:
    Add a secure ETH withdrawal function.
    Validate receiver address during deployment.
    Emit events whenever ETH is received or transferred.

Examples:

    require(_receiver != address(0),"Invalid receiver");

    event ETHReceived(address indexed sender,uint256 amount);

    event ETHSent(address indexed receiver,uint256 amount);
*/
//patched code
contract ETHReceiver{

    /*
        TRACK TOTAL ETH RECEIVED
    */
    uint256 public totalReceived;

    /*
        TRACK LAST SENDER
    */
    address public lastSender;
    address public owner;

    /*
        TRACK NUMBER OF RECEIVES
    */
    uint256 public receiveCounter;

    uint256 public fallbackCounter;
    

    event ReceiveTriggered(address indexed sender,uint256 value);
    event FallbackTriggered(address indexed sender,uint256 values,bytes data);
    event Withdraw(address indexed user,uint256 amount);

    constructor(){
        owner=msg.sender;
    }
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

        emit ReceiveTriggered(msg.sender, msg.value);
    }

       /*
    =====================================================
    FALLBACK
    =====================================================

    ETH + NON EMPTY calldata
    OR
    unknown function call
    */
    fallback() external payable {

        lastSender = msg.sender;
        totalReceived += msg.value;
        fallbackCounter++;

        emit FallbackTriggered(msg.sender, msg.value, msg.data);

     }

    function withdrawEth(uint256 _amount) external {
    require(msg.sender==owner,"Not owner");
    require(address(this).balance >= _amount, "Insufficient balance");

    // (bool success,) =payable(owner).call{value:_amount}("");
    // require(success,"Transfer failed");
    payable(owner).transfer(_amount);
    emit Withdraw(msg.sender,_amount);
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

contract ETHSender{

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
        require(receiver != address(0), "Invalid receiver");
    }

    /*
    =====================================================
    SEND ETH  TRIGGERS receive()
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

     /*
    =====================================================
    TRIGGERS fallback()
    =====================================================
    */
    function sendEthwithData()external payable {
        (bool sucess,)=receiver.call{value:msg.value}(
            abi.encodeWithSignature("fakeFunc()")
        );
        lastSuccess = sucess;
         require(sucess,"ETH transfer failed");
    }
}

