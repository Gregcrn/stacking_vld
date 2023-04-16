# Stacking project with Hardhat

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

# Staking Contract

This is a Ethereum staking contract allowing users to stake their tokens for a specified duration and earn interest. The contract uses variable interest rates depending on the staking duration.

## Features

- Allows users to stake their tokens for a specified duration.
- Offers variable interest rates depending on the staking duration.
- Allows users to unstake their tokens after the stake has expired.
- Enables users to withdraw their earnings.
- Allows the contract owner to disable/enable the contract.
- Enables the contract owner to set the interest rate for a specified duration.
- Provides a function to process expired stakes and add earnings to users' accounts.

## Usage

### Staking tokens

Users can stake their tokens by calling the `stake(uint256 durationIndex)` function with the index of the desired staking duration. The available staking durations are 30 days, 60 days, and 90 days.

### Unstaking tokens

After a stake has expired, users can unstake their tokens by calling the `unstake(uint256 stakeId)` function with the ID of the stake they want to unstake.

### Withdrawing earnings

Users can withdraw their earnings by calling the `withdrawEarnings()` function.

### Disabling and enabling the contract

The contract owner can disable the contract by calling the `disable()` function and enable it by calling the `enable()` function.

### Setting interest rates

The contract owner can set the interest rate for a specified duration by calling the `setInterestRate(uint256 durationIndex, uint256 interestRate)` function.

### Processing expired stakes

The contract owner can process expired stakes and add earnings to users' accounts by calling the `getExpiredStakes()` function.

### Viewing stake information

Users can view their stakes by calling the `getStakes(address user)` function with their Ethereum address as the parameter.

## Security

The contract includes modifiers to ensure that only the contract owner can call specific functions and that the contract is enabled before allowing users to interact with it.
