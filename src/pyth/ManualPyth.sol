// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ManualPyth
/// @notice A contract for managing Pyth price feeds with manual override capability
/// @dev Inherits from Ownable for access control
contract ManualPyth is Ownable {
    IPyth public pyth;
    bytes32 public priceId;
    PythStructs.Price public manualPrice;

    /// @notice Emitted when the price is updated
    /// @param price The new price value
    /// @param conf The confidence interval
    /// @param expo The exponent of the price
    /// @param timestamp The timestamp of the update
    event PriceUpdated(
        int64 price,
        uint256 conf,
        int32 expo,
        uint256 timestamp
    );

    /// @notice Initializes the contract with Pyth oracle address and price feed ID
    /// @param _pyth The address of the Pyth oracle contract
    /// @param _priceId The ID of the price feed to track
    constructor(address _pyth, bytes32 _priceId) Ownable(msg.sender) {
        pyth = IPyth(_pyth);
        priceId = _priceId;
    }

    /// @notice Retrieves the current price
    /// @return The current price structure
    function getPrice() public view returns (PythStructs.Price memory) {
        return manualPrice;
    }

    /// @notice Allows the owner to manually set the price
    /// @param _price The price value to set
    /// @param _conf The confidence interval
    /// @param _expo The exponent of the price
    function setManualPrice(
        int64 _price,
        uint64 _conf,
        int32 _expo
    ) external onlyOwner {
        manualPrice = PythStructs.Price(
            _price,
            _conf,
            _expo,
            uint64(block.timestamp)
        );
        emit PriceUpdated(_price, _conf, _expo, block.timestamp);
    }

    /// @notice Updates the price from the Pyth oracle
    /// @param priceUpdateData The update data from Pyth
    function updatePriceFromPyth(
        bytes[] calldata priceUpdateData
    ) external payable {
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        PythStructs.Price memory updatedPrice = pyth.getPriceUnsafe(priceId);
        manualPrice = updatedPrice;
        emit PriceUpdated(
            updatedPrice.price,
            updatedPrice.conf,
            updatedPrice.expo,
            updatedPrice.publishTime
        );
    }
}
