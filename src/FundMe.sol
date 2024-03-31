// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] private funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    address private immutable owner;

    constructor(address priceFeed){
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }
    // fund wallet
    function fund() public payable {
        // Allow users to send $
        // Have a minimum sendable amount of $5
        // How do we send Eth to this account
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didnt send enough eth"); // 1e18 = 1 Eth = 1000000000000000000 = 1* 10 ** 18
        funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;

        // What is a revert ?
        // Undo any actions that have been done, and send the remaining gas back

    }

    function getVersion() public view returns(uint256){
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner() {
        uint256 fundersLength = funders.length;
        for(uint256 fundersIndex = 0; fundersIndex < fundersLength; fundersIndex++){
            address funder = funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }
    

    // withdraw. from wallet
    function withdraw() public onlyOwner {
        require(msg.sender == owner, "must be owner");
        for (uint256 fundersIndex = 0; fundersIndex < funders.length; fundersIndex++) 
        {
            address funder = funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);
        // withdraw the fund
        // 1. Transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // 2. send 
        // bool sendSuccess = payable (msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // 3. call
        (bool callSuccess, ) =payable (msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }


    modifier onlyOwner(){
        // require(msg.sender == owner, "Sender is not owner");
        if(msg.sender != owner) {revert NotOwner();}
            _;
    }

    receive() external payable {
        fund();
     }

     fallback() external payable { 
        fund();
     }
// 
//   View / Pure functions (Getters)
//      


function getAddressToAmountFunded(address fundingAddress) external view returns(uint256){
    return s_addressToAmountFunded[fundingAddress];
}

function getFunder(uint256 index) external view returns(address){
    return funders[index];
}

function getOwner() external view returns(address){
    return owner;
}

}