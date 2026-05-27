// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Modify copied memory array
CONCEPT: Storage unaffected
=========================================================

OBJECTIVE

- Learn how copied memory arrays behave
- Understand storage remains unchanged
- Learn independent copy behavior
- Understand memory isolation from storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

When storage array is copied into memory:

uint256[] memory temp = numbers;

A COMPLETELY SEPARATE copy is created.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

After copying:
- modifying memory affects ONLY memory
- original storage remains unchanged
- memory and storage become independent

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many Solidity bugs happen because developers:
- expect storage mutation
- but only modify memory copy

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Memory copies useful for:

- temporary calculations
- filtering
- sorting
- safe transformations
- read-only processing

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Did developer intend memory copy?
- Is storage expected to change?
- Are mutations happening safely?
- Can copying large arrays create DOS?
- Is memory/storage confusion present?

=========================================================
*/

contract ModifyCopiedMemoryArrayVul {

    uint256[] public numbers;

    function addValues() public {

        /*
            STORE VALUES PERMANENTLY
            inside storage array
        */
        numbers.push(100);

        numbers.push(200);

        numbers.push(300);
    }

    function modifyMemoryCopy()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory
        )
    {

        /*
            STORAGE -> MEMORY COPY

            tempArray becomes independent copy.
        */
        uint256[] memory tempArray = numbers;

        /*
            MODIFY MEMORY COPY ONLY
        */
        tempArray[0] = 999;

        /*
            RETURN:
            1. Modified memory copy
            2. Original storage array
        */
        return (tempArray, numbers);
    }

    function getStorageArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
addValues()

STORAGE ARRAY:

[100,200,300]

---------------------------------------------------------

CALL:
modifyMemoryCopy()

EVM ACTIONS:

1. Storage array loaded
2. Full memory copy created
3. tempArray becomes independent
4. tempArray[0] modified
5. Memory copy changes only
6. Original storage untouched

---------------------------------------------------------

MEMORY ARRAY:

[999,200,300]

---------------------------------------------------------

ORIGINAL STORAGE ARRAY:

[100,200,300]

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
addValues()

---------------------------------------------------------

STEP 3:
Call:
getStorageArray()

EXPECTED:
[100,200,300]

---------------------------------------------------------

STEP 4:
Call:
modifyMemoryCopy()

EXPECTED RETURN:

Modified Memory:
[999,200,300]

Original Storage:
[100,200,300]

---------------------------------------------------------

STEP 5:
Call:
getStorageArray()

EXPECTED:
[100,200,300]

OBSERVE:
Storage unchanged.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Copy empty storage array

EXPECTED:
Empty arrays returned

---------------------------------------------------------

TEST:
Modify multiple memory indexes

EXPECTED:
Only memory copy changes

---------------------------------------------------------

TEST:
Repeated function calls

OBSERVE:
Fresh memory copy created every execution

=========================================================
IMPORTANT COPY UNDERSTANDING
=========================================================

THIS LINE:

uint256[] memory tempArray = numbers;

---------------------------------------------------------

CREATES:
Independent memory copy.

---------------------------------------------------------

DOES NOT CREATE:
Storage reference.

=========================================================
MEMORY ISOLATION
=========================================================

BEFORE MODIFICATION

Storage:
[100,200,300]

Memory:
[100,200,300]

---------------------------------------------------------

AFTER MEMORY MODIFICATION

Storage:
[100,200,300]

Memory:
[999,200,300]

---------------------------------------------------------

IMPORTANT:
Storage remains unaffected.

=========================================================
MEMORY VS STORAGE REFERENCE
=========================================================

---------------------------------------------------------
MEMORY COPY
---------------------------------------------------------

uint256[] memory temp = numbers;

Independent copy.

---------------------------------------------------------
STORAGE REFERENCE
---------------------------------------------------------

uint256[] storage temp = numbers;

Direct pointer to storage.

Changes affect original array.

=========================================================
GAS OBSERVATION
=========================================================

COPYING ARRAYS:
Consumes gas

---------------------------------------------------------

Reason:
Every storage element copied into memory.

---------------------------------------------------------

VERY LARGE ARRAYS:
May become expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Extremely common Solidity issue.

Developers may expect:
storage updates

but only modify memory copy.

---------------------------------------------------------
2. SILENT LOGIC FAILURES
---------------------------------------------------------

Protocol logic may silently fail
because state never updates.

---------------------------------------------------------
3. DOS RISK
---------------------------------------------------------

Huge arrays copied into memory
may consume excessive gas.

---------------------------------------------------------
4. REFERENCE VALIDATION
---------------------------------------------------------

Auditors carefully inspect:
- copy semantics
- reference behavior
- mutation expectations

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker inflates storage array size.

Function copying arrays:
becomes too expensive.

Result:
DOS via gas exhaustion.

---------------------------------------------------------

ANOTHER RISK

Critical protocol update expected
to modify storage.

Developer accidentally modifies memory copy only.

Security logic silently breaks.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create STORAGE reference instead
2. Modify referenced array
3. Observe storage changes permanently

BONUS:
Compare:
memory copy vs storage reference behavior

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage-to-memory creates independent copy
- Memory modifications do not affect storage
- Memory arrays are temporary
- Storage persists permanently
- Memory and storage become isolated
- Copying arrays consumes gas
- Large copies may create DOS risks
- Storage references behave differently
- Memory/storage confusion causes bugs
- Auditors inspect reference semantics carefully

=========================================================
*/

/*
AUDIT REPORT

Title: Storage Reference Directly Modifies Persistent State

Severity: Low

Reason:
Using a storage reference creates a direct pointer to blockchain storage.
Any modification through the reference permanently changes contract state.

Location:

Contract: ModifyCopiedMemoryArray
Function: storageRef()

Vulnerability Description:

The function storageRef() creates a storage reference:

uint256[] storage tempArray = numbers;

Unlike memory copies, this reference directly points to the original
storage array.

Any modification performed through tempArray permanently modifies
the numbers storage array.

This behavior is intentional in the patched challenge solution,
but developers commonly confuse storage references with memory copies.

Such confusion may cause accidental state modifications
and silent logic errors in real-world smart contracts.

Impact:
- Permanent modification of blockchain storage
- Possible unintended state mutation
- Logic errors due to memory/storage confusion
- Unexpected protocol behavior if references misunderstood

Proof of Concept:
        1. Deploy contract

        2. Call:
        addValues()

        Storage array:
        [100,200,300]

        3. Call:
        storageRef()

        4. Call:
        getStorageArray()

Returned output:
[100,200,300,10]

Observation:
Storage array permanently changed through storage reference.

Root Cause:
- Direct use of storage reference
- Developer may assume temporary behavior
- Storage references modify original state directly

Recommendation:

Use memory when temporary modifications are intended.

Example:

uint256[] memory tempArray = numbers;

Use storage references only when permanent
state modification is intentionally required.
*/

// patched code 
contract ModifyCopiedMemoryArray {

    uint256[] public numbers;

    function addValues() public {

        /*
            STORE VALUES PERMANENTLY
            inside storage array
        */
        numbers.push(100);

        numbers.push(200);

        numbers.push(300);
    }

    function modifyMemoryCopy()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory
        )
    {

        /*
            STORAGE -> MEMORY COPY

            tempArray becomes independent copy.
        */
        uint256[] memory tempArray = numbers;

        /*
            MODIFY MEMORY COPY ONLY
        */
        tempArray[0] = 999;

        /*
            RETURN:
            1. Modified memory copy
            2. Original storage array
        */
        return (tempArray, numbers);
    }

    function getStorageArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }

    function storageRef()public {
        uint256[] storage tempArray=numbers;
        tempArray.push(10);
    }
}