// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SkipLabToken is ERC20, AccessControl {
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");

    constructor() ERC20("SkipLab", "SKIPLAB") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, 1000000 * 10**18);
    }

    function gameMint(address to, uint256 amount) external onlyRole(GAME_ROLE) {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyRole(GAME_ROLE) {
        _burn(account, amount);
    }

    function safeTransfer(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function grantGameRole(address game) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GAME_ROLE, game);
    }
}