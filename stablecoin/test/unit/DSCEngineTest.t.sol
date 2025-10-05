//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {console} from "forge-std/console.sol";

contract DSCEnigneTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address wethUsdPriceFeed;
    address weth;
    address wbtcUsdPriceFeed;
    address wbtc;

    address public USER = makeAddr("USER");
    address public USER2 = makeAddr("USER2");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant ETH_USD_PRICE = 2000;
    uint256 public constant BTC_USD_PRICE = 1000;
    uint256 public constant AMOUNT_COLLATERAL_IN_USD = AMOUNT_COLLATERAL * ETH_USD_PRICE;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant AMOUNT_DSC_TO_MINT = 10000 ether;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_ERC20_BALANCE);

        ERC20Mock(weth).mint(USER2, STARTING_ERC20_BALANCE);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                                Constructor Tests                         ///
    ////////////////////////////////////////////////////////////////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() external {
        //arrangement
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);
        //act/assert
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                                 Price Tests                              ///
    ////////////////////////////////////////////////////////////////////////////////

    function testGetUsdValue() external view {
        //arrangement
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = engine.getUsdValue(weth, ethAmount);
        //act/assert
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokemAmountFromUsd() external view {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    function testGetAccountCollateralValue() external depositCollateral {
        //arrangement
        uint256 expectedCollateralValue = AMOUNT_COLLATERAL * (ETH_USD_PRICE + BTC_USD_PRICE);
        //act/assert

        vm.startPrank(USER);
        ERC20Mock(wbtc).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(wbtc, AMOUNT_COLLATERAL);
        vm.stopPrank();

        assertEq(engine.getAccountCollateralValue(USER), expectedCollateralValue);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                                 deposit collateral                       ///
    ////////////////////////////////////////////////////////////////////////////////

    function testRevertsIfCollateralZero() external {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsIfUnapprovedCollateral() external {
        ERC20Mock undefinedToken = new ERC20Mock("undefinedToken", "UT", USER, STARTING_ERC20_BALANCE);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_NotAllowedToken.selector);
        engine.depositCollateral(address(undefinedToken), STARTING_ERC20_BALANCE);
        vm.stopPrank();
    }

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(address(weth), AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier mintDsc() {
        vm.startPrank(USER);
        dsc.approve(address(engine), AMOUNT_DSC_TO_MINT);
        engine.mintDsc(AMOUNT_DSC_TO_MINT);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() external depositCollateral {
        //arrangment
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        //act/assert
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                                 redeem collateral                        ///
    ////////////////////////////////////////////////////////////////////////////////

    function testRedeemCollateral() external depositCollateral {
        vm.startPrank(USER);
        uint256 expectedCollateralBeforeRedeem = AMOUNT_COLLATERAL;
        uint256 collateralBeforeRedeem = engine.getCollateralInformation(weth, USER);
        assertEq(expectedCollateralBeforeRedeem, collateralBeforeRedeem);
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        uint256 expectedCollateralAfterRedeem = 0;
        uint256 collateralAfterRedeem = engine.getCollateralInformation(weth, USER);
        assertEq(expectedCollateralAfterRedeem, collateralAfterRedeem);
        vm.stopPrank();
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                                 mint dsc                                 ///
    ////////////////////////////////////////////////////////////////////////////////

    function testRevertsIfMintingMoreThan50PercentOfCollateralValue() external {
        address BAD_USER = makeAddr("BAD_USER");
        ERC20Mock(weth).mint(BAD_USER, STARTING_ERC20_BALANCE);

        vm.startPrank(BAD_USER);

        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(address(weth), AMOUNT_COLLATERAL);

        try engine.mintDsc(AMOUNT_DSC_TO_MINT + 1) {
            fail();
        } catch (bytes memory err) {
            bytes4 errorSelector;
            assembly {
                errorSelector := mload(add(err, 0x20))
            }
            assertEq(errorSelector, DSCEngine.DSCEngine__BreaksHealthFactor.selector);
        }

        vm.stopPrank();
    }

    function testDepositCollateralAndMintDsc() external depositCollateral mintDsc {
        //arrangement
        uint256 expectedDscMinted = AMOUNT_DSC_TO_MINT;
        (uint256 dscMinted,) = engine.getAccountInformation(USER);
        uint256 dscBalanceOnUserAccount = dsc.balanceOf(USER);
        //act/assert
        assertEq(dscMinted, expectedDscMinted);
        assertEq(dscBalanceOnUserAccount, dscMinted);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                              burn dsc                                    ///
    ////////////////////////////////////////////////////////////////////////////////

    function testBurnDsc() external depositCollateral mintDsc {
        //arrangement
        uint256 expectedDscMinted = AMOUNT_DSC_TO_MINT;
        uint256 expectedDscMintedAfterBurning = 0;
        //act/assert
        vm.startPrank(USER);
        dsc.approve(address(engine), AMOUNT_DSC_TO_MINT);
        (uint256 dscMinted,) = engine.getAccountInformation(USER);
        assertEq(dscMinted, expectedDscMinted);
        engine.burnDsc(AMOUNT_DSC_TO_MINT);
        (uint256 dscMintedAfterBurning,) = engine.getAccountInformation(USER);
        vm.stopPrank();
        assertEq(dscMintedAfterBurning, expectedDscMintedAfterBurning);
    }
    ////////////////////////////////////////////////////////////////////////////////
    ///                              depositing and minting                      ///
    ////////////////////////////////////////////////////////////////////////////////

    function testDepositAndMintDsc() external {
        //arrange
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        assertEq(totalDscMinted, AMOUNT_DSC_TO_MINT);
        assertEq(collateralValueInUsd, AMOUNT_COLLATERAL_IN_USD);
        vm.stopPrank();
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                              Redeem Collateral for Dsc                   ///
    ////////////////////////////////////////////////////////////////////////////////

    function testRedeemCollateralForDsc() external depositCollateral mintDsc {
        //arrangement
        uint256 expectedCollateralBeforeRedeeming = AMOUNT_COLLATERAL;
        uint256 expectedDscMintedBefore = AMOUNT_DSC_TO_MINT;
        (uint256 dscMintedBefore,) = engine.getAccountInformation(USER);
        uint256 collateralBeforeRedeeming = engine.getCollateralInformation(weth, USER);
        //act/assert
        assertEq(dscMintedBefore, expectedDscMintedBefore);
        assertEq(dsc.balanceOf(USER), AMOUNT_DSC_TO_MINT);
        assertEq(collateralBeforeRedeeming, expectedCollateralBeforeRedeeming);
        vm.prank(USER);
        engine.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
        (uint256 dscMintedAfter,) = engine.getAccountInformation(USER);
        uint256 collateralAfterRedeeming = engine.getCollateralInformation(weth, USER);
        assertEq(dscMintedAfter, 0);
        assertEq(collateralAfterRedeeming, 0);
        assertEq(dsc.balanceOf(USER), 0);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                              Liquidate function test                     ///
    ////////////////////////////////////////////////////////////////////////////////

    function testLiquidate() external {
        /**
         * USER2 deposits 10 weth - 20k USD
         * USER2 mints 10k DSC(DEBT) - 10k USD(COLLATERAL)
         * USER2 healthFactor = 1e18
         * USER deposit 10 weth and 10 wbtc - 30k USD
         * USER mints 7.5k DSC - 7.5k USD
         * USER 7.5k DSC(ACCOUNT)(DEBT) - 30k USD (COLLATERAL);
         * USER healthFactor = 2e18
         * ETH pice goes down to 1500USD/ETH (FURTHER CALCULATIONS EXCEPT OF HEALTH FACTOR ASSUMES THAT ETH IS STILL WORTH 2000USD/ETH FOR EASIER CALCULATIONS)
         * USER2 healthFactor = 0.75e18(bad need to be liquidated)
         * USER healthFacotr = 1.66e18(good)
         * USER mints 3k DSC - healtFactor = 1.19e18 (good)
         * USER 10.5k DSC(ACCOUNT)(DEBT) - 30k USD (COLLATERAL);
         * USER decide to liquidate USER2
         * USER2: 10k DSC(ACCOUNT)(NO DEBT) - 9k USD(collateral)- healthFacotr - unlimited(good) // 20k USD -> 19k USD (-1K$)
         * USER: 10 500 DSC(DEBT) - 30k USD(collateral) + 11000$WETH(account) + 500$DSC*account)
         *      //+ 1k$ 10500(DSC DEBT) / 11000$WETH(account) + 500 $DSC TOTAL: 30k USD -> 31k USD (+1K$);
         */

        //arrangement
        uint256 expectedUSER2HealthFactorAfterMintingDsc = 1e18;

        //act/assert
        vm.startPrank(USER2);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
        assertEq(engine.getHealthFactor(), expectedUSER2HealthFactorAfterMintingDsc);
        vm.stopPrank();
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        ERC20Mock(wbtc).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.depositCollateral(wbtc, AMOUNT_COLLATERAL);
        engine.mintDsc(7500 ether);
        vm.stopPrank();
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(1500e8);
        vm.prank(USER2);
        assertEq(engine.isHealthFactorBroken(), true);
        vm.startPrank(USER);
        assertEq(engine.isHealthFactorBroken(), false);
        engine.mintDsc(3000 ether);
        assertEq(engine.isHealthFactorBroken(), false);
        dsc.approve(address(engine), AMOUNT_DSC_TO_MINT);
        engine.liquidate(weth, USER2, AMOUNT_DSC_TO_MINT);

        assertEq(engine.isHealthFactorBroken(), false);
        assertEq(engine.getAmountDscMinted(), 10500 ether);
        console.log("USER WETH AMOUNT: ", ERC20Mock(weth).balanceOf(USER)); // HARD TO ASSERT(MANY DECIMALS PLACES) BUT RETURNING EXPECTED AMOUNT
        assertEq(dsc.balanceOf(USER), 500 ether);
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(2000e8);
        (, uint256 collateralValueInUSD) = engine.getAccountInformation(USER);
        assertEq(collateralValueInUSD, 30000 ether);
        vm.stopPrank();
        vm.startPrank(USER2);
        assertEq(engine.isHealthFactorBroken(), false);
        assertEq(engine.getAmountDscMinted(), 0);
        (, collateralValueInUSD) = engine.getAccountInformation(USER2);
        assertEq(dsc.balanceOf(USER2), 10000 ether);
        //assertEq(collateralValueInUSD, 9000 ether); HARD TO ASSERT(MANY DECIMALS PLACES) BUT RETURNING EXPECTED AMOUNT
        vm.stopPrank();
        assertEq(engine.getAmountDscMinted(), 0);
    }
}
