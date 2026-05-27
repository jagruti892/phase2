// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call function from function
CONCEPT: Execution chaining
=========================================================

OBJECTIVE

- Learn how one function calls another
- Understand execution chaining
- Learn execution stack flow
- Understand chained state updates

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Functions can call:
other functions.

This creates:
execution chains.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Execution flows step-by-step:

Function A
   ->
Function B
   ->
Function C

Then returns backward.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most smart contracts use:
multi-function execution flow.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Execution chaining used in:

- ERC20 transfers
- DeFi swaps
- staking systems
- lending protocols
- liquidation systems
- governance execution

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution order
- hidden state updates
- reentrancy risk
- recursive loops
- validation propagation

=========================================================
*/

contract FunctionExecutionChainingVul {

    /*
        STORAGE VARIABLES
    */
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    /*
    =====================================================
    MAIN ENTRY FUNCTION
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Validate input.
        */
        validateAmount(_amount);

        /*
            STEP 2:
            Add balance.
        */
        addBalance(
            msg.sender,
            _amount
        );

        /*
            STEP 3:
            Update global total.
        */
        updateTotal(_amount);
    }

    /*
    =====================================================
    VALIDATION FUNCTION
    =====================================================
    */

    function validateAmount(
        uint256 _amount
    )
        internal
        pure
    {

        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );
    }

    /*
    =====================================================
    BALANCE UPDATE FUNCTION
    =====================================================
    */

    function addBalance(
        address _user,
        uint256 _amount
    )
        internal
    {

        /*
            Storage update.
        */
        balances[_user] += _amount;
    }

    /*
    =====================================================
    TOTAL UPDATE FUNCTION
    =====================================================
    */

    function updateTotal(
        uint256 _amount
    )
        internal
    {

        totalDeposits += _amount;
    }

    /*
    =====================================================
    CHAINED BONUS FLOW
    =====================================================
    */

    function depositWithBonus(
        uint256 _amount
    )
        external
    {

        /*
            Function calling another function.
        */
        depositInternal(_amount);

        /*
            Additional bonus logic.
        */
        addBalance(
            msg.sender,
            10
        );
    }

    /*
    =====================================================
    INTERNAL DEPOSIT FLOW
    =====================================================
    */

    function depositInternal(
        uint256 _amount
    )
        internal
    {

        /*
            Chained execution continues.
        */
        validateAmount(_amount);

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(50)

=========================================================

STEP 1:
deposit() executes.

---------------------------------------------------------

STEP 2:
deposit() calls:

validateAmount(50)

---------------------------------------------------------

VALIDATION PASSES

---------------------------------------------------------

CONTROL RETURNS TO:
deposit()

---------------------------------------------------------

STEP 3:
deposit() calls:

addBalance(Alice, 50)

---------------------------------------------------------

STORAGE UPDATE:

balances[Alice] += 50

---------------------------------------------------------

CONTROL RETURNS TO:
deposit()

---------------------------------------------------------

STEP 4:
deposit() calls:

updateTotal(50)

---------------------------------------------------------

STORAGE UPDATE:

totalDeposits += 50

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 50

totalDeposits = 50

=========================================================
CHAINED FLOW TRACE
=========================================================

CALL:
depositWithBonus(100)

=========================================================

STEP 1:
depositWithBonus() executes.

---------------------------------------------------------

STEP 2:
Calls:

depositInternal(100)

---------------------------------------------------------

depositInternal() calls:

validateAmount(100)

---------------------------------------------------------

Validation passes.

---------------------------------------------------------

depositInternal() calls:

addBalance(Alice, 100)

---------------------------------------------------------

depositInternal() calls:

updateTotal(100)

---------------------------------------------------------

depositInternal() finishes.

---------------------------------------------------------

CONTROL RETURNS TO:
depositWithBonus()

---------------------------------------------------------

STEP 3:
Bonus added:

addBalance(Alice, 10)

---------------------------------------------------------

FINAL STATE:

balances[Alice] += 110

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Function execution behaves like:
STACK FLOW.

---------------------------------------------------------

Execution enters:
called function

Then returns:
to caller function.

=========================================================
VISUAL FLOW
=========================================================

depositWithBonus()
    |
    +--> depositInternal()
             |
             +--> validateAmount()
             |
             +--> addBalance()
             |
             +--> updateTotal()

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(50)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
50

---------------------------------------------------------

STEP 4:
Call:
totalDeposits()

EXPECTED:
50

---------------------------------------------------------

STEP 5:
Call:
depositWithBonus(100)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
160

---------------------------------------------------------

STEP 7:
Call:
totalDeposits()

EXPECTED:
150

=========================================================
IMPORTANT FUNCTION CHAINING UNDERSTANDING
=========================================================

Functions may:
- validate
- compute
- mutate state
- call helper functions

---------------------------------------------------------

Execution order matters heavily.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. HIDDEN STATE MUTATIONS
---------------------------------------------------------

Called functions may:
modify storage unexpectedly.

---------------------------------------------------------
2. VALIDATION GAPS
---------------------------------------------------------

One chain path may skip validation.

---------------------------------------------------------
3. RECURSION RISK
---------------------------------------------------------

Functions calling each other recursively
may exhaust gas.

---------------------------------------------------------
4. EXECUTION ORDER BUGS
---------------------------------------------------------

Incorrect call ordering
may break invariants.

=========================================================
GAS OBSERVATION
=========================================================

More chained calls:
More gas usage.

---------------------------------------------------------

Deep chains:
Harder auditing.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which functions call others?
- What state changes occur?
- Is validation always enforced?
- Can attacker influence flow?
- Are external calls involved?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets validation
in one chain path.

Attacker uses unsafe path.

---------------------------------------------------------

ANOTHER RISK

External call inside chain
may enable reentrancy.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Call hierarchy
2. Execution order
3. State mutations
4. Validation propagation
5. Revert behavior

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw chain
2. Add fee deduction function
3. Add blacklist validation function
4. Trace full execution manually

BONUS:
Create recursive function
and observe gas behavior.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Functions can call other functions
- Execution follows stack-like flow
- Called function returns control to caller
- Function chains organize logic
- Hidden state mutations may occur
- Validation must propagate through chains
- Execution order matters heavily
- Recursive calls can be dangerous
- Auditors trace full call hierarchy
- Function chaining is core Solidity architecture

=========================================================
*/


//patched code
/*
=========================================================
PATCHED VERSION: Function Execution Chaining
AUDITOR VERSION WITH FULL FLOW CONTROL
=========================================================
*/

// patched code 

contract FunctionExecutionChaining {
    mapping (address=>uint256)public balances;
    mapping (address=>bool)public blacklisted;

    address public owner;
    uint256 public totalDeposit;

    constructor(){
        owner=msg.sender;
    }

    function blacklistUser(address _user)external {
        require(msg.sender==owner,"Not owner");
        blacklisted[_user]=true;    
    }

    function validateUser(address _user)internal view {
        require(blacklisted[_user]==false,"user is blacklisted");
    }

    function validateAmt(uint256 _amt)internal pure{
        require(_amt>0,"amount can't be zero");
        require(_amt<=100,"amount is too large");
    }

    function calcFee(uint256 _amount)internal pure returns(uint256){
        return (_amount*5)/100;
    }

    function addBalance(address _user,uint256 _amt)internal {
        balances[_user]+=_amt;
    }

    function updateTotal(uint256 _amt)internal {
        totalDeposit+=_amt;
    }

    //  DEPOSIT FLOW (CHAINED)
    function deposit(uint256 _amt)external {
        validateAmt(_amt);
        validateUser(msg.sender);
        addBalance(msg.sender, _amt);
        updateTotal(_amt);
    }

    // withdraw
    function _withdrawInternal(address _user,uint256 _amount)internal {
        // calculate fee
        uint256 fee=calcFee(_amount);
        // final amount user receives
        uint256 finalAmt=_amount-fee;
        balances[_user]-=_amount;
    }
}