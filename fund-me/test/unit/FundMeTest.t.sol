//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    DeployFundMe deployer;
    FundMe fundMe;

    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 1e18;
    uint256 constant STARTING_BALANCE = 10e18;
    uint256 constant GAS_COST = 1;

    function setUp() external {
        deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() external view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() external view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testAggregatorVersion() external view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() external {
        vm.expectRevert();
        fundMe.fund{value: 0}();
    }

    function testFundUpdatesFundedDataStructures() external {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFounded = fundMe.getAddressToAmountFounded(USER);
        assertEq(amountFounded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() external {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assertEq(fundMe.getFunder(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() external funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFudner() external funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalnce = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalnce = address(fundMe).balance;
        assertEq(endingFundMeBalnce, 0);
        assertEq(startingOwnerBalance + startingFundMeBalnce, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() external funded {
        //Arrange
        uint160 numOfFunders = 10;
        uint160 funderIndex = 1;
        for (uint160 index = funderIndex; index < numOfFunders; index++) {
            hoax(address(index), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalnce = address(fundMe).balance;
        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_COST);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        //gasUsed
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalnce, endingOwnerBalance);
    }
}
