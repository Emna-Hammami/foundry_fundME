// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal  view returns(uint256) {
        //we need 2 things -> address + ABI
        // 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI is a list of functions that we can call in a contract
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //(uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint8 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price,,,) = priceFeed.latestRoundData();//we need only price
        //price of ETH in terms of USD 
        return uint256(price * 1e10);

    }
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal  view returns (uint256) {
        // msg.value.getConversionRate;
        uint256 ethPrice = getPrice(priceFeed);
        //in solidity you should multiply first then you can divide
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }

    

}