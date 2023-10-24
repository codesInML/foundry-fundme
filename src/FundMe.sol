// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    uint private constant MINIMUM_USD = 5e18;
    using PriceConverter for uint;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    address[] private s_funders;
    mapping(address funder => uint amountFunded)
        private s_addressToAmountFunded;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function withdraw() public restricted {
        for (
            uint funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier restricted() {
        // require(msg.sender == i_owner, "Sender is not the owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * View / Pure functions (Getters)
     */

    function getVersion() public view returns (uint) {
        return s_priceFeed.version();
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getMinimumUSD() public pure returns (uint) {
        return MINIMUM_USD;
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint index) external view returns (address) {
        return s_funders[index];
    }
}
