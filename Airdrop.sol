//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PRAI.sol";

contract Airdrop {
    address public owner;
    ProfitrocketAI public profitrocketAIContract;

    uint256 public constant AIRDROP_AMOUNT = 1000 * 10 ** 18;
    uint256 public constant REFERRAL_BONUS = 5000 * 10 ** 18;
    uint256 public constant MAX_REFERRALS = 25;

    mapping(address => bool) public airdropped;
    mapping(address => address) public referrers;
    mapping(address => uint256) public referralCount;

    event Airdropped(address indexed recipient, uint256 amount);
    event ReferralBonus(address indexed referrer, address indexed recipient, uint256 amount);

    constructor(ProfitrocketAI _profitrocketAIContract) {
        profitrocketAIContract = _profitrocketAIContract;
        owner = msg.sender;
    }

    function airdrop() external {
        require(!airdropped[msg.sender], "Already airdropped");
        airdropped[msg.sender] = true;
        profitrocketAIContract.transfer(msg.sender, AIRDROP_AMOUNT);
        emit Airdropped(msg.sender, AIRDROP_AMOUNT);
    }

    function refer(address _referrer) external {
        require(_referrer != msg.sender, "Cannot refer yourself");
        require(!airdropped[msg.sender], "Already airdropped");
        require(referralCount[_referrer] < MAX_REFERRALS, "Referrer has reached maximum referrals");
        airdropped[msg.sender] = true;
        referrers[msg.sender] = _referrer;
        referralCount[_referrer]++;
        profitrocketAIContract.transfer(msg.sender, AIRDROP_AMOUNT);
        emit Airdropped(msg.sender, AIRDROP_AMOUNT);
        if (referralCount[_referrer] == MAX_REFERRALS) {
            profitrocketAIContract.transfer(_referrer, REFERRAL_BONUS);
            emit ReferralBonus(_referrer, msg.sender, REFERRAL_BONUS);
        }
    }
}