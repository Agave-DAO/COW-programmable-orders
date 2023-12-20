// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../src/AgaveHoldingsOracle.sol";

contract CornArbTest is Test {


    CornArb cornArb;
    address safe = 0x90AA4056945B9f4D8A9A301A6CAD95b0A7AfAfBa;

    function setUp() public virtual override(BaseComposableCoWTest) {

        // cornArb = new CornArb(ComposableCoW(COMPOSABLE_COW));
				cornArb = CornArb(0xd36997955DC839ba3e3dA386f7ebFdFB241f084a);
    }

}
