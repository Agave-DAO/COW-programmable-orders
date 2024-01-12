// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";

// Order type
import "composable/ComposableCoW.sol";
import "../src/AgaveHoldingsOracle.sol";
import {DutchAuction} from "../src/DutchAuction.sol";

contract Deploy is Script {
    function run() external {


 /*//////////////////////////////////////////////////////////////
                                KEY MANAGEMENT
 //////////////////////////////////////////////////////////////*/

    uint256 deployerPrivateKey = 0;
    string memory mnemonic = vm.envString('MNEMONIC');

    if (bytes(mnemonic).length > 30) {
      deployerPrivateKey = vm.deriveKey(mnemonic, 0);
    } else {
      deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    }

 //   address composableCow = vm.envAddress("COMPOSABLE_COW");

 /*//////////////////////////////////////////////////////////////
                                OPERATIONS
 //////////////////////////////////////////////////////////////*/                         


    vm.startBroadcast(deployerPrivateKey);

        // Deploy DutchAuction
       // new DutchAuction{salt: ""}(ComposableCoW(composableCow));

       
        // Deploy Oracle
     new AgaveHoldingsOracle();

     vm.stopBroadcast();
    }
}
