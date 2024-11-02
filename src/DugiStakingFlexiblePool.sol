// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardVault.sol";

contract FlexibleStakingPool is Ownable {
    IERC20 public token;
    RewardVault public rewardVault;


     address public stakingAdmin = 0xbf68cAc8e8fFB705B3DEEd70487BBD054bCE11C6;

    uint256 public constant MINIMUM_STAKE = 100 * 10**18; 
    uint256 public constant MAX_LOCKING_PERIOD = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
    uint256 public constant ANNUAL_REWARD_RATE = 10 * 10**16; // 10% per annum
    uint256 public constant PENALTY_RATE = 20; // 20% penalty for early unstake

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake[]) public stakes;
    uint256 public totalStakingAmount;

    event Staked(address indexed user, uint256 amount, uint256 stakingSlot);
    event Unstaked(address indexed user, uint256 amount, uint256 stakingSlot, uint256 penalty, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);

      constructor(IERC20 _token, RewardVault _rewardVault) Ownable(stakingAdmin) { 
        token = _token;
        rewardVault = _rewardVault;
    }


    modifier hasMinimumStake(uint256 amount) {
        require(amount >= MINIMUM_STAKE, "Minimum stake required");
        _;
    }

    function stake(uint256 amount) external hasMinimumStake(amount) {
        require(rewardVault.checkRewardReserveHealth() == RewardVault.RewardReserveStatus.Healthy, "Reward reserve is insufficient");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        stakes[msg.sender].push(Stake(amount, block.timestamp));
        totalStakingAmount += amount;
        emit Staked(msg.sender, amount, stakes[msg.sender].length - 1);
    }

    function unstake(uint256 stakingSlot) external {
        require(stakingSlot < stakes[msg.sender].length, "Invalid staking slot");
        Stake memory userStake = stakes[msg.sender][stakingSlot];
        require(userStake.amount > 0, "No staked amount");

        uint256 reward = calculateReward(userStake.amount, userStake.startTime);
        uint256 penalty = 0;
        uint256 totalAmount = userStake.amount + reward;

        if (block.timestamp < userStake.startTime + MAX_LOCKING_PERIOD) {
            penalty = (userStake.amount * PENALTY_RATE) / 100;
            totalAmount -= penalty;
        }

        delete stakes[msg.sender][stakingSlot];
        totalStakingAmount -= userStake.amount;

        require(token.transfer(msg.sender, totalAmount), "Token transfer failed");
        emit Unstaked(msg.sender, userStake.amount, stakingSlot, penalty, reward);
    }

    function claimReward(uint256 stakingSlot) external {
        require(stakingSlot < stakes[msg.sender].length, "Invalid staking slot");
        Stake memory userStake = stakes[msg.sender][stakingSlot];
        require(userStake.amount > 0, "No staked amount");

        uint256 reward = calculateReward(userStake.amount, userStake.startTime);
        userStake.startTime = block.timestamp; // Reset start time after claiming reward

        require(token.transfer(msg.sender, reward), "Token transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(uint256 amount, uint256 startTime) public view returns (uint256) {
        uint256 stakingDuration = block.timestamp - startTime;
        uint256 rewardRatePerSecond = ANNUAL_REWARD_RATE / (365 * 24 * 60 * 60);
        return (amount * rewardRatePerSecond * stakingDuration) / 10**18;
    }

    function getStakes(address staker) external view returns (Stake[] memory) {
        return stakes[staker];
    }
}