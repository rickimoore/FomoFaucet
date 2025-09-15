// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @notice Thrown when sender attempts to claim multiple times in a day with a single wallet.
error AlreadyClaimedToday();

/// @notice Thrown when Faucet fails to transfer funds to sender.
error DispenseFailed();

/// @notice Thrown when Faucet fails to transfer funds to sender.
error ClaimTooLow();

/// @notice Thrown when baseRatePerSecond is set to 0.
error InvalidBaseRate();

/// @notice Thrown when slowDownPerClaim is set to 0.
error InvalidSlowDownPerClaim();

/// @notice Thrown when minClaimAmount is set to 0.
error InvalidMinClaimAmount();

/// @title The Fomo-Faucet
/// @author Mavrik
/**
 * @notice This contract is a fun take on faucets and a reverse dutch auction game mechanic.
 *     The idea is to allow anyone to make a claim of hoodiEth from any wallet. The longer users wait,
 *     the larger the claim they can make from the pot. If they wait too long however they increase their chance of being sniped
 *     by another player which will restart the claim amount after each new claim.
 *     There is a limit of 1 claim per day for each address and a minClaimAmount to prevent ddos style attacks.
 *     The game is not designed to ensure complete fairness.
 *     I encourage anyone to figure out ways to break the game and claim as much hoodiEth as possible.
 */
contract FomoFaucet is Ownable {
    uint256 public lastClaim; //integer
    uint256 public claimCount; //integer
    uint256 private baseRatePerSecond; //fixed-point number
    uint256 private slowDownPerClaim; //fixed-point number
    uint256 public minClaimAmount;
    uint64 constant scale = 1e18; //integer

    mapping(address => uint256) public lastClaimDay;

    /// @notice Emitted when a user makes a valid claim.
    /// @param sender is the address of the users making claim.
    /// @param amount is the value of the claim user is able to obtain.
    event ClaimDispensed(address indexed sender, uint256 amount);

    /// @notice Emitted when owner updates minClaimAmount.
    /// @param amount is the value of the new minClaimAmount.
    event MinClaimAmountUpdated(uint256 amount);

    /// @notice Emitted when owner updates baseRatePerSecond.
    /// @param amount is the new value of the baseRatePerSecond.
    event BaseRateUpdated(uint256 amount);

    /// @notice Emitted when owner updates slowDownPerClaim.
    /// @param amount is the new value of the slowDownPerClaim.
    event SlowDownPerClaimUpdated(uint256 amount);

    constructor(uint256 _baseRate, uint256 _slowDownPerClaim, uint256 _minClaimAmount) Ownable(msg.sender) {
        if (_baseRate == 0) {
            revert InvalidBaseRate();
        }

        if (_slowDownPerClaim == 0) {
            revert InvalidSlowDownPerClaim();
        }

        if (_minClaimAmount == 0) {
            revert InvalidMinClaimAmount();
        }

        baseRatePerSecond = _baseRate; // expected to be scaled fixed point
        slowDownPerClaim = _slowDownPerClaim; // expected to be scaled fixed point
        minClaimAmount = _minClaimAmount; //expected to be scaled
        lastClaim = block.timestamp;
    }

    /// @notice Sets a new minClaimAmount. This prevents users from immediately collecting dust wei in ddos attacks.
    /// @dev Only callable by the owner.
    /// @param _minClaimAmount is the new value of the minClaimAmount.
    function updateMinClaimAmount(uint256 _minClaimAmount) public onlyOwner {
        if (_minClaimAmount == 0) {
            revert InvalidMinClaimAmount();
        }

        minClaimAmount = _minClaimAmount;
        emit MinClaimAmountUpdated(_minClaimAmount);
    }

    /// @notice Sets a new baseRatePerSecond. This is the initial rate of wei allowed per second
    /// @dev Only callable by the owner.
    /// @param _baseRate is the new value of the baseRatePerSecond
    function updateBaseRate(uint256 _baseRate) public onlyOwner {
        if (_baseRate == 0) {
            revert InvalidBaseRate();
        }

        baseRatePerSecond = _baseRate;
        emit BaseRateUpdated(_baseRate);
    }

    /// @notice Sets a new slowDownPerClaim. This combined with the claimCount decreases the rate of wei released for every new claim.
    /// @dev Only callable by the owner.
    /// @param _slowDownPerClaim is the new value of the slowDownPerClaim
    function updateSlowDownPerClaim(uint256 _slowDownPerClaim) public onlyOwner {
        if (_slowDownPerClaim == 0) {
            revert InvalidSlowDownPerClaim();
        }

        slowDownPerClaim = _slowDownPerClaim;
        emit SlowDownPerClaimUpdated(_slowDownPerClaim);
    }

    /// @notice Calculates the amount of wei a user can claim at the current block timestamp
    /// @return Amount in wei to be released in the next claim
    function calculateClaim() public view returns (uint256) {
        uint256 timeNow = block.timestamp;
        uint256 balance = address(this).balance;
        uint256 denom = scale + (slowDownPerClaim * claimCount); //1 + k * c

        uint256 rate = (baseRatePerSecond * scale) / denom;
        uint256 delta = timeNow - lastClaim;
        uint256 prod = rate * delta; // fixed point multiplied by integer
        uint256 fraction = prod > scale ? scale : prod; //maxes out at 1 as fixed point

        return (balance * fraction) / scale;
    }

    /// @notice Dispenses wei to msg.sender 1x per day.
    /// @custom:revert AlreadyClaimedToday If adequate time has not passed since msg.sender last claim.
    /// @custom:revert ClaimTooLow If not enough time has passed since las claim.
    /// @custom:revert DispenseFailed If contract failed to send ETH.
    function claim() public {
        uint256 timeNow = block.timestamp;
        uint256 today = timeNow / 1 days;
        if (lastClaimDay[msg.sender] == today) {
            revert AlreadyClaimedToday();
        }

        uint256 claimAmount = calculateClaim(); // this returns unscaled wei

        uint256 balance = address(this).balance;

        if (balance <= minClaimAmount) {
            claimAmount = balance;
        } else if (claimAmount < minClaimAmount) {
            revert ClaimTooLow();
        }

        lastClaimDay[msg.sender] = today;
        lastClaim = timeNow;
        claimCount += 1;

        (bool success,) = payable(msg.sender).call{value: claimAmount}("");

        if (!success) {
            revert DispenseFailed();
        }

        emit ClaimDispensed(msg.sender, claimAmount);
    }
}
