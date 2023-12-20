// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {IAgaveOracle} from "./IAgaveOracle.sol";
import {ILendingPool} from "./ILendingPool.sol";

contract AgaveHoldingsOracle {

		address constant treasury = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;

		address constant AGVE = 0x3a97704a1b25F08aa230ae53B352e2e72ef52843;
		address constant GNO  = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
		address constant WBTC = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;
		address variableDebtWTBC = 0x110C5A1494F0AB6C851abB72AA2efa3dA738aB72;
		


}