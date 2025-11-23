// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TWUSDC is ERC20 {
    constructor() ERC20("TaskWiser USD Coin", "TWUSDC") {
        // Mint initial supply to deployer
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    // Override decimals to match USDC (6)
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
