//Get funds from users
//withdraw funds
//set a min funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error FundMe_NotOwner(); // to reduce gas

// to reduce gas ---> constant , immutable

import { PriceConverter } from "./PriceConverter.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    // non-constant gas > constant gas
    // uint256 public minimumUSD = 5e18; > uint256 public constant minimumUSD = 5e18;
    uint256 public constant minimumUSD = 5e18;

    address[] public s_funders;

    mapping (address funder => uint256 amountFunded) public s_addressToAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        //msg.value.getConversionRate(); //getConversionRate(uint256 msg.value)
        //allow users to send $
        //have a min $ sent
        // 1. how do we send ETH to this contract
        require(msg.value.getConversionRate(s_priceFeed) >= minimumUSD, "didn't send enough ETH !");//number of wei sent with the msg /1e18 = 1ETH
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;

        //what is a revert ?
        //---> undo any actions that have been done, and send the remaining gas back
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 i = 0; i < fundersLength; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOwner {
        //require(msg.sender == owner, "Sender should be owner !");
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0; //initialiser à 0

        }

        s_funders = new address[](0);//reset the array
        //withdraw the funds

        //transfer
        // msg.sender --> type = address
        // payable(msg.sender) --> type = payable address
        //payable(msg.sender).transfer(address(this).balance); // (this) refers to the whole contract

        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send Failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        //execute the condition then the rest of the code
        //require(msg.sender == i_owner, "Sender should be owner !");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;

        //execute the code then the condition
        //_;
        //require(msg.sender == owner, "Sender should be owner !");
    }

    /*function getVersion() public  view returns (uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }*/
   function getVersion() public  view returns (uint256) {
        return s_priceFeed.version();
    }


    // special functions ----> receive() , fallback()
    receive() external payable { 
        fund();
    }

    fallback() external payable { 
        fund();
    }

    /*
     * view / pure functions --> getters 
     */
    function getAddressToAmountFunded (address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner; 
    }

}