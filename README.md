# Bank Contract

A Solidity smart contract for a simple bank that accepts ETH deposits and tracks the **top 3 depositors** on a leaderboard.

## Features

- **Deposit** – Send ETH directly to the contract address (via `receive()`) or call `deposit()`.
- **Balance tracking** – Each address's deposited amount is recorded in a `mapping(address => uint256)`.
- **Admin withdrawal** – Only the contract deployer (admin) can call `withdraw(amount)` to transfer ETH out.
- **Top 3 leaderboard** – The contract maintains a sorted array of the top 3 depositors, updated after every deposit.

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Setup

```bash
forge install
forge build
```

### Run tests

```bash
forge test
```

Example output:

```
Running 9 tests for test/Bank.t.sol:BankTest
[PASS] test_ContractBalance() (gas: ...)
[PASS] test_Deposit() (gas: ...)
[PASS] test_DepositViaReceive() (gas: ...)
[PASS] test_DepositZeroAmount() (gas: ...)
[PASS] test_TopDepositors_OnlyThree() (gas: ...)
[PASS] test_TopDepositors_Ordered() (gas: ...)
[PASS] test_TopDepositors_ReorderOnAdditionalDeposit() (gas: ...)
[PASS] test_TopDepositors_Single() (gas: ...)
[PASS] test_Withdraw() (gas: ...)
[PASS] test_Withdraw_InsufficientBalance() (gas: ...)
[PASS] test_Withdraw_OnlyAdmin() (gas: ...)
[PASS] test_Withdraw_ZeroAmount() (gas: ...)
Test result: ok. 12 passed; 0 failed; finished in ...
```

## Usage

### 1. Deposit ETH

```solidity
// Via deposit()
bank.deposit{value: 10 ether}();

// Or send directly to the contract address
payable(address(bank)).transfer(10 ether);
```

### 2. Check balances

```solidity
uint256 myBalance = bank.balances(address(this));
uint256 total     = bank.getContractBalance();
```

### 3. View top 3 depositors

```solidity
address[3] memory top = bank.getTopDepositors();
// top[0] = highest depositor, top[1] = second, top[2] = third
```

### 4. Admin withdraw

```solidity
bank.withdraw(5 ether);  // only the contract deployer can call this
```

## Contract Overview

| Function            | Visibility | Description                                |
|---------------------|------------|--------------------------------------------|
| `deposit()`         | `external payable` | Deposit ETH into the bank          |
| `withdraw(amount)`  | `external`  | Admin-only: withdraw ETH from the contract |
| `balances(address)` | `public`    | View an address's deposited amount         |
| `topDepositors(uint256)` | `public` | View depositor at leaderboard position |
| `getTopDepositors()` | `external view` | Get the full top-3 array            |
| `getContractBalance()` | `external view` | Get total ETH in the contract     |

## License

MIT
