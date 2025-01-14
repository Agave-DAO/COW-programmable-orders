// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "composable-test/ComposableCoW.base.t.sol";
import "../src/CornArb.sol";
import {GenericArb} from "../src/GenericArb.sol";

contract CornArbTest is BaseComposableCoWTest {
		IERC20 constant SELL_TOKEN = IERC20(0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1);
    IERC20 constant BUY_TOKEN = IERC20(0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb);
    address constant COMPOSABLE_COW = 0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74;
    // bytes32 constant APP_DATA = 0x90afd4be1fb667db713eb836e0134cb8d39d118c29494199fb4f880f22dc7415;
		bytes32 constant APP_DATA = 0x0000000000000000000000000000000000000000000000000000000000000000;

    GenericArb cornArb;
    address safe = 0x90AA4056945B9f4D8A9A301A6CAD95b0A7AfAfBa;

    function setUp() public virtual override(BaseComposableCoWTest) {
        super.setUp();

        // cornArb = new CornArb(ComposableCoW(COMPOSABLE_COW));
				cornArb = GenericArb(0xaadc9A18C1bD99721913d50C6730cd7819954663);
    }

		function test_e2e_settle() public {
        CornArb.Data memory data = helper_testData();
        // create the order
        IConditionalOrder.ConditionalOrderParams memory params =
            super.createOrder(cornArb, keccak256("GenericArb"), abi.encode(data));

        // create the order
        _create(address(safe), params, true);
        // // deal the sell token to the safe
        deal(address(data.sellToken), address(safe), 10 ether);
        // authorise the vault relayer to pull the sell token from the safe
        vm.prank(address(safe));
        data.sellToken.approve(address(relayer), 10 ether);


        (GPv2Order.Data memory order, bytes memory sig) =
            composableCow.getTradeableOrderWithSignature(address(safe), params, bytes(""), new bytes32[](0));

        // uint256 safe1BalanceBefore = data.sellToken.balanceOf(address(safe));

        // settle(address(safe), bob, order, sig, hex"");

        // uint256 safe1BalanceAfter = data.sellToken.balanceOf(address(safe));

        // assertEq(safe1BalanceAfter, safe1BalanceBefore - data.sellAmount);

        // in the end-to-end, we can test replay protection by trying to settle again
        // vm.warp(block.timestamp + 1);
        // settle(
        //     address(safe1),
        //     bob,
        //     order,
        //     sig,
        //     abi.encodeWithSelector(IConditionalOrder.PollNever.selector, AUCTION_FILLED)
        // );
    }

		function helper_testData() internal view returns (CornArb.Data memory data) {
        return CornArb.Data({
            sellToken: SELL_TOKEN,
            buyToken: BUY_TOKEN,
            appData: APP_DATA
        });
    }

    function mockCowCabinet(address mock, address owner, bytes32 ctx, bytes32 retVal)
        internal
        returns (ComposableCoW iface)
    {
        iface = ComposableCoW(mock);
        vm.mockCall(mock, abi.encodeWithSelector(iface.cabinet.selector, owner, ctx), abi.encode(retVal));
    }


    // function test_verifyOrder() public {
    //     bytes32 domainSeparator = 0x8f05589c4b810bc2f706854508d66d447cd971f8354a4bb0b3471ceb0a466bc7;

    //     CornArb.Data memory data = helper_testData();
    //     vm.warp(1_000_000);
    //     GPv2Order.Data memory empty;
    //     GPv2Order.Data memory order =
    //         cornArb.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));
    //     bytes32 hash_ = GPv2Order.hash(order, domainSeparator);
    //     vm.warp(1_000_000 + 79);

    //     cornArb.verify(safe, address(0), hash_, domainSeparator, bytes32(0), abi.encode(data), bytes(""), empty);
    // }

    // function test_validation_RevertWhenSellTokenEqualsBuyToken() public {
    //     CornArb.Data memory data = helper_testData();
    //     data.sellToken = data.buyToken;

    //     helper_runRevertingValidate(data, ERR_SAME_TOKENS);
    // }

    // function test_validation_RevertWhenSellAmountInvalid() public {
    //     CornArb.Data memory data = helper_testData();
    //     data.sellAmount = 0;

    //     helper_runRevertingValidate(data, ERR_MIN_SELL_AMOUNT);
    // }

    function helper_runRevertingValidate(CornArb.Data memory data, string memory reason) internal {
        vm.expectRevert(abi.encodeWithSelector(IConditionalOrder.OrderNotValid.selector, reason));
        cornArb.validateData(abi.encode(data));
    }

}
