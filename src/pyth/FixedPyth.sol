// SPDX-License-Identifier: MIT
/// @author: minwoogramer
pragma solidity 0.8.23;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title FixedPyth
/// @notice A contract for fetching price data from Pyth Network or using a fixed price
/// @dev Inherits from Ownable for access control. This contract allows switching between Pyth Network prices and a fixed price.
contract FixedPyth is Ownable {
    /// @notice Interface for interacting with Pyth Network
    IPyth public pyth;

    /// @notice Unique identifier for the price feed
    bytes32 public priceId;

    /// @notice Constant for price precision (8 decimal places)
    uint256 public constant PRICE_PRECISION = 1e8;

    /// @notice Maximum allowed age of the price data
    uint32 public maxPriceAge;

    /// @notice Fixed price value when not using Pyth Network
    int64 public fixedPrice;

    /// @notice Flag to determine whether to use fixed price or Pyth Network
    bool public useFixedPrice;

    /// @notice Emitted when price is updated
    /// @param price The updated price
    /// @param conf The confidence interval
    /// @param expo The price exponent
    /// @param timestamp The timestamp of the price update
    event PriceUpdated(
        int64 price,
        uint256 conf,
        int32 expo,
        uint256 timestamp
    );

    /// @notice Emitted when fixed price is set
    /// @param price The fixed price that was set
    event FixedPriceSet(int64 price);

    /// @notice Thrown when an invalid price is provided
    error InvalidPrice();

    /// @notice Thrown when the price data is stale
    error PriceStale();

    /// @notice Initializes the contract
    /// @dev Sets up the initial configuration for the Pyth price feed
    /// @param _pyth Address of the Pyth contract
    /// @param _priceId Identifier for the price feed
    /// @param _maxPriceAge Maximum allowed age of the price data
    constructor(
        address _pyth,
        bytes32 _priceId,
        uint32 _maxPriceAge
    ) Ownable(msg.sender) {
        pyth = IPyth(_pyth);
        priceId = _priceId;
        maxPriceAge = _maxPriceAge;
    }

    /// @notice Gets the current price
    /// @dev This function is the main interface for other contracts to fetch the price.
    ///      It returns either the fixed price or the Pyth Network price based on the current setting.
    /// @return price The current price data
    function getPrice() public view returns (PythStructs.Price memory price) {
        if (useFixedPrice) {
            return PythStructs.Price(fixedPrice, 0, 0, uint64(block.timestamp));
        }
        price = pyth.getPriceUnsafe(priceId);
        if (price.publishTime + maxPriceAge < block.timestamp) {
            revert PriceStale();
        }
        return price;
    }

    /// @notice Sets a fixed price
    /// @dev Allows the owner to set a fixed price and enable its use.
    ///      This is useful for testing or in case of Pyth Network unavailability.
    /// @param _price The fixed price to set
    function setFixedPrice(int64 _price) external onlyOwner {
        fixedPrice = _price;
        useFixedPrice = true;
        emit FixedPriceSet(_price);
    }

    /// @notice Unsets fixed price and reverts to using Pyth Network
    /// @dev Allows the owner to switch back to using Pyth Network prices.
    ///      This is typically used after testing or when Pyth Network becomes available again.
    function unsetFixedPrice() external onlyOwner {
        useFixedPrice = false;
    }

    /// @notice Updates price data from Pyth Network
    /// @dev Allows anyone to update the price feed by providing the necessary update data.
    ///      This function is essential for keeping the price data current.
    /// @param priceUpdateData The data required to update the price
    function updatePrice(bytes[] calldata priceUpdateData) external payable {
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        PythStructs.Price memory updatedPrice = pyth.getPriceUnsafe(priceId);
        emit PriceUpdated(
            updatedPrice.price,
            updatedPrice.conf,
            updatedPrice.expo,
            updatedPrice.publishTime
        );
    }
}
