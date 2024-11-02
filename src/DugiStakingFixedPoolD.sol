pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardVault.sol";


contract DugiStakingFixedPoolD is Ownable {
   
    IERC20 public token;
    RewardVault public rewardVault;

    address public stakingAdmin = 0xbf68cAc8e8fFB705B3DEEd70487BBD054bCE11C6;

    

    uint256 public constant MINIMUM_STAKE = 100 * 10**18; 

    uint256 public constant LOCKING_PERIOD_EIGHT_YEARS = 8 * 365 * 24 * 60 * 60; // 8 years in seconds

    uint256 public constant REWARD_RATE_FOR_EIGHT_YEAR =  8*25 * 10**16; // 25% annual rate total of (25*8) 200% of staked token after 8 years
  


    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 stakingSlot;
        uint256 reward;

    }

    uint256 public totalStakingAmount;
    uint256 public totalPoolReward;
    uint256 public totalStakers;
 


   
    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public stakingSlotCounter;


    event Staked(address indexed user, uint256 amount, uint256 stakingSlot);
    event Unstaked(address indexed user, uint256 amount, uint256 stakingSlot);

    constructor(IERC20 _token, RewardVault _rewardVault) Ownable(stakingAdmin) { 
        token = _token;
        rewardVault = _rewardVault;
    }

    modifier hasMinimumStake(uint256 amount) {
        require(amount >= MINIMUM_STAKE, "Minimum stake required");
        _;
    }


        function stakeForEightYears(uint256 amount) external hasMinimumStake(amount) {
        require(rewardVault.checkRewardReserveHealth() == RewardVault.RewardReserveStatus.Healthy, "Reward reserve is insufficient");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        stakingSlotCounter[msg.sender]++;
        uint256 stakingSlot = stakingSlotCounter[msg.sender];
        uint256 reward = LOCKING_PERIOD_EIGHT_YEARS * REWARD_RATE_FOR_EIGHT_YEAR * amount ;
        totalStakingAmount += amount;
        totalPoolReward += reward;
        totalStakers += 1;
        stakes[msg.sender].push(Stake(amount, block.timestamp, stakingSlot ,reward));
        emit Staked(msg.sender, amount, stakingSlot);
    }





    function unstakeFromEightYears(uint256 index) external {
        Stake memory userStake = stakes[msg.sender][index];
        require(userStake.amount > 0, "No staked amount");
        require(block.timestamp >= userStake.startTime + LOCKING_PERIOD_EIGHT_YEARS, "Locking period not over");
        uint256 rewardToBeCollected = userStake.reward;
        uint256 totalAmountToBeCollected = userStake.amount + rewardToBeCollected;
        uint256 stakingSlot = userStake.stakingSlot;
        delete stakes[msg.sender][index];
        totalStakingAmount -= userStake.amount;
        totalPoolReward -= rewardToBeCollected;
        totalStakers -= 1;
        require(token.transfer(msg.sender, totalAmountToBeCollected), "Token transfer failed");
        emit Unstaked(msg.sender, totalAmountToBeCollected, stakingSlot);
    }



}
