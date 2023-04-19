// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Staking
 * @dev A contract for staking tokens with variable interest rates.
 */
contract Staking {
    /**
     * @dev Struct to represent a stake.
     * @param user The address of the user who made the stake.
     * @param amount The amount of tokens staked.
     * @param duration The duration of the stake.
     * @param interestRate The interest rate of the stake.
     * @param start The timestamp when the stake was made.
     * @param end The timestamp when the stake expires.
     * @param released A boolean flag indicating if the stake has been released.
     */
    struct Stake {
        address user;
        uint256 amount;
        uint256 duration;
        uint256 interestRate;
        uint256 start;
        uint256 end;
        bool released;
    }

    address public owner;
    bool public enabled;
    uint256 public totalStaked;
    mapping(address => uint256) public balanceOf;
    mapping(address => Stake[]) public stakesOf;
    mapping(address => uint256) public earningsOf;
    mapping(uint256 => Stake[]) public expiredStakes;
    uint256 public nextStakeId;
    uint256[] public durations;
    mapping(uint256 => uint256) public interestRates;
    IERC20 public token;

    /// @dev Emitted when a user stakes
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 duration,
        uint256 interestRate
    );

    /// @dev Emitted when a user unstakes
    event Unstaked(address indexed user, uint256 amount);

    /// @dev Emitted when a stake expires
    event ExpiredStake(address indexed user, uint256 amount, uint256 earnings);

    /// @notice Initializes the contract with owner, enabled status, and default interest rates and token
    constructor(IERC20 _token) {
        owner = msg.sender;
        enabled = true;
        durations = [30 days, 60 days, 90 days];
        interestRates[30 days] = 20;
        interestRates[60 days] = 30;
        interestRates[90 days] = 90;
        token = _token;
    }

    /// @dev Modifier to ensure only the contract owner can call a function
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /// @dev Modifier to ensure the contract is enabled before calling a function
    modifier isEnabled() {
        require(enabled, "Contract is disabled");
        _;
    }

    /// @notice Allows a user to stake an amount for a specified duration
    /// @param durationIndex The index of the staking duration in the durations array
    /// @param amount The amount of tokens to stake
    function stake(uint256 durationIndex, uint256 amount) external isEnabled {
        require(durationIndex < durations.length, "Invalid duration index");
        require(amount > 0, "Amount must be greater than zero");
        uint256 duration = durations[durationIndex];
        uint256 interestRate = interestRates[duration];
        uint256 start = block.timestamp;
        uint256 end = start + duration;
        Stake memory newStake = Stake(
            msg.sender,
            amount,
            duration,
            interestRate,
            start,
            end,
            false
        );
        stakesOf[msg.sender].push(newStake);
        totalStaked += amount;
        balanceOf[msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, duration, interestRate);
    }

    /// @notice Allows a user to unstake an expired stake
    /// @param stakeId The ID of the stake to unstake
    function unstake(uint256 stakeId) external {
        Stake storage stakeToUnstake = getStakeById(stakeId);
        require(
            stakeToUnstake.user == msg.sender,
            "You are not the owner of this stake"
        );
        require(
            !stakeToUnstake.released,
            "This stake has already been released"
        );
        require(
            block.timestamp >= stakeToUnstake.end,
            "This stake has not yet expired"
        );
        uint256 amount = stakeToUnstake.amount;
        balanceOf[msg.sender] -= amount;
        earningsOf[msg.sender] += getEarnings(stakeToUnstake);
        stakeToUnstake.released = true;
        token.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /*
    /// @notice Allows a user to withdraw their earnings
    function withdrawEarnings() external {
        uint256 earnings = earningsOf[msg.sender];
        require(earnings > 0, "You have no earnings to withdraw");
        earningsOf[msg.sender] = 0;
        payable(msg.sender).transfer(earnings);
    }
    */

    /// @notice Disables the contract (only callable by the owner)
    function disable() external onlyOwner {
        enabled = false;
    }

    /// @notice Enables the contract (only callable by the owner)
    function enable() external onlyOwner {
        enabled = true;
    }

    /// @notice Sets the interest rate for a specified duration
    /// @param durationIndex The index of the staking duration in the durations array
    /// @param interestRate The new interest rate to set
    function setInterestRate(
        uint256 durationIndex,
        uint256 interestRate
    ) external onlyOwner {
        require(durationIndex < durations.length, "Invalid duration index");
        interestRates[durations[durationIndex]] = interestRate;
    }

    /// @notice Returns the stakes of a user
    /// @param user The user whose stakes to return
    /// @return An array of the user's stakes
    function getStakes(address user) external view returns (Stake[] memory) {
        return stakesOf[user];
    }

    /// @notice Processes expired stakes and adds earnings to users' accounts (only callable by the owner)
    function getExpiredStakes() external {
        require(msg.sender == owner, "Only owner can call this function");
        uint256[] memory expiredStakeIds = getExpiredStakeIds();
        for (uint256 i = 0; i < expiredStakeIds.length; i++) {
            uint256 expiredStakeId = expiredStakeIds[i];
            Stake storage expiredStake = getStakeById(expiredStakeId);
            uint256 earnings = getEarnings(expiredStake);
            earningsOf[expiredStake.user] += earnings;
            expiredStake.released = true;
            emit ExpiredStake(expiredStake.user, expiredStake.amount, earnings);
        }
    }

    /// @notice Returns an array of expired stake IDs
    /// @return An array of expired stake IDs
    function getExpiredStakeIds() public view returns (uint256[] memory) {
        uint256[] memory result;
        uint256 count;
        for (uint256 i = 0; i < durations.length; i++) {
            Stake[] storage expired = expiredStakes[i];
            for (uint256 j = 0; j < expired.length; j++) {
                Stake storage expiredStake1 = expired[j];
                if (
                    !expiredStake1.released &&
                    block.timestamp >= expiredStake1.end
                ) {
                    count++;
                }
            }
        }
        result = new uint256[](count);
        count = 0;
        for (uint256 i = 0; i < durations.length; i++) {
            Stake[] storage expired = expiredStakes[i];
            for (uint256 j = 0; j < expired.length; j++) {
                Stake storage expiredStake2 = expired[j];
                if (
                    !expiredStake2.released &&
                    block.timestamp >= expiredStake2.end
                ) {
                    result[count] = j;
                    count++;
                }
            }
        }
        return result;
    }

    /// @notice Returns a stake by its ID
    /// @param stakeId The ID of the stake to return
    /// @return The requested stake
    function getStakeById(
        uint256 stakeId
    ) internal view returns (Stake storage) {
        uint256 stakesLength = stakesOf[msg.sender].length;
        require(stakeId < stakesLength, "Invalid stake ID");
        return stakesOf[msg.sender][stakeId];
    }

    /// @notice Calculates the earnings of a stake
    /// @param stakeEarn The stake for which to calculate earnings
    /// @return The earnings of the stake
    function getEarnings(
        Stake storage stakeEarn
    ) internal view returns (uint256) {
        uint256 amount = stakeEarn.amount;
        uint256 interestRate = stakeEarn.interestRate;
        uint256 start = stakeEarn.start;
        uint256 end = stakeEarn.end;
        uint256 timeElapsed = end - start;
        uint256 ratePerSecond = interestRate / (365 days * 1 ether);
        uint256 earnings = amount * ratePerSecond * timeElapsed;
        return earnings;
    }

    function getEarningsPublic(uint256 stakeId) public view returns (uint256) {
        Stake storage stakeEarn = getStakeById(stakeId);
        return getEarnings(stakeEarn);
    }
}
