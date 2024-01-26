// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {GPv2Order} from "cowprotocol/libraries/GPv2Order.sol";

import {ComposableCoW} from "composable/ComposableCoW.sol";
import "composable/BaseConditionalOrder.sol";
import "composable/interfaces/IAggregatorV3Interface.sol";
import {AgaveHoldingsOracle} from "./AgaveHoldingsOracle.sol";

import {IAgaveOracle} from "./IAgaveOracle.sol";
import {ILendingPool} from "./ILendingPool.sol";

// --- error strings
/// @dev can't buy and sell the same token
string constant ERR_SAME_TOKENS = "same tokens";
/// @dev sell amount must be greater than zero
string constant ERR_MIN_SELL_AMOUNT = "sellAmount must be gt 0";

/**
 * @title Buy asset when market price below oracle price.
 * @author CoW Protocol Developers
 * @author Pogo (changes specific to )
 */
contract AgaveBuybackOrder is BaseConditionalOrder {
    /// @dev `staticInput` data struct for buying
    struct Data {
        IERC20 sellToken;
        bytes32 appData;
    }

    /// @dev need to know where to find ComposableCoW as this has the cabinet!
    ComposableCoW public immutable composableCow;

		IAgaveOracle oracle = IAgaveOracle(0x062B9D1D3F5357Ef399948067E93B81F4B85db7a);
		address AGVE = 0x3a97704a1b25F08aa230ae53B352e2e72ef52843;
        AgaveHoldingsOracle TreasuryOracle =
        AgaveHoldingsOracle(0xA671d7D0C571e5B92510dE6c5d0B5C1635eC8791);
		address agaveDao = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;
		address owner; // owner is the holder of the funds for sale

		uint256 amtToSellDefault = 25 ether;

        mapping(address => uint256) amtToSellForAsset;

    constructor(ComposableCoW _composableCow, address _owner) {
        composableCow = _composableCow;
		owner = _owner;
    }


		function transferOwnership(address newOwner) external {
				require(msg.sender == owner);
				owner = newOwner;
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
                address buyToken = AGVE;

				uint oracleSellTokenPrice = oracle.getAssetPrice(address(data.sellToken));
                uint amtToSell = (amtToSellForAsset[address(data.sellToken)] != 0) ? amtToSellForAsset[address(data.sellToken)] : amtToSellDefault;
				uint sellAmount = 1 ether * amtToSell / oracleSellTokenPrice;

				if (IERC20(data.sellToken).balanceOf(owner) < sellAmount){
						revert("no balance");
				}

				uint oracleBuyTokenPrice = (TreasuryOracle.agavePrice() / 1e17) * 1e17;

				uint decimalsBuyToken = 10**IERC20Metadata(buyToken).decimals();
				uint decimalsSellToken = 10**IERC20Metadata(address(data.sellToken)).decimals();

				uint oracleBuyAmount = oracleSellTokenPrice  * sellAmount * decimalsBuyToken / (oracleBuyTokenPrice * decimalsSellToken);
				uint marketBuyAmount = oracleBuyAmount + oracleBuyAmount * 3 / 1000; // we want a price at least 0.3% better than oracle price, if available

        order = GPv2Order.Data(
            data.sellToken,
            IERC20(buyToken),
            agaveDao,
            sellAmount,
            marketBuyAmount,
            validToBucket(300), // expiry
            data.appData,
            0, // use zero fee for limit orders
            GPv2Order.KIND_SELL, // only sell order support for now
            false, // partially fillable orders are not supported
            GPv2Order.BALANCE_ERC20,
            GPv2Order.BALANCE_ERC20
        );

    }

		function changeAmtToSellForAsset(address assetAddress, uint newAmt) external {
				require(msg.sender == owner);
				amtToSellForAsset[assetAddress] = newAmt;
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
    function validateData(bytes memory data) external view override {
        _validateData(abi.decode(data, (Data)));
    }

    /**
     * Internal method for validating the ABI encoded data struct.
     * @dev This is a gas optimisation method as it allows us to avoid ABI decoding the data struct twice.
     * @param data `Data` struct containing the order parameters
     * @dev Throws if the order provided is not valid.
     */
    function _validateData(Data memory data) internal view {
        if (data.sellToken == IERC20(AGVE)) revert OrderNotValid(ERR_SAME_TOKENS);
    }
}
