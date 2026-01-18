// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MockERC6909} from "../../src/token/ERC6909/MockERC6909.sol";
import {IERC6909} from "openzeppelin-contracts/contracts/interfaces/IERC6909.sol";

contract ERC6909Test is Test {
    MockERC6909 internal testing;

    address internal alice;
    address internal bob;
    address internal charlie;

    uint256 internal constant TOKEN_ID_1 = 1;
    uint256 internal constant TOKEN_ID_2 = 2;
    uint256 internal constant INITIAL_BALANCE = 1000 ether;

    // Events from IERC6909
    event Transfer(address caller, address indexed sender, address indexed receiver, uint256 indexed id, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    // Errors from ERC6909
    error ERC6909InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 id);
    error ERC6909InsufficientAllowance(address spender, uint256 allowance, uint256 needed, uint256 id);
    error ERC6909InvalidApprover(address approver);
    error ERC6909InvalidReceiver(address receiver);
    error ERC6909InvalidSender(address sender);
    error ERC6909InvalidSpender(address spender);

    function setUp() public {
        testing = new MockERC6909();

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Pre-mint tokens to alice for testing
        testing.mint(alice, TOKEN_ID_1, INITIAL_BALANCE);
        testing.mint(alice, TOKEN_ID_2, INITIAL_BALANCE);
    }

    // ============ Positive Test Cases ============

    function test_supportsInterface() public view {
        // ERC6909 interface
        assertTrue(testing.supportsInterface(type(IERC6909).interfaceId));
        // ERC165 interface
        assertTrue(testing.supportsInterface(0x01ffc9a7));
        // Invalid interface
        assertFalse(testing.supportsInterface(0xffffffff));
    }

    function test_balanceOf() public view {
        assertEq(testing.balanceOf(alice, TOKEN_ID_1), INITIAL_BALANCE);
        assertEq(testing.balanceOf(alice, TOKEN_ID_2), INITIAL_BALANCE);
        assertEq(testing.balanceOf(bob, TOKEN_ID_1), 0);
    }

    function test_allowance() public {
        assertEq(testing.allowance(alice, bob, TOKEN_ID_1), 0);

        vm.prank(alice);
        testing.approve(bob, TOKEN_ID_1, 100 ether);

        assertEq(testing.allowance(alice, bob, TOKEN_ID_1), 100 ether);
    }

    function test_isOperator() public {
        assertFalse(testing.isOperator(alice, bob));

        vm.prank(alice);
        testing.setOperator(bob, true);

        assertTrue(testing.isOperator(alice, bob));
    }

    function test_mint() public {
        uint256 mintAmount = 500 ether;

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0), bob, TOKEN_ID_1, mintAmount);

        testing.mint(bob, TOKEN_ID_1, mintAmount);

        assertEq(testing.balanceOf(bob, TOKEN_ID_1), mintAmount);
    }

    function test_burn() public {
        uint256 burnAmount = 100 ether;
        uint256 expectedBalance = INITIAL_BALANCE - burnAmount;

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), alice, address(0), TOKEN_ID_1, burnAmount);

        testing.burn(alice, TOKEN_ID_1, burnAmount);

        assertEq(testing.balanceOf(alice, TOKEN_ID_1), expectedBalance);
    }

    function test_approve() public {
        uint256 approveAmount = 200 ether;

        vm.expectEmit(true, true, true, true);
        emit Approval(alice, bob, TOKEN_ID_1, approveAmount);

        vm.prank(alice);
        bool success = testing.approve(bob, TOKEN_ID_1, approveAmount);

        assertTrue(success);
        assertEq(testing.allowance(alice, bob, TOKEN_ID_1), approveAmount);
    }

    function test_setOperator() public {
        vm.expectEmit(true, true, true, true);
        emit OperatorSet(alice, bob, true);

        vm.prank(alice);
        bool success = testing.setOperator(bob, true);

        assertTrue(success);
        assertTrue(testing.isOperator(alice, bob));

        vm.expectEmit(true, true, true, true);
        emit OperatorSet(alice, bob, false);

        vm.prank(alice);
        success = testing.setOperator(bob, false);

        assertTrue(success);
        assertFalse(testing.isOperator(alice, bob));
    }

    function test_transfer() public {
        uint256 transferAmount = 100 ether;

        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, alice, bob, TOKEN_ID_1, transferAmount);

        vm.prank(alice);
        bool success = testing.transfer(bob, TOKEN_ID_1, transferAmount);

        assertTrue(success);
        assertEq(testing.balanceOf(alice, TOKEN_ID_1), INITIAL_BALANCE - transferAmount);
        assertEq(testing.balanceOf(bob, TOKEN_ID_1), transferAmount);
    }

    function test_transferFrom() public {
        uint256 transferAmount = 100 ether;

        // Approve bob to spend alice's tokens
        vm.prank(alice);
        testing.approve(bob, TOKEN_ID_1, transferAmount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(bob, alice, charlie, TOKEN_ID_1, transferAmount);

        vm.prank(bob);
        bool success = testing.transferFrom(alice, charlie, TOKEN_ID_1, transferAmount);

        assertTrue(success);
        assertEq(testing.balanceOf(alice, TOKEN_ID_1), INITIAL_BALANCE - transferAmount);
        assertEq(testing.balanceOf(charlie, TOKEN_ID_1), transferAmount);
        assertEq(testing.allowance(alice, bob, TOKEN_ID_1), 0);
    }

    // ============ Negative Test Cases (Revert) ============

    function test_revert_mint() public {
        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidReceiver.selector, address(0)));
        testing.mint(address(0), TOKEN_ID_1, 100 ether);
    }

    function test_revert_burn() public {
        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidSender.selector, address(0)));
        testing.burn(address(0), TOKEN_ID_1, 100 ether);

        vm.expectRevert(
            abi.encodeWithSelector(ERC6909InsufficientBalance.selector, alice, INITIAL_BALANCE, INITIAL_BALANCE + 1, TOKEN_ID_1)
        );
        testing.burn(alice, TOKEN_ID_1, INITIAL_BALANCE + 1);
    }

    function test_revert_approve() public {
        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidApprover.selector, address(0)));
        vm.prank(address(0));
        testing.approve(bob, TOKEN_ID_1, 100 ether);

        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidSpender.selector, address(0)));
        vm.prank(alice);
        testing.approve(address(0), TOKEN_ID_1, 100 ether);
    }

    function test_revert_setOperator() public {
        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidApprover.selector, address(0)));
        vm.prank(address(0));
        testing.setOperator(bob, true);

        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidSpender.selector, address(0)));
        vm.prank(alice);
        testing.setOperator(address(0), true);
    }

    function test_revert_transfer() public {
        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidSender.selector, address(0)));
        vm.prank(address(0));
        testing.transfer(bob, TOKEN_ID_1, 100 ether);

        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidReceiver.selector, address(0)));
        vm.prank(alice);
        testing.transfer(address(0), TOKEN_ID_1, 100 ether);

        vm.expectRevert(
            abi.encodeWithSelector(ERC6909InsufficientBalance.selector, alice, INITIAL_BALANCE, INITIAL_BALANCE + 1, TOKEN_ID_1)
        );
        vm.prank(alice);
        testing.transfer(bob, TOKEN_ID_1, INITIAL_BALANCE + 1);
    }

    function test_revert_transferFrom() public {
        // When sender is address(0) and caller is not sender/operator, allowance check happens first
        vm.expectRevert(abi.encodeWithSelector(ERC6909InsufficientAllowance.selector, bob, 0, 100 ether, TOKEN_ID_1));
        vm.prank(bob);
        testing.transferFrom(address(0), charlie, TOKEN_ID_1, 100 ether);

        // When caller is sender, no allowance check, so InvalidReceiver is caught
        vm.expectRevert(abi.encodeWithSelector(ERC6909InvalidReceiver.selector, address(0)));
        vm.prank(alice);
        testing.transferFrom(alice, address(0), TOKEN_ID_1, 100 ether);

        // Insufficient balance when caller is sender
        vm.expectRevert(
            abi.encodeWithSelector(ERC6909InsufficientBalance.selector, alice, INITIAL_BALANCE, INITIAL_BALANCE + 1, TOKEN_ID_1)
        );
        vm.prank(alice);
        testing.transferFrom(alice, bob, TOKEN_ID_1, INITIAL_BALANCE + 1);

        // Insufficient allowance when caller is not sender/operator
        vm.expectRevert(abi.encodeWithSelector(ERC6909InsufficientAllowance.selector, bob, 0, 100 ether, TOKEN_ID_1));
        vm.prank(bob);
        testing.transferFrom(alice, charlie, TOKEN_ID_1, 100 ether);

        // Insufficient allowance with partial approval
        vm.prank(alice);
        testing.approve(bob, TOKEN_ID_1, 50 ether);

        vm.expectRevert(abi.encodeWithSelector(ERC6909InsufficientAllowance.selector, bob, 50 ether, 100 ether, TOKEN_ID_1));
        vm.prank(bob);
        testing.transferFrom(alice, charlie, TOKEN_ID_1, 100 ether);
    }
}
