// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Workout Accountability Contracts
 * @dev Users lock funds tied to their fitness goals. If they meet goals, 
 * they can claim rewards. If not, funds are donated to charity.
 */
contract Project {
    struct Goal {
        uint256 targetSteps;   // Example fitness goal (steps count)
        uint256 deadline;      // Unix timestamp
        uint256 stakedAmount;  // Locked funds
        bool achieved;         // Marked true when fitness proof submitted
        bool claimed;          // True once funds handled
    }

    mapping(address => Goal) public goals;
    address public charityWallet;

    event GoalCommitted(address indexed user, uint256 targetSteps, uint256 deadline, uint256 amount);
    event GoalAchieved(address indexed user);
    event FundsClaimed(address indexed user, uint256 amount);
    event FundsDonated(address indexed user, uint256 amount);

    constructor(address _charityWallet) {
        charityWallet = _charityWallet;
    }

    /// @notice User locks tokens (ETH in this case) with a fitness goal
    function commitGoal(uint256 _targetSteps, uint256 _deadline) external payable {
        require(msg.value > 0, "Must stake some ETH");
        require(_deadline > block.timestamp, "Deadline must be in future");

        goals[msg.sender] = Goal({
            targetSteps: _targetSteps,
            deadline: _deadline,
            stakedAmount: msg.value,
            achieved: false,
            claimed: false
        });

        emit GoalCommitted(msg.sender, _targetSteps, _deadline, msg.value);
    }

    /// @notice Called by an off-chain oracle/fitness tracker integration
    function markGoalAchieved(address _user) external {
        Goal storage g = goals[_user];
        require(block.timestamp <= g.deadline, "Deadline passed");
        require(!g.achieved, "Already marked achieved");

        g.achieved = true;
        emit GoalAchieved(_user);
    }

    /// @notice User claims funds if successful, else sends funds to charity
    function settleGoal() external {
        Goal storage g = goals[msg.sender];
        require(!g.claimed, "Already settled");
        require(block.timestamp > g.deadline, "Deadline not reached");

        g.claimed = true;

        if (g.achieved) {
            payable(msg.sender).transfer(g.stakedAmount);
            emit FundsClaimed(msg.sender, g.stakedAmount);
        } else {
            payable(charityWallet).transfer(g.stakedAmount);
            emit FundsDonated(msg.sender, g.stakedAmount);
        }
    }
}
