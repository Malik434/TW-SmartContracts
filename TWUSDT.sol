// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TWUSDT is ERC20 {
    constructor() ERC20("TaskWiser Tether USD", "TWUSDT") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
