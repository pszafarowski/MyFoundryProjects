//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";

contract DSCEngineTest is Test {
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint8 public constant DECIMALS = 8;
    uint256 public constant ETH_USD_PRICE = 2000;
    uint256 public constant BTC_USD_PRICE = 1000;
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_BALANCE = 100 ether;

    address public USER = makeAddr("USER");

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc) = config.activeNetworkConfig();
        //ERC20Mock(weth).mint(USER, STARTING_BALANCE);
    }
    /*//////////////////////////////////////////////////////////////
                               PRICE TEST
    //////////////////////////////////////////////////////////////*/

    function testGetUsdValue() external view {
        //arrange
        uint256 wethAmount = 15 ether;
        (, int256 price,,,) = AggregatorV3Interface(wethUsdPriceFeed).latestRoundData();
        uint256 expectedPrice = (wethAmount * (uint256(price) * 1e10) / 1e18);
        //act/assert
        uint256 actualPrice = engine.getUsdValue(weth, wethAmount);
        assert(expectedPrice == actualPrice);
    }

    /*//////////////////////////////////////////////////////////////
                           DEPOSIT COLLATERAL
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralIsZero() external {
        //arrange
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert();
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
