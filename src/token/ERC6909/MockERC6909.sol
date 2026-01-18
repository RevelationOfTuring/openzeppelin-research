// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC6909} from "openzeppelin-contracts/contracts/token/ERC6909/ERC6909.sol";

contract MockERC6909 is ERC6909 {
    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }
}
