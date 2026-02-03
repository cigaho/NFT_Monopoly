// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMonopolyProperty.sol";
import "./interfaces/ISkipLabToken.sol";

contract Board is AccessControl {
    bytes32 public constant GAME_CONTRACT = keccak256("GAME_CONTRACT");
    
    enum TileType { START, PROPERTY, CHANCE, COMMUNITY_CHEST, TAX, JAIL }

    struct Tile {
        TileType tileType;
        string name;
        uint256 value;
        uint256 linkedPropertyId;
    }

    Tile[40] public tiles;
    IMonopolyProperty public propertyContract;
    ISkipLabToken public tokenContract;

    constructor(address _propertyAddress, address _tokenAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        
        propertyContract = IMonopolyProperty(_propertyAddress);
        tokenContract = ISkipLabToken(_tokenAddress);
        _initializeBoard();
    }

    function grantGameRole(address game) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(game != address(0), "Invalid game address");
        _grantRole(GAME_CONTRACT, game);
        
        // update token contract access
        bytes32 gameRole = tokenContract.GAME_ROLE();
        tokenContract.grantRole(gameRole, game);
    }

    function _initializeBoard() private {
        // initialize board
        tiles[0] = Tile(TileType.START, "Start", 200, 0);
        tiles[1] = Tile(TileType.PROPERTY, "HKU", 60, 1);
        tiles[2] = Tile(TileType.COMMUNITY_CHEST, "Community Chest", 0, 0);
        tiles[3] = Tile(TileType.PROPERTY, "Central", 60, 2);
        tiles[4] = Tile(TileType.TAX, "Income Tax", 200, 0);
        tiles[5] = Tile(TileType.PROPERTY, "Station", 200, 3);
    }

    function handleLandingEffect(uint256 position, address player) external onlyRole(GAME_CONTRACT) {
        require(position < 40, "Invalid position");
        
        Tile memory tile = tiles[position];
        
        if (tile.tileType == TileType.PROPERTY) {
            _handlePropertyLanding(tile.linkedPropertyId, player);
        } else if (tile.tileType == TileType.CHANCE) {
            _handleChanceCard(player);
        } else if (tile.tileType == TileType.COMMUNITY_CHEST) {
            _handleCommunityChest(player);
        }
    }

    function _handlePropertyLanding(uint256 propertyId, address player) private {
        address owner = propertyContract.ownerOf(propertyId);
        if (owner == address(0)) {
            uint256 price = propertyContract.getPropertyPrice(propertyId);
            require(
                tokenContract.safeTransfer(player, address(this), price),
                "Payment failed"
            );
            propertyContract.safeTransferFrom(address(this), player, propertyId);
        } else {
            _collectRent(propertyId, player, owner);
        }
    }

    function _collectRent(uint256 propertyId, address payer, address owner) private {
        uint256 rent = propertyContract.getCurrentRent(propertyId);
        require(rent > 0, "Invalid rent amount");
        require(tokenContract.safeTransfer(payer, owner, rent), "Rent failed");
    }

    function _handleChanceCard(address player) private {
        tokenContract.gameMint(player, 100 * 10**18);
    }

    function _handleCommunityChest(address player) private {
        tokenContract.gameMint(player, 50 * 10**18);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
