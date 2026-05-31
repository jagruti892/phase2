// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Fail external call intentionally
CONCEPT: Error handling
=========================================================

OBJECTIVE

- Learn how external calls fail
- Understand low-level call return values
- Learn proper error handling
- Understand rollback behavior

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

External calls may fail because:

- target reverts
- target rejects ETH
- out-of-gas occurs
- function missing
- malicious behavior

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Low-level call() does NOT auto-revert.

---------------------------------------------------------

It returns:

(bool success, bytes memory data)

---------------------------------------------------------

Developer must:
handle failure manually.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Unchecked external-call failures caused:
many Solidity vulnerabilities.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Error handling critical in:

- token transfers
- swaps
- bridges
- governance execution
- lending systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unchecked return values
- partial execution
- rollback behavior
- silent failures
- external trust assumptions

=========================================================
TARGET CONTRACT
=========================================================
*/

contract Rejector {

    /*
        TRACK CALL COUNT
    */
    uint256 public callCounter;

    /*
    =====================================================
    NORMAL FUNCTION
    =====================================================
    */

    function normalFunction()
        external
    {

        callCounter++;
    }

    /*
    =====================================================
    ALWAYS FAIL
    =====================================================

    Intentionally reverts.
    */

    function alwaysFail()
        external
        pure
    {

        revert("Intentional failure");
    }

    /*
    =====================================================
    REJECT ETH
    =====================================================

    Reject plain ETH transfers.
    */

    receive()
        external
        payable
    {

        revert("ETH rejected");
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/

contract ExternalCallHandler {

    /*
        TRACK RESULTS
    */
    bool public lastSuccess;

    bytes public lastData;

    uint256 public localCounter;

    /*
    =====================================================
    SAFE EXTERNAL CALL
    =====================================================
    */

    function safeExternalCall(
        address _target
    )
        external
    {

        /*
            Local state update BEFORE call.
        */
        localCounter++;

        /*
            Low-level external call.
        */
        (bool success, bytes memory data) =
            _target.call(
                abi.encodeWithSignature(
                    "normalFunction()"
                )
            );

        /*
            Store results.
        */
        lastSuccess = success;

        lastData = data;

        /*
            Require success.
        */
        require(
            success,
            "External call failed"
        );
    }

    /*
    =====================================================
    CALL FAILING FUNCTION
    =====================================================
    */

    function triggerFailure(
        address _target
    )
        external
    {

        /*
            Local state update FIRST.
        */
        localCounter++;

        /*
            Call reverting function.
        */
        (bool success, bytes memory data) =
            _target.call(
                abi.encodeWithSignature(
                    "alwaysFail()"
                )
            );

        /*
            Save results.
        */
        lastSuccess = success;

        lastData = data;

        /*
            IMPORTANT:
            success = false

            Manual failure handling required.
        */
        require(
            success,
            "Low-level call failed"
        );
    }

    /*
    =====================================================
    SEND ETH TO REJECTOR
    =====================================================
    */

    function sendETH(
        address payable _target
    )
        external
        payable
    {

        /*
            Attempt ETH transfer.
        */
        (bool success, bytes memory data) =
            _target.call{
                value: msg.value
            }("");

        /*
            Save result.
        */
        lastSuccess = success;

        lastData = data;

        /*
            Revert if transfer failed.
        */
        require(
            success,
            "ETH transfer rejected"
        );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy Rejector

---------------------------------------------------------

STEP 2:
Deploy ExternalCallHandler

=========================================================
TRACE:
safeExternalCall()
=========================================================

STEP 1:
localCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 2
=========================================================

Low-level call executes:

_target.call(
    abi.encodeWithSignature(
        "normalFunction()"
    )
)

=========================================================
STEP 3
=========================================================

Target function executes successfully.

---------------------------------------------------------

success = true

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

Transaction succeeds.

=========================================================
FAILURE TRACE
=========================================================

CALL:
triggerFailure()

=========================================================

STEP 1:
localCounter++

---------------------------------------------------------

NEW VALUE:
2

=========================================================
STEP 2
=========================================================

External call executes:

alwaysFail()

=========================================================
STEP 3
=========================================================

Target contract executes:

revert("Intentional failure")

---------------------------------------------------------

External call fails.

---------------------------------------------------------

success = false

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

FAILS

---------------------------------------------------------

FULL TRANSACTION REVERTS

=========================================================
IMPORTANT ROLLBACK OBSERVATION
=========================================================

Even though:

localCounter++

executed BEFORE external call,

---------------------------------------------------------

ALL state changes revert.

---------------------------------------------------------

FINAL VALUE:
unchanged

=========================================================
WHY?
=========================================================

Ethereum transactions are:
ATOMIC.

---------------------------------------------------------

Either:
ALL succeeds

OR

ALL reverts.

=========================================================
ETH FAILURE TRACE
=========================================================

CALL:
sendETH()

VALUE:
1 ETH

=========================================================

STEP 1:
ETH sent to Rejector.

---------------------------------------------------------

receive() executes.

=========================================================
STEP 2
=========================================================

receive() reverts:

"ETH rejected"

---------------------------------------------------------

External call fails.

---------------------------------------------------------

success = false

=========================================================
STEP 3
=========================================================

require(success)

---------------------------------------------------------

Transaction fully reverts.

=========================================================
IMPORTANT LOW-LEVEL CALL UNDERSTANDING
=========================================================

call() NEVER auto-reverts.

---------------------------------------------------------

Developer MUST check:

success

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Unchecked external calls =
dangerous vulnerability.

---------------------------------------------------------

Execution may continue
after silent failure.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy Rejector

---------------------------------------------------------

STEP 2:
Deploy ExternalCallHandler

---------------------------------------------------------

STEP 3:
Call:
safeExternalCall()

Input:
Rejector address

---------------------------------------------------------

EXPECTED:
Success

---------------------------------------------------------

STEP 4:
Call:
triggerFailure()

---------------------------------------------------------

EXPECTED:
Transaction reverts

---------------------------------------------------------

STEP 5:
Check:
localCounter()

IMPORTANT:
Counter unchanged due to rollback.

---------------------------------------------------------

STEP 6:
In VALUE field:
enter 1 ether

---------------------------------------------------------

STEP 7:
Call:
sendETH()

---------------------------------------------------------

EXPECTED:
Revert with:
"ETH transfer rejected"

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNCHECKED RETURN VALUES
---------------------------------------------------------

Failure ignored silently.

---------------------------------------------------------
2. PARTIAL EXECUTION ASSUMPTIONS
---------------------------------------------------------

Developers misunderstand rollback behavior.

---------------------------------------------------------
3. MALICIOUS REVERTS
---------------------------------------------------------

Target intentionally blocks execution.

---------------------------------------------------------
4. DOS VIA REVERT
---------------------------------------------------------

External contract halts protocol flow.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may:

- intentionally revert
- block protocol logic
- trigger DOS
- exploit unchecked failures

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Are call() return values checked?
- Can external calls fail silently?
- Does revert rollback state safely?
- Can malicious contracts DOS execution?
- Is error handling correct?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External call behavior
2. Failure handling
3. Rollback mechanics
4. Return-value validation
5. DOS possibilities

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Handle failure WITHOUT reverting
2. Add try/catch example
3. Decode revert messages
4. Compare call() vs interface call

BONUS:
Create malicious DOS contract.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External calls may fail
- call() returns success manually
- call() does not auto-revert
- require(success) handles failures safely
- Transactions rollback atomically
- Reverts undo previous state updates
- Unchecked return values are dangerous
- External contracts are untrusted
- Error handling is security critical
- Auditors inspect failure logic carefully

=========================================================
*/