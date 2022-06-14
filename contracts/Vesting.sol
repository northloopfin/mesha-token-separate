// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";

contract TokenVesting is Ownable {
    event Released(uint256 amount);
    event Revoked();

    // beneficiary of tokens after they are released
    address public immutable beneficiary;

    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;

    bool public immutable revocable;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;

    /**
    * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
    * of the balance will have vested.
    * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
    * @param _duration duration in seconds of the period in which the tokens will vest
    * @param _revocable whether the vesting is revocable or not
    */
    constructor(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_cliff <= _duration, "Cliff cannot be longer than duration");

        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start += _cliff;
        start = _start;
    }

    /**
    * @notice Transfers vested tokens to beneficiary.
    * @param token ERC20 token which is being vested
    */
    function release(IERC20 token) external {
        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0, "No releasable amount");

        released[address(token)] += unreleased;

        token.transfer(beneficiary, unreleased);

        emit Released(unreleased);
    }

    /**
    * @notice Allows the owner to revoke the vesting. Tokens already vested
    * remain in the contract, the rest are returned to the owner.
    * @param token ERC20 token which is being vested
    */
    function revoke(IERC20 token) external onlyOwner {
        require(revocable, "Is not revocable");
        require(!revoked[address(token)], "Token has already been revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance - unreleased;

        revoked[address(token)] = true;

        token.transfer(owner(), refund);

        emit Revoked();
    }

    /**
    * @dev Calculates the amount that has already vested but hasn't been released yet.
    * @param token ERC20 token which is being vested
    */
    function releasableAmount(IERC20 token) public view returns (uint256) {
        return vestedAmount(token) - released[address(token)];
    }

    /**
    * @dev Calculates the amount that has already vested.
    * @param token ERC20 token which is being vested
    */
    function vestedAmount(IERC20 token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance + released[address(token)];

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration || revoked[address(token)]) {
            return totalBalance;
        } else {
            return totalBalance * (block.timestamp - start) / duration;
        }
    }
}