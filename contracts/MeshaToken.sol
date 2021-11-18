// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Vesting.sol";

contract MeshaToken is ERC20, TokenVesting {
    uint256 constant SCALE = 10**18;
    uint256 public constant TOKEN_SUPPLY = 10 * 10**9;
    uint256 public constant INITIAL_SUPPLY = 1 * 10**6;
    address public owner;
    uint256 noOfTimesTokenIssued = 0;
    uint256 createTime;

    constructor() ERC20("Mesha Token", "MESHA") 
                  TokenVesting(0x68ca398A19F1027f8f5eDe2C8275Da5A6C9194E7, 
                    block.timestamp, block.timestamp + 1 years, 
                    block.timestamp + 4 years, 
                    true) {
        _mint(msg.sender, INITIAL_SUPPLY * SCALE);
        owner = msg.sender;
        createTime = block.timestamp;
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }
}