// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ISkipLabToken is IAccessControl {
    // 权限管理
    function GAME_ROLE() external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    
    // 代币操作
    function gameMint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function safeTransfer(address sender, address recipient, uint256 amount) external returns (bool);
    
    // ERC20标准函数
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    
    // 新增必要函数
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}