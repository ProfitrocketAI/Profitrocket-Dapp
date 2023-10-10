// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract Staking is ERC20 {
    struct StakingInfo {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 reward;
        uint256 lastUpdateTime;
    }

    uint256 public constant LOCK_IN_PERIOD = 30 days;
    uint256 public constant REWARD_RATE = 7; // 7% per year
    uint256 public constant STAKING_REWARDS_SUPPLY = 70_000_000; // 70 million PRAI tokens for staking rewards
    uint256 public totalRewardsDistributed = 0; // Total rewards distributed

    mapping(address => StakingInfo) public stakes;
    mapping(address => uint256) public rewards;
    address[] public stakers;

    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);
    event Withdrawn(address indexed user, uint256 amount, uint256 total);
    event RewardPaid(address indexed user, uint256 reward);

    constructor() ERC20("ProfitRocket AI Staking", "PRAI-S") {}

    function stake(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");
    // Check if the user is already a staker, if not, add to stakers array
    if (stakes[msg.sender].amount == 0) {
        stakers.push(msg.sender);
    } else {
        // If the user is already a staker, check if they are in a lock-in period
        require(block.timestamp >= stakes[msg.sender].endTime, "You are currently in a lock-in period");
    }
  
    stakes[msg.sender].amount += amount;
    stakes[msg.sender].startTime = block.timestamp;
    stakes[msg.sender].endTime = block.timestamp + LOCK_IN_PERIOD;
    _transfer(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount, stakes[msg.sender].amount);
}

    function withdraw(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");
    require(stakes[msg.sender].amount >= amount, "Insufficient staked amount");
    require(block.timestamp >= stakes[msg.sender].endTime, "Tokens are still locked");

    stakes[msg.sender].amount -= amount;
    if (stakes[msg.sender].amount == 0) {
        // Remove the staker from the stakers array if they have no more staked tokens
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == msg.sender) {
                stakers[i] = stakers[stakers.length - 1];
                stakers.pop();
                break;
            }
        }
    }

    _transfer(address(this), msg.sender, amount);
    emit Unstaked(msg.sender, amount, stakes[msg.sender].amount);
}

    function claimRewards() external {
        uint256 reward = rewards[msg.sender];
        require(totalRewardsDistributed + (reward) <= STAKING_REWARDS_SUPPLY, "Not enough tokens left for rewards");

        rewards[msg.sender] = 0;
        totalRewardsDistributed = totalRewardsDistributed + (reward);

        _transfer(address(this), msg.sender, reward);

        emit RewardPaid(msg.sender, reward);
    }
    function updateRewards() external {
        uint256 totalStaked = totalSupply();
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 stakedAmount = stakes[staker].amount;
            if (stakedAmount == 0) continue;
            uint256 timeElapsed = block.timestamp - stakes[staker].lastUpdateTime;
            stakes[staker].reward += stakedAmount * timeElapsed * REWARD_RATE / totalStaked;
            stakes[staker].lastUpdateTime = block.timestamp;
        }
    }
}
