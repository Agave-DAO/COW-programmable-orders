// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {IAgaveOracle} from "./IAgaveOracle.sol";
import {ILendingPool} from "./ILendingPool.sol";

interface IDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function getAllATokens() external view returns (TokenData[] memory);
}

interface LPs {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        ); // honeyswap pool

    function getPoolTokens(
        bytes32 poolId
    )
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        ); // balancer pool
}

contract AgaveHoldingsOracle {
    ILendingPool pool =
        ILendingPool(0x5E15d5E33d318dCEd84Bfe3F4EACe07909bE6d9c);
    IAgaveOracle oracle =
        IAgaveOracle(0x062B9D1D3F5357Ef399948067E93B81F4B85db7a);
    IDataProvider dataProvider =
        IDataProvider(0xE6729389DEa76D47b5BcB0bA5c080821c3B51329);

    address constant treasury = 0xb4c575308221CAA398e0DD2cDEB6B2f10d7b000A;

    address constant AGVE = 0x3a97704a1b25F08aa230ae53B352e2e72ef52843;
    address constant GNO = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address constant WBTC = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;
    address constant WETH = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;
    address constant WXDAI = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address constant LINK = 0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2;
    address constant FOX = 0x21a42669643f45Bc0e086b8Fc2ed70c23D67509d;
    address constant WSTETH = 0x6C76971f98945AE98dD7d4DFcA8711ebea946eA6;
    address constant USDC = 0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83;
    address constant USDT = 0x4ECaBa5870353805a9F068101A40E0f32ed605C6;
    address constant sDAI = 0xaf204776c7245bF4147c2612BF6e5972Ee483701;
    address constant EURe = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;

    address constant WETHAGVE = 0xeba7Cc57e6f745B8D5CaB829e07346C65393D78E;
    address constant GNOAGVE = 0x388Cae2f7d3704C937313d990298Ba67D70a3709;
    address constant balVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    uint constant agveMaxSupply = 100000 * 1 ether;

    bytes32 constant poolId =
        0x388cae2f7d3704c937313d990298ba67d70a3709000200000000000000000026;

    address[] trancheAssets = [USDC, WXDAI, LINK, GNO, WBTC, WETH];
    uint[] trancheAmounts = [
        24078408053,
        45946608268509000000000,
        1175790459215760000000,
        386624586847771000000,
        79361022,
        18185795406575000000
    ];

    function agveHoldings() public view returns (uint) {
        return IERC20(AGVE).balanceOf(treasury);
    }

    function assetHoldings() public view returns (uint assetsValue) {
        address[] memory assets = pool.getReservesList();
        uint[] memory assetPrices = oracle.getAssetsPrices(assets);

        for (uint i; i < assets.length; i++) {
            assetsValue +=
                (IERC20(assets[i]).balanceOf(treasury) * assetPrices[i]) /
                10 ** IERC20Metadata(assets[i]).decimals();
        }
    }

    function protocolBalance() public view returns (uint balance) {
        address[] memory assets = pool.getReservesList();
        IDataProvider.TokenData[] memory agAssets = dataProvider
            .getAllATokens();
        uint[] memory assetPrices = oracle.getAssetsPrices(assets);

        uint totalCollateralETH;
        for (uint i; i < assets.length; i++) {
            totalCollateralETH +=
                (IERC20(agAssets[i].tokenAddress).balanceOf(treasury) *
                    assetPrices[i]) /
                10 ** IERC20Metadata(agAssets[i].tokenAddress).decimals();
        }

        (, uint totalDebtETH, , , , ) = pool.getUserAccountData(treasury);
        return totalCollateralETH - totalDebtETH;
    }

    function LPHoldings()
        public
        view
        returns (uint AGVEinLP, uint WETHinUSD, uint GNOinUSD)
    {
        uint poolSupply = IERC20(WETHAGVE).totalSupply();
        uint balance = IERC20(WETHAGVE).balanceOf(treasury);
        if (balance > 0) {
            (uint112 reserveAgve, uint112 reserveWeth, ) = LPs(WETHAGVE)
                .getReserves();
            WETHinUSD =
                (oracle.getAssetPrice(WETH) * reserveWeth * balance) /
                (poolSupply * 1 ether);
            AGVEinLP = (reserveAgve * balance) / poolSupply;
        }
        poolSupply = IERC20(GNOAGVE).totalSupply();
        balance = IERC20(GNOAGVE).balanceOf(treasury);
        if (balance > 0) {
            (, uint256[] memory balances, ) = LPs(balVault).getPoolTokens(
                poolId
            ); // first is AGVE, 2nd is GNO
            GNOinUSD =
                (oracle.getAssetPrice(GNO) * balances[1] * balance) /
                (poolSupply * 1 ether);
            AGVEinLP += (balances[0] * balance) / poolSupply;
        }
    }

    function totalAssets() public view returns (uint totalValue) {
        uint assetsValue = assetHoldings();
        (, uint WETHinUSD, uint GNOinUSD) = LPHoldings();
        uint depositedValue = protocolBalance();
        totalValue = assetsValue + WETHinUSD + GNOinUSD + depositedValue;
    }

    function totalEquity() public view returns (uint totalAGVE) {
        uint agveInTreasury = agveHoldings();
        (uint AGVEinLP, , ) = LPHoldings();
        totalAGVE = agveInTreasury + AGVEinLP;
    }

    function agavePrice() external view returns (uint) {
        return ((totalAssets() * 1 ether) / (agveMaxSupply - totalEquity()));
    }

    function reimbursementTrancheValue()
        public
        view
        returns (uint trancheValue)
    {
        /*
			agUSDC - 24078.408053
			agWXDAI - 45946.608268509000000000
			LINK - 1175.790459215760000000
			agGNO - 386.624586847771000000
			agWBTC - 0.79361022
			agWETH - 18.185795406575000000
			*/
        uint[] memory assetPrices = oracle.getAssetsPrices(trancheAssets);

        for (uint i; i < trancheAssets.length; i++) {
            trancheValue +=
                (trancheAmounts[i] * assetPrices[i]) /
                10 ** IERC20Metadata(trancheAssets[i]).decimals();
        }
    }

    function agavePriceBeforeReimbursement()
        external
        view
        returns (uint refPrice)
    {
        return (((totalAssets() - reimbursementTrancheValue()) * 1 ether) /
            (agveMaxSupply - totalEquity()));
    }
}
