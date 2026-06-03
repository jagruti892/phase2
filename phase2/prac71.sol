// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trigger out-of-gas scenario
CONCEPT: Execution failure
=========================================================

OBJECTIVE

- Understand what "out of gas" means
- See how loops can cause execution failure
- Learn why gas limits exist
- Think like an auditor about DOS risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every Ethereum transaction has a GAS LIMIT.

---------------------------------------------------------

If execution consumes more gas than available:

→ transaction REVERTS automatically

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Out-of-gas (OOG) is NOT a normal revert.

It is a HARD EXECUTION FAILURE.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Out-of-gas scenarios cause:

- failed transactions
- stuck operations
- denial of service (DOS)
- unusable functions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

OOG risks appear in:

- loops over arrays
- batch processing
- staking reward distribution
- token airdrops
- NFT mint batches

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- loop bounds
- gas estimation
- worst-case inputs
- storage-heavy iterations
- external call loops

=========================================================
OUT-OF-GAS CONTRACT
=========================================================
*/

contract OutOfGasDemoVul {
    /*
        STORAGE ARRAY
    */
    uint256[] public data;

    /*
    =====================================================
    INFINITE LOOP RISK FUNCTION
    =====================================================
    */

    function dangerousLoop() external  {
        /*
        =================================================
        WARNING PATTERN
        =================================================
        This function loops over ALL stored data.

        If array becomes large:
        GAS LIMIT WILL BE EXCEEDED.
        */
        uint256 sum = 0;

        for ( uint256 i = 0; i < data.length;i++) {
            /*
                Storage read (expensive).
            */
            sum += data[i];
            /*
                Additional storage write (very expensive).
            */
            data[i] = sum;
        }
    }
    /*
    =====================================================
    ADD MANY VALUES
    =====================================================
    */

    function addMany(uint256 n)external {
        for ( uint256 i = 0; i < n; i++) {
            data.push(i);
        }
    }

    /*
    =====================================================
    SAFE BATCH VERSION
    =====================================================
    */

    function safeProcess(uint256 limit) view  external{
        /*
            Limit loop size to avoid OOG.
        */
        require(limit <= 100, "Too large batch");
        uint256 sum = 0;
        for ( uint256 i = 0;i < limit;i++) {
            sum += data[i];
        }
    }

    /*
    =====================================================
    GET LENGTH
    =====================================================
    */

    function getLength() external  view returns (uint256) {
        return data.length;
    }
}

/*
=========================================================
EXECUTION FLOW (OUT-OF-GAS SCENARIO)
=========================================================

STEP 1:
Deploy OutOfGasDemo

=========================================================
STEP 2:
CALL:
addMany(10000)

=========================================================

Array grows to:
10000 elements

=========================================================
STEP 3:
CALL:
dangerousLoop()

=========================================================

STEP-BY-STEP EXECUTION
=========================================================

STEP 1:
sum = 0

---------------------------------------------------------

STEP 2:
i = 0 → read data[0]

---------------------------------------------------------

STEP 3:
data[0] updated

---------------------------------------------------------

STEP 4:
i = 1 → read data[1]

---------------------------------------------------------

(repeats thousands of times)

=========================================================
GAS CONSUMPTION GROWS
=========================================================

Each iteration costs:

- storage read
- storage write
- loop increment
- memory operations

=========================================================
CRITICAL MOMENT
=========================================================

At some iteration:

gas remaining < required gas

=========================================================
RESULT
=========================================================

TRANSACTION FAILS:

OUT OF GAS (OOG)

=========================================================
IMPORTANT BEHAVIOR
=========================================================

When OOG happens:

- entire transaction REVERTS
- ALL state changes rollback
- no partial execution persists

=========================================================
FINAL RESULT
=========================================================

data remains unchanged after failure

=========================================================
WHY THIS HAPPENS
=========================================================

Ethereum enforces gas limit per block:

→ prevents infinite computation
→ protects network from abuse

=========================================================
SAFE VERSION TRACE
=========================================================

CALL:
safeProcess(100)

=========================================================

STEP 1:
limit checked

---------------------------------------------------------

limit <= 100

=========================================================
STEP 2:
loop executes safely

---------------------------------------------------------

only 100 iterations

=========================================================
STEP 3:
execution completes successfully

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Out-of-gas is a:

---------------------------------------------------------
HARD EXECUTION FAILURE
---------------------------------------------------------

not a normal revert.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED LOOPS
---------------------------------------------------------

can exceed gas limit

---------------------------------------------------------
2. STORAGE INSIDE LOOP
---------------------------------------------------------

accelerates gas exhaustion

---------------------------------------------------------
3. USER-CONTROLLED INPUT SIZE
---------------------------------------------------------

attackers can force OOG

---------------------------------------------------------
4. DOS VIA GAS LIMIT
---------------------------------------------------------

contract becomes unusable

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- increase array size
- trigger expensive loops
- force OOG condition
- block contract execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can loop exceed gas limit?
- Is input size bounded?
- Are storage writes inside loops?
- What is worst-case gas cost?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors calculate:

---------------------------------------------------------
GAS PER ITERATION × MAX SIZE
---------------------------------------------------------

to ensure safety.

=========================================================
BEST PRACTICES
=========================================================

- Always bound loops
- Avoid storage writes in loops
- Use batching techniques
- Validate input size
- Design O(1) or O(log n) logic

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Allow dynamic batch processing
2. Prevent OOG using chunking
3. Compare safe vs unsafe loops
4. Add gas estimator function

BONUS:
Create pagination-based processing system.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Out-of-gas causes transaction failure
- Gas limits protect Ethereum network
- Large loops are dangerous
- Storage operations are expensive
- OOG reverts entire transaction
- Input size must be controlled
- Gas estimation is critical
- Auditors analyze worst-case execution
- Batching avoids gas exhaustion
- Safe design prevents DOS attacks

=========================================================
*/

/*
Audit Report

Title: Unbounded Loop Leading to Out-of-Gas Denial of Service

Severity: High

Reason:
The dangerousLoop() function processes the entire data array without any upper limit. As the array grows, gas consumption increases linearly and can eventually exceed the block gas limit, causing permanent transaction failures.

Location:

Contract: OutOfGasDemoVul
Function: dangerousLoop()

Vulnerability Description:

The dangerousLoop() function iterates through every element of the data array and performs both a storage read 
and a storage write during each iteration.

for (uint256 i = 0; i < data.length; i++) {
    sum += data[i];
    data[i] = sum;
}

Since the array size is controlled through addMany(), an attacker or normal user can continuously increase 
the array length.

As the array becomes large, dangerousLoop() will consume excessive gas and eventually become impossible
to execute.

Impact:

Function may become permanently unusable.
Transactions can repeatedly fail with Out-of-Gas errors.
Creates a Denial of Service (DoS) condition.
Legitimate users cannot complete processing once the array grows beyond a certain size.
Contract functionality becomes dependent on gas limits rather than business logic.

Proof of Concept:
    1.Deploy the contract.
    2.Populate the array:
        addMany(10000);
    3.Call:
        dangerousLoop();
    4.Expected result:
        Out of Gas
    Transaction Reverted

The function attempts to process all 10,000 elements and exceeds the available gas limit.

Root Cause:
The function processes the entire dynamic array without any limit.
for (uint256 i = 0; i < data.length; i++)
Additionally, expensive storage writes occur inside the loop:
data[i] = sum;

The combination of:
Unbounded iteration
Storage reads
Storage writes

causes gas usage to grow linearly with array size.

Recommendation:
Implement batch processing (chunking) so that only a limited number of elements are processed per transaction.

Example:

function safeProcessBatch(
    uint256 start,
    uint256 batchSize
) external {

    uint256 end = start + batchSize;

    if (end > data.length) {
        end = data.length;
    }

    uint256 sum = 0;

    for (uint256 i = start; i < end; i++) {
        sum += data[i];
        data[i] = sum;
    }
}

Additionally:

Limit maximum batch size.
Avoid unnecessary storage writes.
Estimate worst-case gas consumption during development.
*/

//patched code 
contract OutOfGasDemo {
    /*
        STORAGE ARRAY
    */
    uint256[] public data;

    /*
    =====================================================
    INFINITE LOOP RISK FUNCTION
    =====================================================
    */

    function dangerousLoop() external  {
        /*
        =================================================
        WARNING PATTERN
        =================================================
        This function loops over ALL stored data.

        If array becomes large:
        GAS LIMIT WILL BE EXCEEDED.
        */
        uint256 sum = 0;

        for ( uint256 i = 0; i < data.length;i++) {
            /*
                Storage read (expensive).
            */
            sum += data[i];
            /*
                Additional storage write (very expensive).
            */
            data[i] = sum;
        }
    }
    /*
    =====================================================
    ADD MANY VALUES
    =====================================================
    */

    function addMany(uint256 n)external {
        for ( uint256 i = 0; i < n; i++) {
            data.push(i);
        }
    }

    /*
    =====================================================
    SAFE BATCH VERSION
    =====================================================
    */

    function safeProcess(uint256 limit) view  external{
        /*
            Limit loop size to avoid OOG.
        */
        require(limit <= 100, "Too large batch");
        uint256 sum = 0;
        for ( uint256 i = 0;i < limit;i++) {
            sum += data[i];
        }
    }
    /*
    =====================================================
    GET LENGTH
    =====================================================
    */
    function getLength() external  view returns (uint256) {
        return data.length;
    }

//Allow dynamic batch processing
    uint256 public currentIndex;
    uint256 public processedSum;

//Process data in small chunks
function processBatch(uint256 batchSize) external {
    uint256 end = currentIndex + batchSize;

    if(end > data.length){
        end = data.length;
    }

    uint256 sum = processedSum;

    for(uint256 i = currentIndex; i < end; i++){
        sum += data[i];
    }
    processedSum = sum;
    currentIndex = end;
}


    // Add gas estimator function(returns remaining items to be proccessed 
    function estimateRemainingWork() external view returns(uint256){
    return data.length - currentIndex;
    }

    // pagination :Read data in small chunks.
    function pagination(uint256 start,uint256 count)external view returns (uint256[] memory){
        uint256 [] memory page=new uint256[](count);
        for(uint256 i=0;i<count;i++){
            page[i]=data[start+i];
        }
        return page;
    }
}
