// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC6909ContentURI} from "openzeppelin-contracts/contracts/token/ERC6909/extensions/ERC6909ContentURI.sol";

contract MockERC6909ContentURI is ERC6909ContentURI {
    function setContractURI(string memory newContractURI) external {
        _setContractURI(newContractURI);
    }

    function setTokenURI(uint256 id, string memory newTokenURI) external {
        _setTokenURI(id, newTokenURI);
    }
}
