// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ProfitShare is ReentrancyGuard {
    uint256 public investmentFund;
    uint256 public lastRecordedFund;
    uint256 public profit;
    address public marketingWallet;
    address public owner;
    uint256 public lastDistribution;
    uint256 public distributionInterval = 30 days;

    mapping(address => uint256) public profitsShare;
    mapping(address => uint256) public reinvestedShare;

    event ProfitsDistributed(uint256 tokenHoldersShare, uint256 retainedShare, uint256 marketingShare);
    event Reinvested(address indexed investor, uint256 amount);

    constructor() {
        owner = msg.sender;
        lastDistribution = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier canDistribute() {
        require(block.timestamp >= lastDistribution + distributionInterval, "Distribution not allowed yet");
        _;
    }

    function recordInitialFund() public onlyOwner {
        lastRecordedFund = investmentFund;
    }

    function calculateMonthlyProfit() public onlyOwner {
        profit = investmentFund - lastRecordedFund;
    }

    function distributeProfits() public onlyOwner nonReentrant canDistribute {
        uint256 tokenHoldersShare = (profit * 75) / 100;
        uint256 retainedShare = (profit * 15) / 100;
        uint256 marketingShare = (profit * 10) / 100;

        // distributeShare(tokenHoldersShare);

        investmentFund += retainedShare;
        // payable(marketingWallet).transfer(marketingShare);

        emit ProfitsDistributed(tokenHoldersShare, retainedShare, marketingShare);
        lastDistribution = block.timestamp;
    }

    function reinvest(uint8 percentage) public nonReentrant {
        require(percentage > 0 && percentage <= 100, "Invalid percentage");
        uint256 share = profitsShare[msg.sender];
        require(share > 0, "No profits to reinvest");

        uint256 reinvestAmount = (share * percentage) / 100;
        require(reinvestAmount > 0, "Reinvestment amount too small");

        reinvestedShare[msg.sender] += reinvestAmount;
        profitsShare[msg.sender] -= reinvestAmount;
        investmentFund += reinvestAmount;

        emit Reinvested(msg.sender, reinvestAmount);
    }

    // Other necessary functions
}
