// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call contract from contract
CONCEPT: Nested execution
=========================================================

OBJECTIVE

- Learn how one contract calls another
- Understand nested execution flow
- Learn msg.sender behavior across contracts
- Understand inter-contract trust assumptions

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Contracts can directly interact
with other deployed contracts.

---------------------------------------------------------

Execution may flow like:

User
   ->
Contract A
   ->
Contract B

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

During nested calls:

msg.sender changes.

---------------------------------------------------------

Inside Contract B:

msg.sender =
Contract A

NOT original user.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Modern Solidity systems are:

multi-contract architectures.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested calls appear in:

- ERC20 token interactions
- routers
- lending protocols
- staking systems
- NFT marketplaces
- bridges

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution flow
- msg.sender transitions
- trust assumptions
- nested state changes
- reentrancy windows

=========================================================
TARGET CONTRACT
=========================================================
*/

contract DataStorageVul {
    /*
        STORED VALUE
    */
    uint256 public storedNumber;

    /*
        TRACK LAST CALLER
    */
    address public lastCaller;

    /*
    =====================================================
    STORE NUMBER
    =====================================================
    */

    function setNumber(uint256 _number )  external {

        /*
            Save input.
        */
        storedNumber = _number;

        /*
            Store msg.sender.

            IMPORTANT:
            This will become
            calling contract address
            during nested execution.
        */
        lastCaller = msg.sender;
    }

    /*
    =====================================================
    READ VALUE
    =====================================================
    */

    function getNumber() external view returns (uint256){

        return storedNumber;
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/

contract NestedCallerVul {
    /*
        TARGET CONTRACT
    */
    DataStorageVul public target;

    /*
        TRACK LOCAL EXECUTION
    */
    uint256 public localCounter;

    /*
        STORE LAST READ VALUE
    */
    uint256 public lastReadValue;

    /*
        CONSTRUCTOR
    */
    constructor(address _target) {
        /*
            Save target contract reference.
        */
        target = DataStorageVul(_target);
    }

    /*
    =====================================================
    CALL TARGET CONTRACT
    =====================================================
    */

    function callSetNumber( uint256 _number ) external {
        /*
            Local state update.
        */
        localCounter++;

        /*
            EXTERNAL CONTRACT CALL

            Execution jumps into:
            DataStorage.setNumber()
        */
        target.setNumber(_number);
    }

    /*
    =====================================================
    READ FROM TARGET CONTRACT
    =====================================================
    */

    function readTargetNumber()  external {
        /*
            Nested external read.
        */
        uint256 value = target.getNumber();

        /*
            Save locally.
        */
        lastReadValue = value;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy DataStorage

---------------------------------------------------------

STEP 2:
Deploy NestedCaller

Constructor input:
DataStorage address

=========================================================
TRACE:
callSetNumber(100)
=========================================================

STEP 1:
User calls:

NestedCaller.callSetNumber(100)

=========================================================
STEP 2
=========================================================

NestedCaller executes:

localCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 3
=========================================================

External contract call:

target.setNumber(100)

---------------------------------------------------------

Execution CONTEXT switches.

=========================================================
STEP 4
=========================================================

Execution enters:
DataStorage contract

---------------------------------------------------------

storedNumber = 100

=========================================================
STEP 5
=========================================================

IMPORTANT:

Inside DataStorage:

msg.sender =
NestedCaller contract

---------------------------------------------------------

NOT original user.

=========================================================
STEP 6
=========================================================

lastCaller =
NestedCaller address

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
NestedCaller.localCounter
---------------------------------------------------------

1

---------------------------------------------------------
DataStorage.storedNumber
---------------------------------------------------------

100

---------------------------------------------------------
DataStorage.lastCaller
---------------------------------------------------------

NestedCaller address

=========================================================
IMPORTANT msg.sender UNDERSTANDING
=========================================================

FLOW:

User
   ->
NestedCaller
   ->
DataStorage

---------------------------------------------------------

Inside DataStorage:

msg.sender =
NestedCaller

=========================================================
WHY THIS IS IMPORTANT
=========================================================

Authentication logic may fail
if developer assumes:

msg.sender == original user

=========================================================
READ TRACE
=========================================================

CALL:
readTargetNumber()

=========================================================

STEP 1:
NestedCaller calls:

target.getNumber()

=========================================================
STEP 2
=========================================================

Execution enters:
DataStorage

---------------------------------------------------------

storedNumber returned.

=========================================================
STEP 3
=========================================================

Returned value saved:

lastReadValue = storedNumber

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy DataStorage

---------------------------------------------------------

STEP 2:
Deploy NestedCaller

Input:
DataStorage address

---------------------------------------------------------

STEP 3:
Call:
callSetNumber(100)

---------------------------------------------------------

STEP 4:
Open DataStorage

---------------------------------------------------------

STEP 5:
Call:
storedNumber()

EXPECTED:
100

---------------------------------------------------------

STEP 6:
Call:
lastCaller()

EXPECTED:
NestedCaller contract address

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Nested execution changes:

---------------------------------------------------------
CONTROL FLOW
---------------------------------------------------------

and

---------------------------------------------------------
AUTHENTICATION CONTEXT
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. msg.sender CONFUSION
---------------------------------------------------------

Authentication bypass possible.

---------------------------------------------------------
2. TRUST ASSUMPTIONS
---------------------------------------------------------

External contracts may behave maliciously.

---------------------------------------------------------
3. REENTRANCY
---------------------------------------------------------

Nested calls create callback opportunities.

---------------------------------------------------------
4. FAILURE PROPAGATION
---------------------------------------------------------

Nested revert breaks entire transaction.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers exploit:

- msg.sender assumptions
- nested callback logic
- external state assumptions
- recursive execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors trace:

- external jumps
- msg.sender changes
- storage mutations
- nested execution paths
- trust boundaries

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors build:

---------------------------------------------------------
EXECUTION GRAPH
---------------------------------------------------------

to understand:

- control flow
- state dependencies
- attack surface

=========================================================
WHY NESTED EXECUTION IS RISKY
=========================================================

More contracts =
more assumptions.

---------------------------------------------------------

More assumptions =
larger attack surface.

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add ETH transfers
2. Add low-level call()
3. Add failing nested call
4. Add malicious callback contract

BONUS:
Build mini router contract.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Contracts can call other contracts
- Nested execution changes msg.sender
- Execution context switches externally
- Nested calls increase complexity
- External calls create attack surface
- Authentication assumptions are dangerous
- Reverts propagate across nested calls
- Auditors trace execution flow carefully
- Multi-contract systems are harder to secure
- Inter-contract trust assumptions are critical

=========================================================
*/

/*
Audit Report

Title: Unrestricted State Modification in setNumber()

Severity: Informational

Reason:
The function allows any external user to modify protocol state. However, based on the contract design, this behavior appears intentional to demonstrate nested contract execution and msg.sender transitions.

Location:

Contract: DataStorageVul
Function: setNumber()

Vulnerability Description:

The setNumber() function allows any external user or contract to modify the storedNumber state variable.

function setNumber(uint256 _number) external {
storedNumber = _number;
lastCaller = msg.sender;
}

No authorization checks are implemented.
Any user may directly call:
setNumber(100)
    or
setNumber(999)
and overwrite the previously stored value.

Impact:
An attacker can arbitrarily modify storedNumber.
If this variable controlled critical protocol logic such as:

protocol parameters
pricing configuration
treasury settings
access-control configuration

then unauthorized users could manipulate protocol behavior.
However, in the current educational example the purpose of the contract is to demonstrate:
    nested contract calls
    msg.sender transitions
    execution context changes

Therefore the practical security impact is limited.

Proof of Concept:

1.Deploy DataStorageVul.
2.User A calls:
setNumber(100)
Result:
storedNumber = 100

3.Attacker calls:
setNumber(999)
Result:
storedNumber = 999

4.State changes successfully.

Root Cause:

The function is declared external without any authorization mechanism.
No require() statement validates caller permissions.
Important Design Consideration:
This contract is intentionally used by NestedCallerVul.

Execution flow:

User
->
NestedCallerVul
->
DataStorageVul

Inside DataStorageVul:
msg.sender == NestedCallerVul
NOT the original user.

Therefore adding:
require(msg.sender == owner);

would cause nested calls to fail unless the NestedCallerVul contract itself were designated as the authorized caller.

Recommendation:
If the contract is intended for production use, implement an authorization model that explicitly supports trusted 
caller contracts.

Example:

address public authorizedCaller;
function setNumber(uint256 _number) external {
require(
    msg.sender == authorizedCaller,
    "Unauthorized caller"
);
storedNumber = _number;
lastCaller = msg.sender;

}
*/
//patched code
contract DataStorage {
    /*
        STORED VALUE
    */
    uint256 public storedNumber;

    /*
        TRACK LAST CALLER
    */
    address public lastCaller;
// ETH transfers
    event ETHReceived(address sender,uint256 amount);

    receive() external payable {
    emit ETHReceived(msg.sender, msg.value);
    }

    /*
    =====================================================
    STORE NUMBER
    =====================================================
    */

    function setNumber(uint256 _number )  external {

        /*
            Save input.
        */
        storedNumber = _number;

        /*
            Store msg.sender.

            IMPORTANT:
            This will become
            calling contract address
            during nested execution.
        */
        lastCaller = msg.sender;
    }

    /*
    =====================================================
    READ VALUE
    =====================================================
    */

    function getNumber() external view returns (uint256){

        return storedNumber;
    }
// failing nested call
    function failFunction() external pure {
        revert("Intentional failure");
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/

contract NestedCaller {
    DataStorage public target;
    uint256 public localCounter;

    uint256 public lastReadValue;
    constructor(address _target) {
        /*
            Save target contract reference.
        */
        target = DataStorage(payable (_target));
    }

    /*
    =====================================================
    CALL TARGET CONTRACT
    =====================================================
    */

    function callSetNumber( uint256 _number ) external {
        localCounter++;

        target.setNumber(_number);
    }
// low-level call()
    function setLowLevelCall(uint256 _number) external {
        (bool success,)=address(target).call(abi.encodeWithSignature("setNumber(uint256)", _number));
        require(success,"Low level call failed"); 
    }
    /*
    =====================================================
    READ FROM TARGET CONTRACT
    =====================================================
    */

    function readTargetNumber()  external {
    
        uint256 value = target.getNumber();

        lastReadValue = value;
    }
// ETH transfers
    function sendETH() external payable {
    payable(address(target)).transfer(msg.value);
    }
// failing nested call
    function callFaillingfuncCall() external view  {
        target.failFunction();
    }

    function sendETHToMalicious(address payable malicious) external payable{
    (bool success,)=malicious.call{value:msg.value}("");
    require(success,"ETH tranfer failed");
    }
}
// malicious callback contract
contract MaliciousCallback {
    event BeforeCall();
    event CallbackTriggered();
    NestedCaller public caller;
    constructor(address _caller) {
        caller = NestedCaller(_caller);
    }

    receive() external payable {
        emit BeforeCall();
        caller.callSetNumber(999);
          emit CallbackTriggered();
    }

}

contract MiniRouter {
    function routeCall( address target, uint256 value ) external {

        DataStorage(payable (target)).setNumber(value);
    }
}