// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseScript} from "./Base.s.sol";
import {ERC20PaymasterV06} from "../src/ERC20PaymasterV06.sol";
import {IERC20Metadata} from "@openzeppelin-v5.0.0/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IOracle as IOracleChainlink} from "src/interfaces/oracles/IOracle.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    function run() public broadcast returns (ERC20PaymasterV06 paymaster) {
        /**
         * IERC20Metadata _token,
        address _entryPoint,
        IOracle _tokenOracle,
        IOracle _nativeAssetOracle,
        uint32 _stalenessThreshold,
        address _owner,
        uint32 _priceMarkupLimit,
        uint32 _priceMarkup,
        uint256 _refundPostOpCost,
        uint256 _refundPostOpCostWithGuarantor
         */
        // paymaster = new ERC20PaymasterV06(
        //     IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F),
        //     address(0x0),
        //     IOracleChainlink(0x6982508145454CEB08aead3b439187C6eb551AEF),
        //     IOracleChainlink(0x6982508145454CEB08aead3b439187C6eb551AEF),
        //     0,
        //     address(0x0),
        //     0,
        //     0,
        //     0,
        //     0
        // );
    }
}
