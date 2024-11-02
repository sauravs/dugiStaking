// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
// forge test --match-path test/RewardVault.t.sol --via-ir
import "forge-std/Test.sol";
import "../src/RewardVault.sol";
import "../src/DugiStakingFixedPoolA.sol";
import "../src/DugiStakingFixedPoolB.sol";
import "../src/DugiStakingFixedPoolC.sol";
import "../src/DugiStakingFixedPoolD.sol";
import "../src/MockDUGIToken.sol";

contract RewardVaultTest is Test {
    RewardVault rewardVault;
    MockDUGIToken dugiToken;
    DugiStakingFixedPoolA stakingPoolA;
    DugiStakingFixedPoolB stakingPoolB;
    DugiStakingFixedPoolC stakingPoolC;
    DugiStakingFixedPoolD stakingPoolD;

    address vaultAdmin = address(0x999);
    address nonOwner = address(0x888);
    address newVaultAdmin = address(0x777);
    address public stakingAdmin = address(0xbf68cAc8e8fFB705B3DEEd70487BBD054bCE11C6);
 

    function setUp() public {
        dugiToken = new MockDUGIToken();
        rewardVault = new RewardVault(dugiToken, vaultAdmin);

        stakingPoolA = new DugiStakingFixedPoolA(dugiToken, rewardVault);
        stakingPoolB = new DugiStakingFixedPoolB(dugiToken, rewardVault);
        stakingPoolC = new DugiStakingFixedPoolC(dugiToken, rewardVault);
        stakingPoolD = new DugiStakingFixedPoolD(dugiToken, rewardVault);
        
        vm.prank(vaultAdmin);
        rewardVault.setStakingPools(stakingPoolA, stakingPoolB, stakingPoolC, stakingPoolD);

        // mint 1000000000000 DUGI tokens to the vaultAdmin

        dugiToken.mint(vaultAdmin, 1000000000000 * 10**18);
        assertEq(dugiToken.balanceOf(vaultAdmin), 1000000000000 * 10**18);
    }

    function testUpdateVaultAdmin() public {
        vm.prank(stakingAdmin);
        rewardVault.updateVaultAdmin(newVaultAdmin);
        assertEq(rewardVault.vaultAdmin(), newVaultAdmin);
    }

    function testUpdateVaultAdminFailNotAuthorized() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        rewardVault.updateVaultAdmin(newVaultAdmin);
    }

    function testDepositRewards() public {
        uint256 amount = 100000 * 10**18;
        vm.prank(vaultAdmin);
        dugiToken.approve(address(rewardVault), amount);
        vm.prank(vaultAdmin);
        rewardVault.depositRewards(amount);
        assertEq(rewardVault.rewardReserve(), amount);
    }

    function testDepositRewardsFailNotAuthorized() public {
        uint256 amount = 1000 * 10**18;
        vm.prank(nonOwner);
        vm.expectRevert("Only vaultadmin allowed");
        rewardVault.depositRewards(amount);
    }

      function testGetLiability() public {

        // check rewardReserve is 0
        assertEq(rewardVault.rewardReserve(), 0);
        // Assuming the totalPoolReward functions return 0 initially
        assertEq(rewardVault.getLiability(), 0);
    }

 
     function testCheckRewardReserveHealth() public {
        uint256 amount = 100000 * 10**18;
        vm.prank(vaultAdmin);        
        dugiToken.approve(address(rewardVault), amount);
        vm.prank(vaultAdmin);        
        rewardVault.depositRewards(amount);
        assertEq(rewardVault.rewardReserve(), amount);
        assertEq(rewardVault.getLiability(), 0);
        vm.prank(vaultAdmin);        
        rewardVault.updateExtraReserve(1000 * 10**18); // Set EXTRA_RESERVE to a value that makes rewardReserve > liability + EXTRA_RESERVE
        assertEq(uint(rewardVault.checkRewardReserveHealth()), uint(RewardVault.RewardReserveStatus.Healthy));
    }

    function testWithdrawRewards() public {
        uint256 amount = 100000 * 10**18;
        vm.prank(vaultAdmin);
        dugiToken.approve(address(rewardVault), amount);
        vm.prank(vaultAdmin);
        rewardVault.depositRewards(amount);
        assertEq(rewardVault.rewardReserve(), amount);
        vm.prank(vaultAdmin);
        rewardVault.withdrawRewards(amount);
        assertEq(rewardVault.rewardReserve(), 0);
    }
    
}