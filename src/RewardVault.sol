// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DugiStakingFixedPoolA.sol";
import "./DugiStakingFixedPoolB.sol";
import "./DugiStakingFixedPoolC.sol";
import "./DugiStakingFixedPoolD.sol";

contract RewardVault is Ownable {
    IERC20 public token;
    
    DugiStakingFixedPoolA public stakingPoolA;
    DugiStakingFixedPoolB public stakingPoolB;
    DugiStakingFixedPoolC public stakingPoolC;
    DugiStakingFixedPoolD public stakingPoolD;

    uint256 public rewardReserve;
    uint256 public EXTRA_RESERVE = 10000 * 10**18;  //10000 DUGI

    address public vaultAdmin;
    address public stakingAdmin = 0xbf68cAc8e8fFB705B3DEEd70487BBD054bCE11C6;

    event RewardDeposited(uint256 amount);
    event RewardWithdrawn(uint256 amount);
    event ExtraReserveUpdated(uint256 amount);

    modifier onlyvaultAdmin() {
        require(msg.sender == vaultAdmin, "Only vaultadmin allowed");
        _;
    }

    enum RewardReserveStatus { Insufficient, Healthy }

    constructor(IERC20 _token, address _vaultAdmin) Ownable(stakingAdmin) {
        token = _token;
        vaultAdmin = _vaultAdmin;
    }

    // function to update the vaultAdmin by the owner
    function updateVaultAdmin(address _vaultAdmin) public onlyOwner {
        vaultAdmin = _vaultAdmin;
    }

    // function to update the EXTRA_RESERVE by the vaultAdmin
    function updateExtraReserve(uint256 amount) external onlyvaultAdmin {
        EXTRA_RESERVE = amount;
        emit ExtraReserveUpdated(amount);
    }

    function setStakingPools(
        DugiStakingFixedPoolA _stakingPoolA,
        DugiStakingFixedPoolB _stakingPoolB,
        DugiStakingFixedPoolC _stakingPoolC,
        DugiStakingFixedPoolD _stakingPoolD
    ) external onlyvaultAdmin {
        stakingPoolA = _stakingPoolA;
        stakingPoolB = _stakingPoolB;
        stakingPoolC = _stakingPoolC;
        stakingPoolD = _stakingPoolD;
    }

    function depositRewards(uint256 amount) external onlyvaultAdmin {
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        rewardReserve += amount;
        emit RewardDeposited(amount);
    }

    function withdrawRewards(uint256 amount) external onlyvaultAdmin {
        require(rewardReserve >= getLiability(), "Insufficient reward reserve");
        rewardReserve -= amount;
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit RewardWithdrawn(amount);
    }

    function getLiability() public view returns (uint256) {
        return stakingPoolA.totalPoolReward() + stakingPoolB.totalPoolReward() + stakingPoolC.totalPoolReward() + stakingPoolD.totalPoolReward();
    }

    function checkRewardReserveHealth() public view returns (RewardReserveStatus) {
        uint256 liability = getLiability();
        if (rewardReserve < liability) {
            return RewardReserveStatus.Insufficient;
        } else if (rewardReserve > liability + EXTRA_RESERVE) {
            return RewardReserveStatus.Healthy;
        }
        return RewardReserveStatus.Insufficient;
    }
}