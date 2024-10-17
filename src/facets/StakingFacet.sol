// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ERC20Facet.sol";
import "../libraries/LibDiamond.sol";

contract StakingFacet {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.staking.storage");

    struct StakingStorage {
        mapping(address => uint256) stakedBalances;
        uint256 totalStaked;
    }

    function stakingStorage() internal pure returns (StakingStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        ERC20Facet erc20 = ERC20Facet(address(this));
        require(erc20.balanceOf(msg.sender) >= amount, "Insufficient balance");

        StakingStorage storage ss = stakingStorage();
        ss.stakedBalances[msg.sender] += amount;
        ss.totalStaked += amount;

        require(erc20.transferFrom(msg.sender, address(this), amount), "Stake transfer failed");

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        StakingStorage storage ss = stakingStorage();
        require(ss.stakedBalances[msg.sender] >= amount, "Insufficient staked balance");

        ss.stakedBalances[msg.sender] -= amount;
        ss.totalStaked -= amount;

        ERC20Facet erc20 = ERC20Facet(address(this));
        require(erc20.transfer(msg.sender, amount), "Unstake transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    function stakedBalanceOf(address account) external view returns (uint256) {
        return stakingStorage().stakedBalances[account];
    }

    function totalStaked() external view returns (uint256) {
        return stakingStorage().totalStaked;
    }
}