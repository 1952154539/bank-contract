// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public admin;
    address public alice;
    address public bob;
    address public carol;

    function setUp() public {
        admin = makeAddr("admin");
        alice = makeAddr("alice");
        bob   = makeAddr("bob");
        carol = makeAddr("carol");

        vm.prank(admin);
        bank = new Bank();
    }

    // ── Deposit tests ─────────────────────────────────────────────────────

    function test_Deposit() public {
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        assertEq(bank.balances(alice), 1 ether);
    }

    function test_DepositViaReceive() public {
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        (bool ok,) = address(bank).call{value: 2 ether}("");
        assertTrue(ok);

        assertEq(bank.balances(alice), 2 ether);
    }

    function test_DepositZeroAmount() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert("Bank: amount must be greater than zero");
        bank.deposit{value: 0}();
    }

    // ── Withdraw tests ────────────────────────────────────────────────────

    function test_Withdraw() public {
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        uint256 adminBefore = admin.balance;
        vm.prank(admin);
        bank.withdraw(3 ether);

        assertEq(admin.balance, adminBefore + 3 ether);
        assertEq(address(bank).balance, 2 ether);
    }

    function test_Withdraw_OnlyAdmin() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(alice);
        vm.expectRevert("Bank: caller is not the admin");
        bank.withdraw(1 ether);
    }

    function test_Withdraw_InsufficientBalance() public {
        vm.prank(admin);
        vm.expectRevert("Bank: insufficient contract balance");
        bank.withdraw(1 ether);
    }

    function test_Withdraw_ZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert("Bank: amount must be greater than zero");
        bank.withdraw(0);
    }

    // ── Top 3 leaderboard tests ──────────────────────────────────────────

    function test_TopDepositors_Single() public {
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        bank.deposit{value: 10 ether}();

        (address[3] memory top) = bank.getTopDepositors();
        assertEq(top[0], alice);
        assertEq(top[1], address(0));
        assertEq(top[2], address(0));
    }

    function test_TopDepositors_Ordered() public {
        vm.deal(alice, 3 ether);
        vm.deal(bob,   5 ether);
        vm.deal(carol, 4 ether);

        vm.prank(alice);
        bank.deposit{value: 3 ether}();
        vm.prank(bob);
        bank.deposit{value: 5 ether}();
        vm.prank(carol);
        bank.deposit{value: 4 ether}();

        (address[3] memory top) = bank.getTopDepositors();
        assertEq(top[0], bob,   "first should be bob (5 eth)");
        assertEq(top[1], carol, "second should be carol (4 eth)");
        assertEq(top[2], alice, "third should be alice (3 eth)");
    }

    function test_TopDepositors_ReorderOnAdditionalDeposit() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob,   10 ether);

        // Alice deposits first: leaderboard = [alice]
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        // Bob deposits 2 ether: leaderboard = [bob, alice]
        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        (address[3] memory top) = bank.getTopDepositors();
        assertEq(top[0], bob,   "first should be bob (2 eth)");
        assertEq(top[1], alice, "second should be alice (1 eth)");

        // Alice tops up to 3 ether – she should take first.
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        top = bank.getTopDepositors();
        assertEq(top[0], alice, "first should be alice (3 eth)");
        assertEq(top[1], bob,   "should be bob (2 eth)");
    }

    function test_TopDepositors_OnlyThree() public {
        address dave = makeAddr("dave");

        vm.deal(alice, 10 ether);
        vm.deal(bob,   10 ether);
        vm.deal(carol, 10 ether);
        vm.deal(dave,  10 ether);

        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        vm.prank(bob);
        bank.deposit{value: 4 ether}();
        vm.prank(carol);
        bank.deposit{value: 3 ether}();
        vm.prank(dave);
        bank.deposit{value: 2 ether}();   // dave should NOT appear in top 3

        (address[3] memory top) = bank.getTopDepositors();
        assertEq(top[0], alice, "first alice");
        assertEq(top[1], bob,   "second bob");
        assertEq(top[2], carol, "third carol");
        assertFalse(top[0] == dave || top[1] == dave || top[2] == dave,
                    "dave should not be in top 3");
    }

    function test_ContractBalance() public {
        vm.deal(alice, 5 ether);
        vm.deal(bob,   3 ether);

        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        assertEq(bank.getContractBalance(), 5 ether);

        vm.prank(bob);
        bank.deposit{value: 3 ether}();
        assertEq(bank.getContractBalance(), 8 ether);
    }
}
