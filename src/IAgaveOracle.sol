// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IAgaveOracle {

  /// @notice Gets a list of prices from a list of assets addresses
  /// @param assets The list of assets addresses
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

	function getAssetPrice(address asset) external view returns (uint256);

}