// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";

// Order type
import "composable/ComposableCoW.sol";
import "../src/AgaveHoldingsOracle.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {GenericArb} from "../src/GenericArb.sol";

contract Deploy is Script {
    function run() external {


 /*//////////////////////////////////////////////////////////////
                                KEY MANAGEMENT
 //////////////////////////////////////////////////////////////*/

    uint256 deployerPrivateKey = 0;
    // string memory mnemonic = vm.envString('MNEMONIC');

    // if (bytes(mnemonic).length > 30) {
    //   deployerPrivateKey = vm.deriveKey(mnemonic, 0);
    // } else {
    //   deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    // }

		deployerPrivateKey = vm.envUint('PRIVATE_KEY');

   address composableCow = vm.envAddress("COMPOSABLE_COW");

 /*//////////////////////////////////////////////////////////////
                                OPERATIONS
 //////////////////////////////////////////////////////////////*/                         


    vm.startBroadcast(deployerPrivateKey);

        // Deploy DutchAuction
       new GenericArb{salt: ""}(ComposableCoW(composableCow), 0x90AA4056945B9f4D8A9A301A6CAD95b0A7AfAfBa);

       
        // Deploy Oracle
    //  new AgaveHoldingsOracle();

     vm.stopBroadcast();
    }
}
