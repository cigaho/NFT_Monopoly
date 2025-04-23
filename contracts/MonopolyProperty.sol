// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IMonopolyProperty.sol";

contract MonopolyProperty is ERC721, AccessControl, IMonopolyProperty {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant override GAME_CONTRACT = keccak256("GAME_CONTRACT");
    
    struct Property {
        string name;
        uint256 price;
        uint256 baseRent;
        string colorGroup;
        uint256 position;
    }

    mapping(uint256 => uint256) public override propertyLevels;
    mapping(uint256 => Property) private _properties;
    uint256 public constant MAX_LEVEL = 5;

    event PropertyUpgraded(uint256 indexed tokenId, uint256 newLevel);

    constructor() ERC721("MonopolyProperty", "MPROP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(GAME_CONTRACT, DEFAULT_ADMIN_ROLE);
    }

    function grantGameRole(address game) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GAME_CONTRACT, game);
    }

    function getPropertyPrice(uint256 tokenId) public view returns (uint256) {
        (, uint256 price, , , , ) = getPropertyDetails(tokenId);
        return price;
    }

    function mintProperty(
        address player,
        string memory name,
        uint256 price,
        uint256 baseRent,
        string memory colorGroup,
        uint256 mapPosition
    ) external override onlyRole(GAME_CONTRACT) returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);

        _properties[newItemId] = Property(name, price, baseRent, colorGroup, mapPosition);
        return newItemId;
    }

    function upgradeProperty(uint256 tokenId) external override {
        require(
            ownerOf(tokenId) == msg.sender || hasRole(GAME_CONTRACT, msg.sender),
            "Not authorized"
        );
        require(propertyLevels[tokenId] < MAX_LEVEL, "Max level reached");
        
        propertyLevels[tokenId]++;
        emit PropertyUpgraded(tokenId, propertyLevels[tokenId]);
    }

    function getPropertyDetails(uint256 tokenId) public view override returns (
        string memory name,
        uint256 price,
        uint256 currentRent,
        string memory colorGroup,
        uint256 level,
        uint256 position
    ) {
        require(_exists(tokenId), "Property does not exist");
        Property memory prop = _properties[tokenId];
        return (
            prop.name,
            prop.price,
            getCurrentRent(tokenId),
            prop.colorGroup,
            propertyLevels[tokenId],
            prop.position
        );
    }

    function getCurrentRent(uint256 tokenId) public view override returns (uint256) {
        return _properties[tokenId].baseRent * (100 + 50 * propertyLevels[tokenId]) / 100;
    }

    function getColorGroup(uint256 tokenId) external view override returns (string memory) {
        return _properties[tokenId].colorGroup;
    }

    function getPropertyPosition(uint256 tokenId) external view override returns (uint256) {
        return _properties[tokenId].position;
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || 
            hasRole(GAME_CONTRACT, msg.sender),
            "Transfer not allowed"
        );
        propertyLevels[tokenId] = 0;
        _safeTransfer(from, to, tokenId, "");
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}