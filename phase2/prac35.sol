// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Validate calldata input manually
CONCEPT: Input security
=========================================================

OBJECTIVE

- Learn how to validate external calldata inputs
- Understand why all external input is untrusted
- Learn manual validation techniques
- Understand security risks from unchecked input

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

ALL calldata input is attacker-controlled.

Never trust:
- numbers
- addresses
- arrays
- strings
- booleans

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Without validation:
attackers may:
- break logic
- bypass rules
- exhaust gas
- corrupt accounting

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Input validation is one of the MOST IMPORTANT
smart contract security practices.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Validation used in:

- token transfers
- staking systems
- governance voting
- DeFi routers
- NFT minting
- access control

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Missing require() checks
- Unbounded arrays
- Invalid addresses
- Overflow assumptions
- Authorization validation
- Business logic validation

=========================================================
*/

contract ValidateCalldataInputvul {

    /*
        STATE VARIABLES

        Permanent blockchain state.
    */
    uint256 public storedAmount;

    address public lastReceiver;

    /*
    =====================================================
    VALIDATE UINT INPUT
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            VALIDATION:
            Amount must be greater than zero.
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        /*
            VALIDATION:
            Prevent excessively large deposits.
        */
        require(
            _amount <= 1000 ether,
            "Amount too large"
        );

        /*
            Store validated value.
        */
        storedAmount = _amount;
    }

    /*
    =====================================================
    VALIDATE ADDRESS INPUT
    =====================================================
    */

    function setReceiver(
        address _receiver
    )
        external
    {

        /*
            VALIDATION:
            Prevent zero address.
        */
        require(
            _receiver != address(0),
            "Invalid address"
        );

        lastReceiver = _receiver;
    }

    /*
    =====================================================
    VALIDATE ARRAY INPUT
    =====================================================
    */

    function processArray(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {

        /*
            VALIDATION:
            Prevent huge arrays.
        */
        require(
            _numbers.length <= 100,
            "Array too large"
        );

        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {

            /*
                VALIDATION:
                Reject zero values.
            */
            require(
                _numbers[i] > 0,
                "Invalid number"
            );

            total += _numbers[i];
        }

        return total;
    }

    /*
    =====================================================
    VALIDATE STRING INPUT
    =====================================================
    */

    function validateMessage(
        string calldata _message
    )
        external
        pure
        returns (bool)
    {

        /*
            Convert string to bytes
            to check length.
        */
        bytes calldata messageBytes =
            bytes(_message);

        /*
            VALIDATION:
            Reject empty strings.
        */
        require(
            messageBytes.length > 0,
            "Empty message"
        );

        /*
            VALIDATION:
            Prevent excessively large input.
        */
        require(
            messageBytes.length <= 50,
            "Message too long"
        );

        return true;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(100)

EVM ACTIONS:

1. Input arrives in calldata
2. require() validation checks run
3. Validation passes
4. Storage updated permanently

---------------------------------------------------------

FINAL STORAGE:

storedAmount = 100

=========================================================

CALL:
deposit(0)

EVM ACTIONS:

1. Input arrives
2. require() fails
3. Transaction reverts
4. State unchanged

---------------------------------------------------------

ERROR:

"Amount must be > 0"

=========================================================

CALL:
processArray([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Array length validated
3. Loop validates each element
4. Total calculated
5. Result returned

---------------------------------------------------------

RESULT:
6

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(100)

EXPECTED:
Success

---------------------------------------------------------

STEP 3:
Call:
deposit(0)

EXPECTED:
Revert

---------------------------------------------------------

STEP 4:
Call:
setReceiver(address(0))

EXPECTED:
Revert

---------------------------------------------------------

STEP 5:
Call:
processArray([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 6:
Call:
processArray([1,0,3])

EXPECTED:
Revert

---------------------------------------------------------

STEP 7:
Call:
validateMessage("Hello")

EXPECTED:
true

---------------------------------------------------------

STEP 8:
Call:
validateMessage("")

EXPECTED:
Revert

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Very large arrays

EXPECTED:
Rejected

---------------------------------------------------------

TEST:
Huge numbers

EXPECTED:
Rejected if above limit

---------------------------------------------------------

TEST:
Zero addresses

EXPECTED:
Rejected

---------------------------------------------------------

TEST:
Very long strings

EXPECTED:
Rejected

=========================================================
IMPORTANT SECURITY UNDERSTANDING
=========================================================

ALL EXTERNAL INPUT IS:

- attacker-controlled
- untrusted
- potentially malicious

---------------------------------------------------------

NEVER ASSUME:
inputs are safe.

=========================================================
COMMON VALIDATION CHECKS
=========================================================

---------------------------------------------------------
NUMBERS
---------------------------------------------------------

- > 0
- within limits
- no overflow assumptions

---------------------------------------------------------
ADDRESSES
---------------------------------------------------------

- not zero address
- authorized user
- expected contract

---------------------------------------------------------
ARRAYS
---------------------------------------------------------

- max length
- valid elements
- bounded loops

---------------------------------------------------------
STRINGS
---------------------------------------------------------

- non-empty
- max length

=========================================================
WHY VALIDATION MATTERS
=========================================================

WITHOUT VALIDATION:

Attackers may:
- trigger DOS
- bypass logic
- corrupt state
- break accounting

=========================================================
GAS OBSERVATION
=========================================================

MORE VALIDATION:
More gas

---------------------------------------------------------

BUT:
Security is more important
than minimal gas savings.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MISSING VALIDATION
---------------------------------------------------------

Most common vulnerability class.

---------------------------------------------------------
2. DOS VIA LARGE INPUTS
---------------------------------------------------------

Huge arrays may:
- exhaust gas
- break loops

---------------------------------------------------------
3. ZERO ADDRESS RISKS
---------------------------------------------------------

May:
- burn funds
- break ownership logic

---------------------------------------------------------
4. BUSINESS LOGIC VALIDATION
---------------------------------------------------------

Auditors inspect:
whether protocol rules
are enforced correctly.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends:
- massive arrays
- zero addresses
- invalid values
- unexpected inputs

Without validation:
protocol behavior breaks.

---------------------------------------------------------

REAL-WORLD IMPACT

Many exploits occurred because:
developers trusted external input.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Validate nested calldata arrays
2. Reject arrays larger than 50x50
3. Reject duplicate values

BONUS:
Add custom errors instead of require strings.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- All calldata is attacker-controlled
- External input must be validated
- require() enforces rules
- Arrays need size limits
- Addresses need zero-address checks
- Strings need length validation
- Validation prevents DOS and logic bugs
- Security more important than tiny gas savings
- Untrusted input is a major attack surface
- Auditors inspect validation carefully

=========================================================
*/

/*
Audit Report

Title: Missing Access Control on Sensitive State Updates

Severity: Low

Reason:
The contract validates calldata inputs correctly,
but does not restrict who can modify
important state variables.

Any external user may overwrite:

- storedAmount
- lastReceiver

Location:

Contract: ValidateCalldataInputVul

Functions:
- deposit()
- setReceiver()

Vulnerability Description:

The contract performs proper input validation
for:

- uint values
- addresses
- arrays
- strings

However, the contract does not validate
caller authorization before updating
sensitive storage variables.

Vulnerable logic:

storedAmount = _amount;

lastReceiver = _receiver;

Any external account may call:

deposit()

or:

setReceiver()

and overwrite existing state.

The contract lacks protections such as:

- ownership checks
- admin validation
- role restrictions

Impact:

An attacker may:

- overwrite stored protocol values
- manipulate receiver addresses
- corrupt application state
- disrupt intended business logic

This may cause:

- incorrect accounting
- unexpected protocol behavior
- trust issues
- state inconsistency

Proof of Concept:
        1. Deploy contract.
        2. User A calls:
        deposit(100)
            Observe:
            storedAmount = 100
        3. Attacker calls:
        deposit(999)
            Observe:
            storedAmount overwritten to 999
        4. User A calls:
        setReceiver(0x123...)
            Observe:
            lastReceiver = 0x123...
        5. Attacker calls:
        setReceiver(0x456...)
            Observe:
            lastReceiver overwritten to 0x456...

Root Cause:
    The contract validates input values
    but does not validate who is allowed
    to modify sensitive state.

Missing authorization checks:

    require(msg.sender == owner);

Recommendation:

Restrict sensitive state-changing functions
using access control.

Example:

address public owner;

modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

function deposit(uint256 _amount)
    external
    onlyOwner
{
    ...
}

function setReceiver(address _receiver)
    external
    onlyOwner
{
    ...
}
*/
// patched code 
contract ValidateCalldataInput{
    error outerArrayEmpty();
    error outerArrayTooLarge();
    error innerArrayTooLarge();
    error innerArrayEmpty();
    error duplicateValue(uint256 value);

    function inputCallDataCheck(uint256[][] calldata _matrix) external pure returns (bool){
        if(_matrix.length==0){
            revert outerArrayEmpty(); // checks if atleast 1 row is there
        }
        if(_matrix.length>50){
            revert outerArrayTooLarge(); // rejects if rows are more then 50
        }
        /* DUPLICATE TRACKING 
        Since mappings cannot exist in memory, we use a fixed-size boolean array. */
        bool[10000] memory seen;

        // looping outer array
        for(uint256 i=0;i<_matrix.length;i++){
            if(_matrix[i].length==0){
                revert innerArrayEmpty();
            }
            if(_matrix[i].length>50){
                revert innerArrayTooLarge();
            }
            for(uint256 j=0;j<_matrix[i].length;j++){
                uint256 value=_matrix[i][j];
                // DUPLICATE CHECK
                if(seen[value]){
                    revert duplicateValue(value);
                }
                seen[value]=true;
            }
        }
        return true;
    }
}