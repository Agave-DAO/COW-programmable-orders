// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../src/AgaveHoldingsOracle.sol";

contract CornArbTest is Test {
    uint256 gcFork;

    AgaveHoldingsOracle agaveHoldingsOracle;
    address safe = 0x90AA4056945B9f4D8A9A301A6CAD95b0A7AfAfBa;

    function setUp() public {
        gcFork = vm.createFork("https://rpc.gnosis.gateway.fm/");
        vm.selectFork(gcFork);

        agaveHoldingsOracle = new AgaveHoldingsOracle();
    }

    function testTest() public {
        console.log("Following are presented with no decimals for visibility");
        uint agveBalance = agaveHoldingsOracle.agveHoldings();
        console.log(
            "Agve Token Holdings (in treasury): ",
            agveBalance / 1 ether
        );
        uint assetsBalance = agaveHoldingsOracle.assetHoldings();
        console.log("Asset balance (in treasury): ", assetsBalance / 1 ether);
        uint agveDepositsValue = agaveHoldingsOracle.protocolBalance();
        console.log(
            "XDAI deposits-debts (in pool): ",
            agveDepositsValue / 1 ether
        );
        (
            uint agveLPHoldings,
            uint WETHLPHoldingsValue,
            uint GNOLPHoldingsValue
        ) = agaveHoldingsOracle.LPHoldings();
        console.log("Agve token holdings (in LPs): ", agveLPHoldings / 1 ether);
        console.log(
            "ETH + GNO value (in LPs): ",
            (WETHLPHoldingsValue + GNOLPHoldingsValue) / 1 ether
        );

        uint totalAssets = agaveHoldingsOracle.totalAssets();
        console.log("TotalAssets: ", totalAssets);
        uint totalEquity = agaveHoldingsOracle.totalEquity();
        console.log("TotalEquity: ", totalEquity);

        uint oraclePrice = agaveHoldingsOracle.agavePrice();
        console.log("Resulting Agave price: ", oraclePrice);

        uint reimbursementTrancheValue = agaveHoldingsOracle
            .reimbursementTrancheValue();
        console.log("ReimbursementTrancheValue: ", reimbursementTrancheValue);

        uint agavePriceBeforeReimbursement = agaveHoldingsOracle
            .agavePriceBeforeReimbursement();
        console.log(
            "Resulting Agave price before Reimbursement: ",
            agavePriceBeforeReimbursement
        );
    }
}
