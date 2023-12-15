// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {GPv2Order} from "cowprotocol/libraries/GPv2Order.sol";

import {ComposableCoW} from "composable/ComposableCoW.sol";
import "composable/BaseConditionalOrder.sol";
import "composable/interfaces/IAggregatorV3Interface.sol";

import {IAgaveOracle} from "./IAgaveOracle.sol";
import {ILendingPool} from "./ILendingPool.sol";

// --- error strings
/// @dev auction hasn't started
string constant AUCTION_NOT_STARTED = "auction not started";
/// @dev auction has already ended
string constant AUCTION_ENDED = "auction ended";
/// @dev auction has already been filled
string constant AUCTION_FILLED = "auction filled";
/// @dev can't buy and sell the same token
string constant ERR_SAME_TOKENS = "same tokens";
/// @dev sell amount must be greater than zero
string constant ERR_MIN_SELL_AMOUNT = "sellAmount must be gt 0";
/// @dev auction duration must be greater than zero
string constant ERR_MIN_AUCTION_DURATION = "auction duration is zero";
/// @dev step discount is zero
string constant ERR_MIN_STEP_DISCOUNT = "stepDiscount is zero";
/// @dev step discount is greater than or equal to 10000
string constant ERR_MAX_STEP_DISCOUNT = "stepDiscount is gte 10000";
/// @dev number of steps is less than or equal to 1
string constant ERR_MIN_NUM_STEPS = "numSteps is lte 1";
/// @dev total discount is greater than 10000
string constant ERR_MAX_TOTAL_DISCOUNT = "total discount is gte 10000";

/**
 * @title Buy asset when market price below oracle price.
 * @author CoW Protocol Developers
 * @author Pogo (changes specific to )
 */
contract CornArb is BaseConditionalOrder {
    /// @dev `staticInput` data struct for buying
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint256 sellAmount;
        bytes32 appData;
    }

    /// @dev need to know where to find ComposableCoW as this has the cabinet!
    ComposableCoW public immutable composableCow;

		ILendingPool pool = ILendingPool(0x5E15d5E33d318dCEd84Bfe3F4EACe07909bE6d9c);
		IAgaveOracle oracle = IAgaveOracle(0x062B9D1D3F5357Ef399948067E93B81F4B85db7a);
		address WBTC = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;
		// address AGVE = 0x3a97704a1b25F08aa230ae53B352e2e72ef52843;
		// address GNO  = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
		address agaveDao = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;
		address owner;

		bool test; // TEST

    constructor(ComposableCoW _composableCow) {
        composableCow = _composableCow;
				owner = msg.sender;
				IERC20(WBTC).approve(address(pool), 1000000000000000000000 ether);
    }

		function depositOnBehalfOfAgaveDAO() external {
				IERC20(WBTC).transferFrom(owner, address(this), IERC20(WBTC).balanceOf(owner));
				pool.deposit(WBTC, IERC20(WBTC).balanceOf(address(this)), owner, 0x00);
				test = true;
		}

		function emergencyWithdraw(address asset) external {
				require(msg.sender == owner);

				IERC20(asset).transfer(msg.sender, IERC20(asset).balanceOf(address(this)));
		}

    /**
     * If the conditions are satisfied, return the order that can be filled.
     * @param staticInput The ABI encoded `Data` struct.
     * @return order The GPv2Order.Data struct that can be filled.
     */
    function getTradeableOrder(address, address, bytes32, bytes calldata staticInput, bytes calldata)
        public
        view
        override
        returns (GPv2Order.Data memory order)
    {
        Data memory data = abi.decode(staticInput, (Data));
        _validateData(data);

				require(!test, "all done"); // TEST

				uint oracleBuyTokenPrice = oracle.getAssetPrice(address(data.buyToken));
				uint oracleSellTokenPrice = oracle.getAssetPrice(address(data.sellToken));

				uint decimalsBuyToken = 10**IERC20Metadata(address(data.buyToken)).decimals();
				uint decimalsSellToken = 10**IERC20Metadata(address(data.sellToken)).decimals();

				uint oracleBuyAmount = oracleSellTokenPrice  * data.sellAmount * decimalsBuyToken / (oracleBuyTokenPrice * decimalsSellToken);
				uint marketBuyAmount = oracleBuyAmount + oracleBuyAmount * 3 / 1000; // we want a price at least 0.3% better than oracle price, if available

        order = GPv2Order.Data(
            data.sellToken,
            data.buyToken,
            data.receiver,
            data.sellAmount,
            marketBuyAmount,
            validToBucket(180), // expiry
            data.appData,
            0, // use zero fee for limit orders
            GPv2Order.KIND_SELL, // only sell order support for now
            false, // partially fillable orders are not supported
            GPv2Order.BALANCE_ERC20,
            GPv2Order.BALANCE_ERC20
        );

    }

		/**
     * Given the width of the validity bucket, return the timestamp of the *end* of the bucket.
     * @param validity The width of the validity bucket in seconds.
     */
    function validToBucket(uint32 validity) internal view returns (uint32 validTo) {
        validTo = ((uint32(block.timestamp) / validity) * validity) + validity;
    }

    /**
     * @dev External function for validating the ABI encoded data struct. Help debuggers!
     * @param data `Data` struct containing the order parameters
     * @dev Throws if the order provided is not valid.
     */
    function validateData(bytes memory data) external pure override {
        _validateData(abi.decode(data, (Data)));
    }

    /**
     * Internal method for validating the ABI encoded data struct.
     * @dev This is a gas optimisation method as it allows us to avoid ABI decoding the data struct twice.
     * @param data `Data` struct containing the order parameters
     * @dev Throws if the order provided is not valid.
     */
    function _validateData(Data memory data) internal pure {
        if (data.sellToken == data.buyToken) revert OrderNotValid(ERR_SAME_TOKENS);
        if (data.sellAmount == 0) revert OrderNotValid(ERR_MIN_SELL_AMOUNT);
    }
}
