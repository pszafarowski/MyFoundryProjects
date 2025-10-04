//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../../src/RebaseToken.sol";
import {Vault} from "../../src/Vault.sol";
import {IRebaseToken} from "../../src/interfaces/IRebaseToken.sol";
import {console} from "forge-std/console.sol";

contract RebaseTokenTest is Test {
    RebaseToken public token;
    Vault public vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        token = new RebaseToken();
        vault = new Vault(IRebaseToken(address(token)));
        token.grantMintAndBurnRole(address(vault));
        (bool success,) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    function testDepositLinear(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        uint256 startBalance = token.balanceOf(user);
        assertEq(amount, startBalance);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        uint256 middleBalance = token.balanceOf(user);
        assertGt(middleBalance, startBalance);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        uint256 endBalance = token.balanceOf(user);
        assertGt(endBalance, middleBalance);
        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);

        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertEq(token.balanceOf(user), amount);

        vault.redeem(type(uint256).max);
        assertEq(token.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        time = bound(time, 1000, type(uint256).max);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, depositAmount);
        vault.deposit{value: depositAmount}();
        vm.warp(block.timestamp + time);
        vm.roll(block.number + 1);
        

        vm.stopPrank();
    }
}
