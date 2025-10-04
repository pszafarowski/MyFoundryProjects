pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe} from "../../script/Interactions.s.sol";

contract FundMeTestIntegration is Test {
    DeployFundMe deployer;
    FundMe fundMe;

    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 1e18;
    uint256 constant STARTING_BALANCE = 10e18;
    uint256 constant GAS_COST = 1;

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundIntegration() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.prank(USER);
        fundFundMe.fundFundMe(address(fundMe));

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
}
