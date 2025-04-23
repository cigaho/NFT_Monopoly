// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ISkipLabToken.sol";
import "./interfaces/IMonopolyProperty.sol";
import "./Board.sol";

contract MonopolyGame is AccessControl {
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    
    ISkipLabToken public skipLabToken;
    IMonopolyProperty public monopolyProperty;
    Board public board;

    uint256 public currentTurnIndex;
    mapping(address => bool) public hasRolledThisTurn;
    
    struct Player {
        address wallet;
        uint256 position;
        bool isBankrupt;
        uint256 jailTurns;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    event GameStarted();
    event TurnEnded(address indexed player);
    event PlayerBankrupt(address indexed player);
    event PropertyUpgraded(uint256 indexed propertyId, uint256 newLevel);
    event PropertyPurchased(address player, uint256 propertyId);
    event RentPaid(address from, address to, uint256 propertyId, uint256 amount);
    event PlayerMoved(address player, uint256 newPosition);

    constructor(address _tokenAddress, address _propertyAddress, address _boardAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);
        
        skipLabToken = ISkipLabToken(_tokenAddress);
        monopolyProperty = IMonopolyProperty(_propertyAddress);
        board = Board(_boardAddress);
    }

    function initializeGamePermissions() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // 授予当前合约管理员权限
        _grantRole(DEFAULT_ADMIN_ROLE, address(this));
        _grantRole(GAME_ADMIN, address(this));
        
        // 设置棋盘合约权限
        bytes32 boardRole = board.GAME_CONTRACT();
        board.grantRole(boardRole, address(this));
        
        // 设置房产合约权限
        bytes32 propertyRole = monopolyProperty.GAME_CONTRACT();
        monopolyProperty.grantRole(propertyRole, address(this));
        
        // 设置代币权限
        bytes32 tokenRole = skipLabToken.GAME_ROLE();
        skipLabToken.grantRole(tokenRole, address(this));
    }

    modifier onlyCurrentPlayer() {
        require(playerAddresses[currentTurnIndex] == msg.sender, "Not your turn");
        _;
    }

    modifier activePlayer() {
        require(!players[msg.sender].isBankrupt, "Player bankrupt");
        _;
    }

    function joinGame() external {
        require(players[msg.sender].wallet == address(0), "Already joined");
        require(playerAddresses.length < 6, "Max players reached");
        
        players[msg.sender] = Player(msg.sender, 0, false, 0);
        playerAddresses.push(msg.sender);
        skipLabToken.gameMint(msg.sender, 1500 * 10**18);
        
        if(playerAddresses.length == 1) emit GameStarted();
    }

    function buyProperty(uint256 propertyId) external activePlayer {
        require(monopolyProperty.ownerOf(propertyId) == address(this), "Not available");
        
        (, uint256 price, , , , ) = monopolyProperty.getPropertyDetails(propertyId);
        require(skipLabToken.safeTransfer(msg.sender, address(this), price), "Payment failed");
        monopolyProperty.safeTransferFrom(address(this), msg.sender, propertyId);
        
        emit PropertyPurchased(msg.sender, propertyId);
    }

    function collectRent(uint256 propertyId, address tenant) external {
        require(hasRole(GAME_ADMIN, msg.sender), "Unauthorized");
        require(monopolyProperty.ownerOf(propertyId) != address(0), "Invalid property");
        
        address owner = monopolyProperty.ownerOf(propertyId);
        uint256 rent = monopolyProperty.getCurrentRent(propertyId);
        require(skipLabToken.safeTransfer(tenant, owner, rent), "Rent failed");
        
        emit RentPaid(tenant, owner, propertyId, rent);
    }

    function movePlayer(uint256 steps) external onlyCurrentPlayer activePlayer {
        require(steps >= 2 && steps <= 12, "Invalid dice");
        require(!hasRolledThisTurn[msg.sender], "Already moved");
        
        Player storage player = players[msg.sender];
        uint256 newPosition = (player.position + steps) % 40;
        player.position = newPosition;
        hasRolledThisTurn[msg.sender] = true;
        
        board.handleLandingEffect(newPosition, msg.sender);
        emit PlayerMoved(msg.sender, newPosition);
    }

    function endTurn() external onlyCurrentPlayer {
        currentTurnIndex = (currentTurnIndex + 1) % playerAddresses.length;
        hasRolledThisTurn[msg.sender] = false;
        emit TurnEnded(msg.sender);
    }

    function addProperty(
        string memory name,
        uint256 price,
        uint256 baseRent,
        string memory colorGroup,
        uint256 mapPosition
    ) external onlyRole(GAME_ADMIN) {
        monopolyProperty.mintProperty(address(this), name, price, baseRent, colorGroup, mapPosition);
    }

    function distributeTokens(address recipient, uint256 amount) external onlyRole(GAME_ADMIN) {
        skipLabToken.gameMint(recipient, amount);
    }

    function upgradeProperty(uint256 propertyId) external {
        require(monopolyProperty.ownerOf(propertyId) == msg.sender, "Not owner");
        uint256 cost = _calculateUpgradeCost(propertyId);
        
        require(skipLabToken.safeTransfer(msg.sender, address(this), cost), "Payment failed");
        monopolyProperty.upgradeProperty(propertyId);
        
        emit PropertyUpgraded(propertyId, monopolyProperty.propertyLevels(propertyId));
    }

    function grantGameAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(GAME_ADMIN, admin);
    }

    function renounceGameAdmin() external onlyRole(GAME_ADMIN) {
        revokeRole(GAME_ADMIN, msg.sender);
    }

    function _calculateUpgradeCost(uint256 propertyId) private view returns (uint256) {
        uint256 currentLevel = monopolyProperty.propertyLevels(propertyId);
        return (currentLevel + 1) * 100 * 10**18;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}