// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./priceConverter.sol";

error fundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] private s_funders; // private variables are more gas efficient
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        // constructor is a special keyword in solidity. while deploying it will sets the msg.sender = owner
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // allow users to send money
        // have a minimum $ sent
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didnt send enough eth"); // 1e18 = 1000000000000000000 = 1 * 10 ** 18
        //what is revert ? undo any action that have been done and send the remaining gas back
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return s_priceFeed.version();
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner,"Must be a Owner!"); // = is used for set ; == is used for equal to in solidity
        // for loop
        // [1, 2, 3, 4] elements
        //  0, 1, 2, 3  indexes
        // for (starting index; ending index; step amount)

        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // actually withdraw the funds
        /*
        How to send Ether?
        You can send Ether to other contracts by

        transfer (2300 gas, throws error)
        send (2300 gas, returns bool)
        call (forward all gas or set gas, returns bool)
        */
        // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require (sendSuccess, "send failed");
        // call is the mose convenient way to withdraw money; if it is confusing try with ai
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "sender is not Owner!");
        if (msg.sender != i_owner) {
            revert fundMe__NotOwner();
        }
        _; // this means execute the following lines in the function after the require
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
