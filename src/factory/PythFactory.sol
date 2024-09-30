// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Import Pyth oracle implementations
import {FixedPyth} from "./../pyth/FixedPyth.sol";
import {ManualPyth} from "./../pyth/ManualPyth.sol";
import {TwapPyth} from "./../pyth/TwapPyth.sol";

// Import OpenZeppelin contracts
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title PythFactory
/// @notice A factory contract for deploying various Pyth oracle implementations
/// @dev This contract uses Create2 for deterministic address generation
contract PythFactory is Ownable {
    // Events for each type of oracle deployment
    event DeployedFixedPyth(
        bytes32 indexed salt,
        address indexed oracle,
        address pyth,
        bytes32 indexed priceId,
        uint32 maxPriceAge
    );

    event DeployedManualPyth(
        bytes32 indexed salt,
        address indexed oracle,
        address pyth,
        bytes32 indexed priceId
    );

    event DeployedTwapPyth(
        bytes32 indexed salt,
        address indexed oracle,
        address pyth,
        bytes32 indexed priceId,
        uint32 twapInterval,
        uint32 maxPriceAge
    );

    /// @notice Initializes the contract and sets the deployer as the owner
    constructor() Ownable(msg.sender) {}

    /// @notice Deploys a FixedPyth oracle
    /// @param salt The salt for Create2 deployment
    /// @param _pyth The address of the Pyth contract
    /// @param _priceId The price ID for the oracle
    /// @param _maxPriceAge The maximum age of the price data
    /// @return oracle The address of the deployed oracle
    function deployFixedPyth(
        bytes32 salt,
        address _pyth,
        bytes32 _priceId,
        uint32 _maxPriceAge
    ) external onlyOwner returns (address oracle) {
        bytes memory constructorArgs = abi.encode(
            _pyth,
            _priceId,
            _maxPriceAge
        );

        oracle = Create2.deploy(
            0,
            salt,
            abi.encodePacked(type(FixedPyth).creationCode, constructorArgs)
        );

        emit DeployedFixedPyth(salt, oracle, _pyth, _priceId, _maxPriceAge);
    }

    /// @notice Deploys a ManualPyth oracle
    /// @param salt The salt for Create2 deployment
    /// @param _pyth The address of the Pyth contract
    /// @param _priceId The price ID for the oracle
    /// @return oracle The address of the deployed oracle
    function deployManualPyth(
        bytes32 salt,
        address _pyth,
        bytes32 _priceId
    ) external onlyOwner returns (address oracle) {
        bytes memory constructorArgs = abi.encode(_pyth, _priceId);

        oracle = Create2.deploy(
            0,
            salt,
            abi.encodePacked(type(ManualPyth).creationCode, constructorArgs)
        );

        emit DeployedManualPyth(salt, oracle, _pyth, _priceId);
    }

    /// @notice Deploys a TwapPyth oracle
    /// @param salt The salt for Create2 deployment
    /// @param _pyth The address of the Pyth contract
    /// @param _priceId The price ID for the oracle
    /// @param _twapInterval The time-weighted average price interval
    /// @param _maxPriceAge The maximum age of the price data
    /// @return oracle The address of the deployed oracle
    function deployTwapPyth(
        bytes32 salt,
        address _pyth,
        bytes32 _priceId,
        uint32 _twapInterval,
        uint32 _maxPriceAge
    ) external onlyOwner returns (address oracle) {
        bytes memory constructorArgs = abi.encode(
            _pyth,
            _priceId,
            _twapInterval,
            _maxPriceAge
        );

        oracle = Create2.deploy(
            0,
            salt,
            abi.encodePacked(type(TwapPyth).creationCode, constructorArgs)
        );

        emit DeployedTwapPyth(
            salt,
            oracle,
            _pyth,
            _priceId,
            _twapInterval,
            _maxPriceAge
        );
    }
}
