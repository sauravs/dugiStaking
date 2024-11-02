// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// forge test --match-path test/DugiStakeFixedA.t.sol --via-ir
// forge test --match-path test/DugiStakeFixedA.t.sol -vvv
import "forge-std/Test.sol";
import "../src/DugiStakingFixedPoolA.sol";
import "../src/RewardVault.sol";
import "../src/MockDUGIToken.sol";

contract DugiStakingFixedTest is Test {
    DugiStakingFixedPoolA stakingPoolA;
    RewardVault rewardVault;
    MockDUGIToken dugiToken ;
   
    address vaultAdmin = address(0x999);
    address public stakingAdmin = address(0xbf68cAc8e8fFB705B3DEEd70487BBD054bCE11C6);


    address public staker1 = address(0x789);
    address public staker2 = address(0xabc);
    address public staker3 = address(0xdef);
    address public staker4 = address(0x1234);


    function setUp() public {
    
    dugiToken = new MockDUGIToken();
    rewardVault = new RewardVault(dugiToken , vaultAdmin);
    stakingPoolA = new DugiStakingFixedPoolA(dugiToken, rewardVault);


    
         // mint 100000000000 tokens to vaultAdmin
        dugiToken.mint(vaultAdmin, 100000000000 * 10**18);
        // assert that the balance of vaultAdmin has 100000000000
        assertEq(dugiToken.balanceOf(vaultAdmin), 100000000000 * 10**18);


          // mint 100000 tokens to staker1 , staker2, staker3, staker4

        dugiToken.mint(staker1, 100000 * 10**18);
        dugiToken.mint(staker2, 100000 * 10**18);
        dugiToken.mint(staker3, 100000 * 10**18);
        dugiToken.mint(staker4, 100000 * 10**18);

        
        
        // assert that the balance of staker1, staker2, staker3, staker4 is 100000
        assertEq(dugiToken.balanceOf(staker1), 100000 * 10**18);
        assertEq(dugiToken.balanceOf(staker2), 100000 * 10**18);
        assertEq(dugiToken.balanceOf(staker3), 100000 * 10**18);
        assertEq(dugiToken.balanceOf(staker4), 100000 * 10**18);


              // top up the reward vault
        
        vm.startPrank(vaultAdmin);
        dugiToken.approve(address(rewardVault), type(uint256).max);
        vm.startPrank(vaultAdmin);
        rewardVault.depositRewards(100000 * 10**18);
        vm.stopPrank();

        // check the reward reserve
        assertEq(rewardVault.rewardReserve(), 100000 * 10**18);




    }

    
    function testConstructor() public {
        assertEq(address(stakingPoolA.token()), address(dugiToken));
        assertEq(address(stakingPoolA.rewardVault()), address(rewardVault));
        assertEq(stakingPoolA.stakingAdmin(), stakingAdmin);
        assertEq(stakingPoolA.MINIMUM_STAKE(), 100 * 10**18);
        assertEq(stakingPoolA.LOCKING_PERIOD_TWO_YEARS(), 2 * 365 * 24 * 60 * 60);
        assertEq(stakingPoolA.REWARD_RATE_FOR_TWO_YEAR(), 2*10 * 10**16);
        assertEq(stakingPoolA.owner(), stakingAdmin);

    }

     function testStake() public {
        uint256 amount = 2000 * 10**18; // 2000 tokens
        uint256 initialBalance = dugiToken.balanceOf(staker1);

        // Approve the staking contract to spend tokens on behalf of the user
        vm.prank(staker1);
        dugiToken.approve(address(stakingPoolA), amount);

        // Deposit rewards into the reward vault
        vm.prank(vaultAdmin);
        dugiToken.approve(address(rewardVault), amount * 10); // Approve a large amount for reward deposit
        vm.prank(vaultAdmin);
        rewardVault.depositRewards(amount * 10); // Deposit a large amount to ensure sufficient reward reserve

        // Stake tokens
        vm.prank(staker1);
        stakingPoolA.stakeForTwoYears(amount);

        // Check if the tokens were transferred to the staking contract
        uint256 finalBalance = dugiToken.balanceOf(staker1);
        assertEq(finalBalance, initialBalance - amount, "Tokens were not transferred correctly");

        // Check if the stake was recorded correctly
        (uint256 stakedAmount, uint256 startTime, uint256 stakingSlot ,uint256 reward) = stakingPoolA.stakes(staker1, 0);
        assertEq(stakedAmount, amount, "Staked amount is incorrect");
        assertGt(startTime, 0, "Start time is incorrect");
        assertEq(stakingSlot, 1, "Staking slot is incorrect");
        assertEq(stakingPoolA.totalStakingAmount(), amount, "Total staking amount is incorrect");


        // stake tokens again by staker1 again of 4000 tokens 

        uint256 amount2 = 4000 * 10**18; // 4000 tokens
        uint256 initialBalance2 = dugiToken.balanceOf(staker1);

        // Approve the staking contract to spend tokens on behalf of the user
        vm.prank(staker1);
        dugiToken.approve(address(stakingPoolA), amount2);

        // Deposit rewards into the reward vault
        vm.prank(vaultAdmin);
        dugiToken.approve(address(rewardVault), amount2 * 10); // Approve a large amount for reward deposit
        vm.prank(vaultAdmin);
        rewardVault.depositRewards(amount2 * 10); // Deposit a large amount to ensure sufficient reward reserve

        // Stake tokens

        vm.prank(staker1);
        stakingPoolA.stakeForTwoYears(amount2);

        // Check if the tokens were transferred to the staking contract
        uint256 finalBalance2 = dugiToken.balanceOf(staker1);
        assertEq(finalBalance2, initialBalance2 - amount2, "Tokens were not transferred correctly");

        // Check if the stake was recorded correctly

        (uint256 stakedAmount2, uint256 startTime2, uint256 stakingSlot2 , uint256 reward2) = stakingPoolA.stakes(staker1, 1);
        assertEq(stakedAmount2, amount2, "Staked amount is incorrect");

        assertGt(startTime2, 0, "Start time is incorrect");
        assertEq(stakingSlot2, 2, "Staking slot is incorrect");
        assertEq(stakingPoolA.totalStakingAmount(), amount + amount2, "Total staking amount is incorrect");

    }



}