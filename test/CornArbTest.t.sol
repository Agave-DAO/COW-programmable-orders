// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "composable-test/ComposableCoW.base.t.sol";
import "../src/CornArb.sol";

contract CornArbTest is BaseComposableCoWTest {
		IERC20 constant SELL_TOKEN = IERC20(0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb);
    IERC20 constant BUY_TOKEN = IERC20(0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252);
    address constant COMPOSABLE_COW = 0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74;
    bytes32 constant APP_DATA = 0x31d1796250cd5d5d98721da66d78432b71b49fd0b8d2d69b616653e586e9dfb1;

    CornArb cornArb;
    address safe = 0x9027Ad471a1B992602d0996Ce96Dcb011249e3C8;

    function setUp() public virtual override(BaseComposableCoWTest) {
        super.setUp();

        // cornArb = new CornArb(ComposableCoW(COMPOSABLE_COW));
				cornArb = CornArb(0x30e8F216003b3686d2d72F44FD7202eE33a7fFF2);
    }

    function mockCowCabinet(address mock, address owner, bytes32 ctx, bytes32 retVal)
        internal
        returns (ComposableCoW iface)
    {
        iface = ComposableCoW(mock);
        vm.mockCall(mock, abi.encodeWithSelector(iface.cabinet.selector, owner, ctx), abi.encode(retVal));
    }


    function test_verifyOrder() public {
        bytes32 domainSeparator = 0x8f05589c4b810bc2f706854508d66d447cd971f8354a4bb0b3471ceb0a466bc7;

        CornArb.Data memory data = helper_testData();
        vm.warp(1_000_000);
        GPv2Order.Data memory empty;
        GPv2Order.Data memory order =
            cornArb.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));
        bytes32 hash_ = GPv2Order.hash(order, domainSeparator);
        vm.warp(1_000_000 + 79);

        cornArb.verify(safe, address(0), hash_, domainSeparator, bytes32(0), abi.encode(data), bytes(""), empty);
    }

    function test_validation_RevertWhenSellTokenEqualsBuyToken() public {
        CornArb.Data memory data = helper_testData();
        data.sellToken = data.buyToken;

        helper_runRevertingValidate(data, ERR_SAME_TOKENS);
    }

    function test_validation_RevertWhenSellAmountInvalid() public {
        CornArb.Data memory data = helper_testData();
        data.sellAmount = 0;

        helper_runRevertingValidate(data, ERR_MIN_SELL_AMOUNT);
    }

    function test_e2e_settle() public {
        CornArb.Data memory data = helper_testData();
        data.sellToken = SELL_TOKEN;
        data.buyToken = BUY_TOKEN;

        // create the order
        IConditionalOrder.ConditionalOrderParams memory params =
            super.createOrder(cornArb, keccak256("CornArb"), abi.encode(data));

        // create the order
        _create(address(safe), params, true);
        // deal the sell token to the safe
        deal(address(data.sellToken), address(safe), data.sellAmount * 2);
        // authorise the vault relayer to pull the sell token from the safe
        vm.prank(address(safe));
        data.sellToken.approve(address(relayer), data.sellAmount * 2);


        (GPv2Order.Data memory order, bytes memory sig) =
            composableCow.getTradeableOrderWithSignature(address(safe), params, bytes(""), new bytes32[](0));

        uint256 safe1BalanceBefore = data.sellToken.balanceOf(address(safe));

        settle(address(safe), bob, order, sig, hex"");

        uint256 safe1BalanceAfter = data.sellToken.balanceOf(address(safe));

        assertEq(safe1BalanceAfter, safe1BalanceBefore - data.sellAmount);

        // in the end-to-end, we can test replay protection by trying to settle again
        vm.warp(block.timestamp + 1);
        settle(
            address(safe1),
            bob,
            order,
            sig,
            abi.encodeWithSelector(IConditionalOrder.PollNever.selector, AUCTION_FILLED)
        );
    }

    function helper_runRevertingValidate(CornArb.Data memory data, string memory reason) internal {
        vm.expectRevert(abi.encodeWithSelector(IConditionalOrder.OrderNotValid.selector, reason));
        cornArb.validateData(abi.encode(data));
    }

    function helper_testData() internal view returns (CornArb.Data memory data) {
        return CornArb.Data({
            sellToken: IERC20(0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb),
            buyToken: IERC20(0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252),
            receiver: 0xBF8d706C844F1849B063870a42417C20227276F6,
            sellAmount: 0.06 ether,
            appData: 0x31d1796250cd5d5d98721da66d78432b71b49fd0b8d2d69b616653e586e9dfb1
        });
    }
}
