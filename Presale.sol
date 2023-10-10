// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Presale {
    ERC20 public token;
    uint public investmentFundTax;
    uint public marketingTax;

    enum Phase {
        Phase1,
        Phase2,
        Phase3
    }

    uint256 public startTime;
    uint256 public endTime;
    Phase public currentPhase;

    mapping(Phase => uint256) public phasePrice;
    mapping(Phase => uint256) public phaseTokensForSale;

    constructor(
        ERC20 _token,
        uint256 _startTime,
        uint256 _endTime
    ) {
        token = _token;
        startTime = _startTime;
        endTime = _endTime;
        currentPhase = Phase.Phase1;
        investmentFundTax = 8;
        marketingTax = 2;

        phasePrice[Phase.Phase1] = 0.0085 ether;
        phaseTokensForSale[Phase.Phase1] = 65_000_000 * 10**18;

        phasePrice[Phase.Phase2] = 0.0099 ether;
        phaseTokensForSale[Phase.Phase2] = 100_125_000 * 10**18;

        phasePrice[Phase.Phase3] = 0.0125 ether;
        phaseTokensForSale[Phase.Phase3] = 160_000_000 * 10**18;
    }

    function calculateTotalAmount(uint amount) public view returns (uint) {
        uint investmentFundAmount = (amount * investmentFundTax) / 100;
        uint marketingAmount = (amount * marketingTax) / 100;

        uint totalAmount = amount + investmentFundAmount + marketingAmount;
        return totalAmount;
    }

    function buyTokens() external payable {
        require(isActive(), "Presale is not active");

        uint256 currentPrice = phasePrice[currentPhase];
        uint256 currentTokensForSale = phaseTokensForSale[currentPhase];

        require(msg.value >= currentPrice, "Not enough ETH sent");

        uint256 tokens = msg.value / currentPrice;

        require(tokens <= currentTokensForSale, "Not enough tokens left for sale");

        token.transfer(msg.sender, tokens);

        phaseTokensForSale[currentPhase] -= tokens;

        updatePhase();
    }

    function updatePhase() internal {
        if (currentPhase == Phase.Phase1 && phaseTokensForSale[currentPhase] == 0) {
            currentPhase = Phase.Phase2;
        } else if (currentPhase == Phase.Phase2 && phaseTokensForSale[currentPhase] == 0) {
            currentPhase = Phase.Phase3;
        }
    }

    function isActive() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function getCurrentPhase() public view returns (Phase) {
        return currentPhase;
    }

    function getPrice() public view returns (uint256) {
        return phasePrice[currentPhase];
    }

    function getTokensForSale() public view returns (uint256) {
        return phaseTokensForSale[currentPhase];
    }
}