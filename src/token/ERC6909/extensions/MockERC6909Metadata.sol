// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC6909Metadata} from "openzeppelin-contracts/contracts/token/ERC6909/extensions/ERC6909Metadata.sol";

contract MockERC6909Metadata is ERC6909Metadata {
    function setName(uint256 id, string memory newName) external virtual {
        _setName(id, newName);
    }

    function setSymbol(uint256 id, string memory newSymbol) external virtual {
        _setSymbol(id, newSymbol);
    }

    function setDecimals(uint256 id, uint8 newDecimals) external virtual {
        _setDecimals(id, newDecimals);
    }
}
