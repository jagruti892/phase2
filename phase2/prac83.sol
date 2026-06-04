// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Simple Proxy Contract
CONCEPT: Upgradeable architecture (basic delegatecall proxy)
=========================================================

OBJECTIVE

- Understand proxy + implementation pattern
- Learn how upgrades work using delegatecall
- Separate logic (implementation) from storage (proxy)
- Build minimal upgradeable architecture

=========================================================
CORE IDEA
=========================================================

Proxy holds:
- storage
- implementation address

Logic contract holds:
- functions (code only)

Proxy executes logic via delegatecall.

=========================================================
IMPORTANT RULE

delegatecall = logic runs, but storage belongs to proxy

=========================================================
IMPLEMENTATION CONTRACT (LOGIC V1)
=========================================================
*/

contract LogicV1Vul {

    /*
        NOTE:
        These variables are stored in PROXY storage
    */

    uint256 public value;
    address public owner;

    function initialize(address _owner) external {
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
}

/*
=========================================================
IMPLEMENTATION CONTRACT (LOGIC V2 - UPGRADE)
=========================================================
*/

contract LogicV2Vul {

    /*
        MUST match storage layout of V1
    */

    uint256 public value;
    address public owner;

    function setValue(uint256 _value) external {
        value = _value * 2; // upgraded logic
    }

    function setValueIncrement(uint256 _value) external {
        value = value + _value;
    }
}

/*
=========================================================
PROXY CONTRACT (STORAGE OWNER)
=========================================================
*/

contract SimpleProxyVul {

    /*
        STORAGE LAYOUT
    */

    address public implementation;
    address public admin;

    /*
    =====================================================
    CONSTRUCTOR
    =====================================================
    */

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    /*
    =====================================================
    UPGRADE FUNCTION
    =====================================================
    */

    function upgrade(address _newImplementation) external {
        require(msg.sender == admin, "Not admin");
        implementation = _newImplementation;
    }

    /*
    =====================================================
    DELEGATECALL FALLBACK EXECUTION
    =====================================================
    */

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    /*
    =====================================================
    INTERNAL DELEGATECALL
    =====================================================
    */

    function _delegate() internal {

        address impl = implementation;

        assembly {
            /*
                Copy calldata
            */
            calldatacopy(0, 0, calldatasize()) //Copies the user's function call into memory

            /*
                delegatecall:
                gas, implementation, input, output
            */
            let result := delegatecall(
                   gas(),         // use remaining gas
                    impl,          // logic contract address
                    0,             // input starts at memory position 0
                    calldatasize(),// input size
                    0,             // output position
                    0              // output size

            )

            /*
                Copy return data
            */
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1: DEPLOY

1. Deploy LogicV1
2. Deploy SimpleProxy with LogicV1 address

=========================================================
STEP 2: INITIALIZE VIA PROXY

CALL:
proxy.call("initialize(address)", owner)

=========================================================

delegatecall happens:
- LogicV1 runs
- Proxy storage updated

Proxy storage becomes:
owner = set owner

=========================================================
STEP 3: SET VALUE (V1 LOGIC)

CALL:
proxy.call("setValue(uint256)", 10)

RESULT:
value = 10 (stored in proxy)

=========================================================
STEP 4: UPGRADE LOGIC

CALL:
upgrade(LogicV2 address)

Only admin can upgrade.

=========================================================
STEP 5: NEW LOGIC EXECUTION

CALL:
proxy.call("setValue(uint256)", 10)

NOW:

LogicV2 runs:
value = 20 (10 * 2)

=========================================================
WHY THIS WORKS

- Storage stays in proxy
- Logic can be swapped anytime
- State remains unchanged across upgrades

=========================================================
IMPORTANT SECURITY INSIGHTS

✔ Proxy holds storage
✔ Logic holds behavior
✔ delegatecall connects both
✔ upgrade changes behavior only

=========================================================
AUDITOR RISKS

- storage collision
- unauthorized upgrade
- broken initialization
- delegatecall injection
- unsafe implementation switching

=========================================================
BEST PRACTICES

- protect upgrade function (onlyOwner / timelock)
- ensure storage layout compatibility
- use audited proxy patterns (UUPS / Transparent)
- never expose implementation directly

=========================================================
KEY TAKEAWAYS

- proxy = storage layer
- implementation = logic layer
- delegatecall = execution bridge
- upgrade = swap logic, not state
- storage safety is critical

=========================================================
*/

/*
Audit Report

Title: Storage Layout Collision Risk in SimpleProxy Upgrade Architecture

Severity: High

Reason:
The proxy contract storage layout does not match the storage layout expected by LogicV1 and LogicV2 during 
delegatecall execution.

Location:

Contract: SimpleProxy
Function: fallback()
Function: receive()
Function: _delegate()

Vulnerability Description:
The proxy executes implementation contract code using delegatecall.

LogicV1 and LogicV2 expect the following storage layout:

Slot 0 -> value
Slot 1 -> owner

However, SimpleProxy uses:

Slot 0 -> implementation
Slot 1 -> admin

Because delegatecall uses the storage of the calling contract, any write to value or owner inside the 
implementation contract will overwrite implementation and admin in the proxy.

This creates a storage collision vulnerability.

Impact:
An attacker or normal user interaction may unintentionally corrupt critical proxy storage.

Possible consequences include:

- implementation address overwrite
- admin address corruption
- loss of upgradeability
- execution of unintended logic
- complete proxy malfunction

Proof of Concept:
        1. Deploy LogicV1.
        2. Deploy SimpleProxy with LogicV1 address.
        3. Call through proxy:
        setValue(100)

        LogicV1 writes:
        value = 100
        Because delegatecall uses proxy storage:
        Slot 0 (implementation) is overwritten.

        4. Call through proxy:
            initialize(attacker)

        LogicV1 writes:
        owner = attacker
        Because delegatecall uses proxy storage:
        Slot 1 (admin) is overwritten.
    Critical proxy variables become corrupted.

Root Cause:
The implementation contracts and proxy contract do not share the same storage layout.
delegatecall executes implementation code while writing directly into proxy storage slots.
Storage slot mismatch causes storage collision.

Recommendation:
Ensure that proxy and implementation contracts use compatible storage layouts.

Store implementation and admin variables in dedicated storage slots that do not conflict with implementation
state variables.
*/
//patched code 
contract SimpleProxy {

    // Match implementation layout first

    uint256 public value;
    address public owner;

    // Additional proxy variables appended after

    address public implementation;
    address public admin;

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function upgrade(address _newImplementation) external {
        require(msg.sender == admin, "Not admin");
        implementation = _newImplementation;
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function _delegate() internal {

        address impl = implementation;

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                impl,
                0,
                calldatasize(),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}


contract LogicV1 {

    /*
        NOTE:
        These variables are stored in PROXY storage
    */

    uint256 public value;
    address public owner;

    function initialize(address _owner) external {
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
}

/*
=========================================================
IMPLEMENTATION CONTRACT (LOGIC V2 - UPGRADE)
=========================================================
*/

contract LogicV2 {

    /*
        MUST match storage layout of V1
    */

    uint256 public value;
    address public owner;

    function setValue(uint256 _value) external {
        value = _value * 2; // upgraded logic
    }

    function setValueIncrement(uint256 _value) external {
        value = value + _value;
    }
}
