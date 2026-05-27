// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create memory array
CONCEPT: Temporary arrays
=========================================================

OBJECTIVE

- Learn how memory arrays work in Solidity
- Understand temporary array allocation
- Learn difference between memory arrays and storage arrays
- Understand memory array lifecycle

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory arrays:
- are temporary
- exist only during execution
- disappear after function finishes

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Memory arrays do NOT persist
on blockchain storage.

They are useful for:
- temporary calculations
- returning data
- processing values
- intermediate logic

---------------------------------------------------------
MEMORY ARRAY VS STORAGE ARRAY
---------------------------------------------------------

MEMORY ARRAY:
- temporary
- cheaper
- disappears after execution

STORAGE ARRAY:
- permanent
- expensive
- persists on blockchain

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Memory arrays used in:

- batch calculations
- temporary filtering
- returning lists
- internal processing
- aggregation logic

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is memory used safely?
- Is storage accidentally modified?
- Can large arrays cause DOS?
- Are loops scalable?
- Is memory allocation controlled?

=========================================================
*/

contract MemoryArrayVul {

    uint256[] public storedNumbers;

    function createMemoryArray()
        public
        pure
        returns (uint256[] memory)
    {

        /*
            CREATE MEMORY ARRAY

            new uint256[](3)

            Creates temporary array in memory
            with fixed size = 3
        */
        uint256[] memory tempArray = new uint256[](3);

        /*
            Store values inside memory array
        */
        tempArray[0] = 10;

        tempArray[1] = 20;

        tempArray[2] = 30;

        /*
            Return temporary memory array
        */
        return tempArray;
    }

    function calculateSquares(uint256 _number)
        public
        pure
        returns (uint256[] memory)
    {

        /*
            Temporary memory array
        */
        uint256[] memory squares = new uint256[](3);

        /*
            Store calculated values
        */
        squares[0] = _number;

        squares[1] = _number * _number;

        squares[2] = _number * _number * _number;

        return squares;
    }

    function storeValue(uint256 _value) public {

        /*
            STORAGE ARRAY

            This persists permanently.
        */
        storedNumbers.push(_value);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createMemoryArray()

EVM ACTIONS:

1. Memory allocated temporarily
2. Array size = 3 created
3. Values inserted
4. Array returned
5. Memory cleared after execution

---------------------------------------------------------

IMPORTANT

tempArray does NOT persist permanently.

---------------------------------------------------------

CALL:
calculateSquares(2)

MEMORY ARRAY CONTENT:

[2,4,8]

---------------------------------------------------------

AFTER EXECUTION

Memory array destroyed automatically.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createMemoryArray()

EXPECTED:
[10,20,30]

---------------------------------------------------------

STEP 3:
Call:
calculateSquares(2)

EXPECTED:
[2,4,8]

---------------------------------------------------------

STEP 4:
Call:
storedNumbers(0)

EXPECTED:
Error

Reason:
Nothing stored permanently yet.

---------------------------------------------------------

STEP 5:
Call:
storeValue(999)

---------------------------------------------------------

STEP 6:
Call:
storedNumbers(0)

EXPECTED:
999

OBSERVE:
Storage array persists.
Memory array does not.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Use zero values

calculateSquares(0)

EXPECTED:
[0,0,0]

---------------------------------------------------------

TEST:
Use large values

EXPECTED:
Solidity ^0.8.x overflow protection applies

---------------------------------------------------------

TEST:
Repeated calls

OBSERVE:
Fresh memory array created each execution

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

THIS CREATES MEMORY ARRAY:

new uint256[](3)

---------------------------------------------------------

ARRAY EXISTS ONLY:
during function execution.

---------------------------------------------------------

AFTER FUNCTION ENDS:
memory cleared automatically.

---------------------------------------------------------

VERY IMPORTANT

Memory arrays:
- cannot use push()
- require fixed size during creation

=========================================================
MEMORY ARRAY LIMITATION
=========================================================

THIS WORKS:

uint256[] memory arr = new uint256[](3);

---------------------------------------------------------

THIS FAILS:

arr.push(10);

Reason:
Memory arrays have fixed size.

=========================================================
MEMORY VS STORAGE ARRAY
=========================================================

---------------------------------------------------------
MEMORY ARRAY
---------------------------------------------------------

Temporary

Destroyed after execution

Cheaper

---------------------------------------------------------
STORAGE ARRAY
---------------------------------------------------------

Persistent

Stored on blockchain

Expensive

=========================================================
GAS OBSERVATION
=========================================================

MEMORY:
Cheaper than storage

---------------------------------------------------------

LARGE MEMORY ARRAYS:
Still increase gas consumption

---------------------------------------------------------

STORAGE WRITES:
Most expensive operations

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY DOS RISK
---------------------------------------------------------

Huge memory allocations may:
- consume excessive gas
- exceed block gas limits

---------------------------------------------------------
2. LOOP SCALABILITY
---------------------------------------------------------

Large memory arrays inside loops
can become dangerous.

---------------------------------------------------------
3. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Developers may incorrectly assume:
memory persists permanently.

---------------------------------------------------------
4. UNBOUNDED INPUTS
---------------------------------------------------------

Attacker-controlled array sizes
can create denial-of-service vectors.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker supplies huge input size.

Contract allocates massive memory array.

Result:
- excessive gas usage
- transaction failure
- DOS condition

---------------------------------------------------------

REAL-WORLD RISK

Improper array processing has caused:
- gas exhaustion
- uncallable functions
- scalability failures

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create memory array of size 5
2. Fill array using loop
3. Return all multiplied values

BONUS:
Compare gas between:
memory arrays vs storage arrays

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory arrays are temporary
- Memory cleared after execution
- Memory arrays require fixed size
- Memory arrays cannot use push()
- Storage arrays persist permanently
- Memory cheaper than storage
- Large memory arrays increase gas
- Dynamic data often returned from memory
- Unbounded memory allocation can be dangerous
- Auditors inspect memory scalability carefully

=========================================================
*/

/*
AUDIT REPORT
Title: Hardcoded Memory Array Size Without Input Validation or Flexibility

Severity: Low

Reason: Function uses a fixed-size memory array without any input control or validation, limiting flexibility and scalability.

Location:

Contract: MemoryArray
Function: createMemoryArray()

Vulnerability Description:

The function createMemoryArray() creates a memory array of fixed size (5) and populates it using a loop.

While the implementation is functionally correct, it does not allow dynamic sizing or input-driven behavior, which reduces flexibility and can become inefficient or restrictive in real-world use cases.

Additionally, if extended in future versions, this pattern may introduce gas inefficiency or unbounded memory risks if size becomes user-controlled.

Impact:
        No direct security vulnerability in current implementation
        Limited flexibility due to hardcoded array size
        Poor scalability if logic is extended to dynamic inputs
        Potential gas inefficiency in larger iterations (future risk scenario)
Proof of Concept:
        1.Deploy contract
            Call:
        2.createMemoryArray()
            Returned output:
            [0, 1, 4, 9, 16]
        3.Observation:
            Array size is fixed at 5
            Values are generated using loop
            No input parameter controls array size
Root Cause:
    Hardcoded array length (5)
    No external input parameter for size control
    No validation or scaling logic implemented
Recommendation:
    Allow dynamic array size with proper validation.

Example:
    require(_size > 0 && _size <= 100, "Invalid size");
    uint256[] memory tempArray = new uint256[](_size);
*/

//patched code 
contract MemoryArray {
    function createMemoryArray()public pure returns (uint256[] memory)
    {
    
        uint256[] memory tempArray = new uint256[](5);
        /*
            Store values inside memory array
        */
       for (uint i = 0; i < tempArray.length; i++) {
           tempArray[i] = i*i;
       }
        /*
            Return temporary memory array
        */
        return tempArray;
    }
}