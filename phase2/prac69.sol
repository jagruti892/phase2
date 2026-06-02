// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Compare view vs state-changing gas
CONCEPT: Gas optimization
=========================================================

OBJECTIVE

- Learn why view functions are cheaper
- Compare read-only vs storage-modifying execution
- Understand gas optimization basics
- Think like auditor about efficient design

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

READING storage is cheaper than
MODIFYING storage.

---------------------------------------------------------

View functions:
do NOT change blockchain state.

---------------------------------------------------------

State-changing functions:
modify permanent blockchain storage.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Storage writes are among the MOST
expensive EVM operations.

---------------------------------------------------------

View functions avoid:

- storage writes
- state persistence
- blockchain updates

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Gas optimization affects:

- protocol usability
- transaction cost
- scalability
- user experience

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

View functions used for:

- dashboards
- frontend reads
- balances
- analytics
- protocol stats

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unnecessary storage writes
- expensive logic
- gas-heavy functions
- optimization opportunities

=========================================================
GAS COMPARISON CONTRACT
=========================================================
*/

contract GasComparisonVul {

    /*
        STORAGE VARIABLE
    */
    uint256 public storedNumber;

    /*
        STORAGE ARRAY
    */
    uint256[] public values;

    /*
    =====================================================
    VIEW FUNCTION
    =====================================================

    READS storage only.

    NO state changes.
    */

    function readStoredNumber()
        external
        view
        returns (uint256)
    {

        /*
            Read storage value.
        */
        return storedNumber;
    }

    /*
    =====================================================
    PURE FUNCTION
    =====================================================

    Uses no storage at all.
    */

    function calculateSum(
        uint256 a,
        uint256 b
    )
        external
        pure
        returns (uint256)
    {

        /*
            Pure computation only.
        */
        return a + b;
    }

    /*
    =====================================================
    STATE-CHANGING FUNCTION
    =====================================================

    WRITES to storage.
    */

    function updateStoredNumber(
        uint256 _num
    )
        external
    {

        /*
            EXPENSIVE STORAGE WRITE.
        */
        storedNumber = _num;
    }

    /*
    =====================================================
    STORAGE-HEAVY FUNCTION
    =====================================================

    Multiple storage writes.
    */

    function storeManyValues()
        external
    {

        /*
            Loop with storage writes.
        */
        for (
            uint256 i = 0;
            i < 10;
            i++
        ) {

            /*
                VERY expensive.
            */
            values.push(i);
        }
    }

    /*
    =====================================================
    VIEW ARRAY LENGTH
    =====================================================

    Cheap storage read.
    */

    function getArrayLength()
        external
        view
        returns (uint256)
    {

        return values.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy GasComparison

=========================================================
TRACE:
VIEW FUNCTION
=========================================================

CALL:
readStoredNumber()

=========================================================

STEP 1:
Function executes.

---------------------------------------------------------

Storage value READ only.

---------------------------------------------------------

NO storage modifications.

=========================================================
IMPORTANT
=========================================================

Blockchain state remains unchanged.

---------------------------------------------------------

Gas usage:
VERY LOW

=========================================================
WHY?
=========================================================

Reading storage is much cheaper than writing.

=========================================================
TRACE:
PURE FUNCTION
=========================================================

CALL:
calculateSum(5, 7)

=========================================================

STEP 1:
Computation occurs.

---------------------------------------------------------

5 + 7 = 12

=========================================================
IMPORTANT
=========================================================

NO storage access.

---------------------------------------------------------

NO blockchain modification.

=========================================================
GAS USAGE
=========================================================

EXTREMELY LOW.

=========================================================
TRACE:
STATE-CHANGING FUNCTION
=========================================================

CALL:
updateStoredNumber(100)

=========================================================

STEP 1:
Storage write occurs.

---------------------------------------------------------

storedNumber = 100

=========================================================
IMPORTANT
=========================================================

Permanent blockchain state changes.

=========================================================
GAS USAGE
=========================================================

MUCH HIGHER.

=========================================================
WHY?
=========================================================

Storage writes are expensive.

---------------------------------------------------------

Blockchain state must persist forever.

=========================================================
TRACE:
MULTIPLE STORAGE WRITES
=========================================================

CALL:
storeManyValues()

=========================================================

STEP 1:
Loop begins.

=========================================================
STEP 2
=========================================================

10 storage writes occur:

---------------------------------------------------------

values.push(0)

values.push(1)

...

values.push(9)

=========================================================
IMPORTANT
=========================================================

Gas increases heavily.

---------------------------------------------------------

Every push modifies permanent storage.

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
readStoredNumber()
---------------------------------------------------------

CHEAP

=========================================================

---------------------------------------------------------
calculateSum()
---------------------------------------------------------

VERY CHEAP

=========================================================

---------------------------------------------------------
updateStoredNumber()
---------------------------------------------------------

EXPENSIVE

=========================================================

---------------------------------------------------------
storeManyValues()
---------------------------------------------------------

VERY EXPENSIVE

=========================================================
GAS COMPARISON SUMMARY
=========================================================

---------------------------------------------------------
PURE FUNCTION
---------------------------------------------------------

Lowest gas

---------------------------------------------------------

Reason:
No storage access

=========================================================

---------------------------------------------------------
VIEW FUNCTION
---------------------------------------------------------

Low gas

---------------------------------------------------------

Reason:
Storage reads only

=========================================================

---------------------------------------------------------
STATE-CHANGING FUNCTION
---------------------------------------------------------

Higher gas

---------------------------------------------------------

Reason:
Storage writes

=========================================================

---------------------------------------------------------
MULTIPLE STORAGE WRITES
---------------------------------------------------------

Very high gas

---------------------------------------------------------

Reason:
Repeated permanent storage updates

=========================================================
VERY IMPORTANT UNDERSTANDING
=========================================================

Gas mainly increases because of:

---------------------------------------------------------
STORAGE WRITES
---------------------------------------------------------

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
readStoredNumber()

---------------------------------------------------------

Observe:
very low gas

=========================================================
TEST 2
=========================================================

Call:
calculateSum(5,7)

---------------------------------------------------------

Observe:
extremely low gas

=========================================================
TEST 3
=========================================================

Call:
updateStoredNumber(100)

---------------------------------------------------------

Observe:
higher gas

=========================================================
TEST 4
=========================================================

Call:
storeManyValues()

---------------------------------------------------------

Observe:
much higher gas

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Gas optimization improves:

---------------------------------------------------------
SCALABILITY
---------------------------------------------------------

and

---------------------------------------------------------
USABILITY
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNNECESSARY STORAGE WRITES
---------------------------------------------------------

Wastes gas.

---------------------------------------------------------
2. STORAGE INSIDE LOOPS
---------------------------------------------------------

Massive gas growth.

---------------------------------------------------------
3. EXPENSIVE EXECUTION PATHS
---------------------------------------------------------

Protocol becomes costly.

---------------------------------------------------------
4. GAS DOS
---------------------------------------------------------

Functions exceed gas limits.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may exploit:

- expensive functions
- gas-heavy loops
- storage growth
- DOS conditions

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Are storage writes necessary?
- Can logic use memory instead?
- Are loops optimized?
- Can gas usage scale dangerously?
- Is state modification minimized?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors profile:

---------------------------------------------------------
GAS COMPLEXITY
---------------------------------------------------------

AND

---------------------------------------------------------
STORAGE EFFICIENCY
---------------------------------------------------------

=========================================================
BEST PRACTICES
=========================================================

- Use view/pure when possible
- Minimize storage writes
- Avoid unnecessary loops
- Use memory for temporary data
- Batch expensive operations carefully

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add 1000 storage writes
2. Compare memory vs storage
3. Optimize loop gas
4. Add mapping writes

BONUS:
Measure gas differences in Remix.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- View functions are cheaper
- Pure functions are cheapest
- Storage writes cost high gas
- Reading storage is cheaper than writing
- Loops increase gas usage
- Storage-heavy logic is expensive
- Gas optimization improves scalability
- Auditors inspect storage efficiency
- Memory is cheaper than storage
- Efficient Solidity design matters heavily

=========================================================
*/
/*
AUDIT REPORT

Title: Unbounded Storage Growth in storeManyValues()

Severity: Medium

Reason: Repeated calls continuously increase storage
usage, causing increasing gas costs and scalability
issues.

Location:

Contract: GasComparisonVul
Function: storeManyValues()


VULNERABILITY DESCRIPTION

The function storeManyValues() appends new values
to the storage array every time it is executed.

Affected code:

for(uint256 i = 0; i < 10; i++) {
    values.push(i);
}

The array is never cleared and there is no maximum
size restriction.

As a result, storage grows permanently with every
execution.

IMPACT

Users can repeatedly call:
storeManyValues()

which causes:

- Continuous storage growth
- Increasing gas consumption
- Higher transaction costs
- Long-term scalability issues

Over time the function becomes more expensive to
execute.

PROOF OF CONCEPT

        1. Deploy the contract.
        2. Call:
        storeManyValues()
        Result:
        values.length = 10

        3. Call again:
        storeManyValues()
        Result:
        values.length = 20

        4. Call again:
        storeManyValues()
        Result:
        values.length = 30

        Storage continues growing indefinitely.

ROOT CAUSE

The function performs permanent storage writes:
values.push(i);
inside a loop.
No cleanup mechanism exists.
No maximum storage limit exists.

RECOMMENDATION

Restrict array growth.

Possible solutions:

- Set maximum array size
- Implement cleanup functionality
- Use memory arrays when persistence
  is not required
- Limit repeated writes
*/

//patched code
contract GasComparison {

    /*
        STORAGE VARIABLE
    */
    uint256 public storedNumber;

    /*
        STORAGE ARRAY
    */
    uint256[] public values;

    /*
    =====================================================
    VIEW FUNCTION
    =====================================================

    READS storage only.

    NO state changes.
    */

    function readStoredNumber() external view returns (uint256){

        /*
            Read storage value.
        */
        return storedNumber;
    }

    /*
    =====================================================
    PURE FUNCTION
    =====================================================

    Uses no storage at all.
    */

    function calculateSum(uint256 a, uint256 b) external pure returns (uint256){
        /*
            Pure computation only.
        */
        return a + b;
    }

    /*
    =====================================================
    STATE-CHANGING FUNCTION
    =====================================================

    WRITES to storage.
    */

    function updateStoredNumber( uint256 _num )external {

        /*
            EXPENSIVE STORAGE WRITE.
        */
        storedNumber = _num;
    }

    /*
    =====================================================
    STORAGE-HEAVY FUNCTION
    =====================================================

    Multiple storage writes.
    */

    function storeManyValues()  external  {

        /*
            Loop with storage writes.
        */
        for (uint256 i = 0; i < 10;  i++ ) {
            /*
                VERY expensive.
            */
            values.push(i);
        }
    }

    

    /*
    =====================================================
    VIEW ARRAY LENGTH
    =====================================================

    Cheap storage read.
    */

    function getArrayLength() external view returns (uint256) {
        return values.length;
    }
// Add 1000 Storage Writes
    function store1000Values() external {
    for(uint256 i = 0; i < 1000; i++) {
        values.push(i);
        }
    }//Out of Gas

// memory store
    function storeMemory()external pure returns (uint256[] memory){
        uint256[] memory temp=new uint256[](1000);
            for(uint256 i = 0; i < 1000; i++) {
        temp[i] = i;
         }
        return temp;
    }//execution cost 399,715 gas

// Optimize loop gas
    function optimizedLoop() external{
    uint256 sum;

    for(uint256 i = 0; i < 1000; i++) {
        sum += i;
        }
     storedNumber = sum;
    }  //Execution cost: 271,320 gas

//  mapping writes
    mapping(uint256 => uint256) public data;

    function writeMapping() external{
        for(uint256 i=0; i<100; i++) {
            data[i] = i;
        }
    }//	2204970 gas high
}

