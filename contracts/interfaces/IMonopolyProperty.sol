// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMonopolyProperty is IAccessControl, IERC721 {
    // 添加缺失的方法声明
    function getPropertyPrice(uint256 tokenId) external view returns (uint256);
    
    // 保持其他原有方法声明
    function grantGameRole(address game) external;
    function GAME_CONTRACT() external view returns (bytes32);
    
    function mintProperty(
        address player,
        string memory name,
        uint256 price,
        uint256 baseRent,
        string memory colorGroup,
        uint256 mapPosition
    ) external returns (uint256);
    
    function upgradeProperty(uint256 tokenId) external;
    function getPropertyDetails(uint256 tokenId) external view returns (
        string memory name,
        uint256 price,
        uint256 currentRent,
        string memory colorGroup,
        uint256 level,
        uint256 position
    );
    function getCurrentRent(uint256 tokenId) external view returns (uint256);
    function propertyLevels(uint256 tokenId) external view returns (uint256);
    function getColorGroup(uint256 tokenId) external view returns (string memory);
    function getPropertyPosition(uint256 tokenId) external view returns (uint256);
}