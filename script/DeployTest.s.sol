// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";

// Order type
import "composable/ComposableCoW.sol";
// import {DutchAuction} from "../src/DutchAuction.sol";
import {CornArb} from "../src/CornArb.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

// metadata for IPFS post-hook:
// `{"metadata":{"hooks":{"post":[{"callData":"0x37c36970","gasLimit":"700000","target":"0xBF8d706C844F1849B063870a42417C20227276F6"}],"version":"0.1.0"}},"version":"0.10.0"}`
// appDataHash: 0x5571e18d1d66f8311a9c0c8461d27c59b278b42002f8a4b023514e86e9a4ae1f

contract DeployTest is Script {

		address WBTC = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;
		address AGVE = 0x3a97704a1b25F08aa230ae53B352e2e72ef52843;
		address GNO  = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
		address owner = 0xBF8d706C844F1849B063870a42417C20227276F6;
		address CowVaultRelay = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;
		address composableCow = 0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74;

		CornArb cornArb = CornArb(0x9027Ad471a1B992602d0996Ce96Dcb011249e3C8);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

				// IERC20(GNO).approve(CowVaultRelay, 1 ether);
				new CornArb{salt: ""}(ComposableCoW(composableCow));

				vm.stopBroadcast();
    }
}
