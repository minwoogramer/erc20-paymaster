// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TwapPyth is Ownable {
    IPyth public immutable pyth;
    bytes32 public immutable priceId;
    uint32 public twapInterval;
    uint32 public maxPriceAge;

    /// @notice Struct to store price observations
    /// @param price The price value
    /// @param timestamp The timestamp of the observation
    struct PriceObservation {
        int64 price;
        uint64 timestamp;
    }

    PriceObservation[] private priceHistory;
    uint256 private constant MAX_PRICE_HISTORY = 24;
    uint256 private constant PRICE_PRECISION = 1e8;

    event PriceUpdated(int64 price, uint64 timestamp);
    event TwapIntervalUpdated(uint32 newInterval);
    event MaxPriceAgeUpdated(uint32 newMaxAge);

    error InvalidPrice();
    error PriceStale();
    error InsufficientPriceData();

    /// @notice Constructor to initialize the contract
    /// @param _pyth Address of the Pyth contract
    /// @param _priceId Pyth price feed identifier
    /// @param _twapInterval Time interval for TWAP calculation
    /// @param _maxPriceAge Maximum allowed age of price data
    constructor(
        address _pyth,
        bytes32 _priceId,
        uint32 _twapInterval,
        uint32 _maxPriceAge
    ) Ownable(msg.sender) {
        pyth = IPyth(_pyth);
        priceId = _priceId;
        twapInterval = _twapInterval;
        maxPriceAge = _maxPriceAge;
    }

    /// @notice Get the latest price
    /// @return The latest price from the price history
    function getPrice() public view returns (int64) {
        if (priceHistory.length == 0) revert InvalidPrice();
        return priceHistory[priceHistory.length - 1].price;
    }

    /// @notice Calculate the time-weighted average price (TWAP)
    /// @return The calculated TWAP
    function getTwapPrice() public view returns (int64) {
        uint256 length = priceHistory.length;
        if (length == 0) revert InsufficientPriceData();

        uint256 startTime = block.timestamp - twapInterval;
        int256 cumulativeTimeWeightedPrice;
        uint256 totalTime;

        unchecked {
            for (uint256 i = length - 1; i > 0; i--) {
                PriceObservation memory current = priceHistory[i];
                PriceObservation memory prev = priceHistory[i - 1];

                if (current.timestamp <= startTime) break;

                uint256 timeWeight = current.timestamp -
                    (prev.timestamp > startTime ? prev.timestamp : startTime);

                cumulativeTimeWeightedPrice +=
                    int256(current.price) *
                    int256(timeWeight);
                totalTime += timeWeight;
            }
        }

        if (totalTime == 0) revert InsufficientPriceData();

        int256 twapPrice = cumulativeTimeWeightedPrice / int256(totalTime);

        require(
            twapPrice >= type(int64).min && twapPrice <= type(int64).max,
            "TWAP price out of int64 range"
        );
        return int64(twapPrice);
    }

    /// @notice Update the price using Pyth Network data
    /// @param priceUpdateData The price update data from Pyth Network
    function updatePrice(bytes[] calldata priceUpdateData) external payable {
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        PythStructs.Price memory updatedPrice = pyth.getPriceUnsafe(priceId);
        if (updatedPrice.publishTime + maxPriceAge < block.timestamp)
            revert PriceStale();

        uint64 timestamp = uint64(updatedPrice.publishTime);
        if (
            priceHistory.length == 0 ||
            timestamp > priceHistory[priceHistory.length - 1].timestamp
        ) {
            if (priceHistory.length >= MAX_PRICE_HISTORY) {
                for (uint256 i = 1; i < priceHistory.length; i++) {
                    priceHistory[i - 1] = priceHistory[i];
                }
                priceHistory[priceHistory.length - 1] = PriceObservation(
                    updatedPrice.price,
                    timestamp
                );
            } else {
                priceHistory.push(
                    PriceObservation(updatedPrice.price, timestamp)
                );
            }
            emit PriceUpdated(updatedPrice.price, timestamp);
        }
    }

    /// @notice Set a new TWAP interval
    /// @param _twapInterval New TWAP interval value
    function setTwapInterval(uint32 _twapInterval) external onlyOwner {
        twapInterval = _twapInterval;
        emit TwapIntervalUpdated(_twapInterval);
    }

    /// @notice Set a new maximum price age
    /// @param _maxPriceAge New maximum price age value
    function setMaxPriceAge(uint32 _maxPriceAge) external onlyOwner {
        maxPriceAge = _maxPriceAge;
        emit MaxPriceAgeUpdated(_maxPriceAge);
    }
}
