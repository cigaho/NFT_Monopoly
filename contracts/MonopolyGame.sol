// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Board.sol";
import "./MonopolyProperty.sol";

contract MonopolyGame {
    enum GameState { ACTIVE, ENDED }
    GameState public gameState;

    //store players info
    struct Player {
        address addr;
        uint256 balance;
        uint256 position;
        uint256 asset;
    }
    
    Board public board;
    MonopolyProperty public propertyToken;
    Player[2] public players;
    uint256 public currentPlayer;
    uint256 public round;
    bool public canBuy;
    bool public bonus;

    mapping(uint256 => address) public propertyOwner;
    
    event PlayerMoved(uint256 indexed playerIndex, uint256 newPosition);
    event PropertyPurchased(address buyer, uint256 position);
    event GameEnded(address winner);
    event TurnSwitched(uint256 newPlayer);
    event RentPaid(address payer, address owner, uint256 amount);
    event PropertyUpgraded(uint256 indexed position, address indexed player, uint256 upgradeCost, uint256 newLevel);
    event RoundReward(address player, uint reward);

    //start the game and offer 4000 initial balance
    constructor(
        address[2] memory _players,
        address _board,
        address _property
    ) {
        board = Board(_board);
        propertyToken = MonopolyProperty(_property);
        round=0;
        bonus = false;
        for(uint256 i = 0; i < 2; i++) {
            players[i] = Player({
                addr: _players[i],
                balance: 4000, 
                position: 0,
                asset: 0
            });
        }
        gameState = GameState.ACTIVE;
        currentPlayer = 0;
    }

    modifier onlyCurrentPlayer() {
        require(msg.sender == players[currentPlayer].addr, "Not your turn");
        _;
    }

//Below are external functions called by JavaScript to maintain gameflow
    //change bonus to false
    function changeBonus() external{
        bonus = false;
    }
    
    //Used to set the tax office's owner to Tax official address
    function setOwner(uint256 position, address owner) external {
        propertyOwner[position] = owner;
    }
    
    // roll the dice and call internal function _movePlayer for moving players
    function rollDice() external onlyCurrentPlayer returns (uint256) {
        require(gameState == GameState.ACTIVE, "Game ended");
        
        uint256 dice = _randomDice();
        _movePlayer(dice);
        canBuy = (propertyOwner[players[currentPlayer].position] == address(0));
        return dice;
    }

    //Handle property purchase issue
    function buyProperty() external onlyCurrentPlayer {
        require(gameState == GameState.ACTIVE, "Game ended");
        require(canBuy, "Can only buy after rolling dice");
    
        uint256 position = players[currentPlayer].position;
        require(propertyOwner[position] == address(0), "Already owned");
    
        uint256 price = board.getPrice(position);
        
        _transfer(players[currentPlayer].addr,address(0),price);
        _updateAsset(players[currentPlayer].addr, price);
        propertyToken.mint(players[currentPlayer].addr, position);
        propertyOwner[position] = players[currentPlayer].addr;
    
        emit PropertyPurchased(msg.sender, position);
        canBuy = false;
        _nextTurn();
    }
    
    //Handle property upgrade, call functions in Board.sol
    function upgradeProperty() external onlyCurrentPlayer {
        uint256 position = players[currentPlayer].position;
        require(propertyOwner[position] == players[currentPlayer].addr, "Not owner");
        uint256 currentLevel = board.getLevel(position);
        
        // Calculate upgrade price
        uint256 basePrice = board.getPrice(position);
        uint256 upgradeCost = (basePrice * currentLevel) / 2; 
        
        
        require(players[currentPlayer].balance >= upgradeCost, "Insufficient balance");
        
        // Deducting balance first to avoid reentry attack
        _transfer(players[currentPlayer].addr, address(0), upgradeCost);
        _updateAsset(players[currentPlayer].addr, upgradeCost);
        board.upgrade(position);
        
        uint256 newLevel = board.getLevel(position);
        emit PropertyUpgraded(position, msg.sender, upgradeCost, newLevel);
    }




//Functions used for test file stimulations
    //Set up player's balance, position by address
    function debugForceSetup(address player, uint256 position, uint256 balance,bool isCurrentPlayer) external {
        uint256 playerIndex = (player == players[0].addr) ? 0 : 1;
        
        players[playerIndex].position = position % 20;
        players[playerIndex].balance = balance;
        
        if(isCurrentPlayer) {
            currentPlayer = playerIndex;
            canBuy = true;
        }
    }

    // Move a player to designated position and triggle relavant events (purchase, rent)
    function debugMovePlayer(address player, uint256 steps) external {
        require(gameState == GameState.ACTIVE, "Game ended");
        
        currentPlayer = (player == players[0].addr) ? 0 : 1;
        canBuy = false;
        
        players[currentPlayer].position = (players[currentPlayer].position + steps) % 20;
        _handlePosition();
        _nextTurn();
    }


//Following functions are used to retreive certain information
    // User balance
    function getBalance(address player) external view returns (uint256) {
        for (uint i = 0; i < players.length; i++) {
            if (players[i].addr == player) {
                return players[i].balance;
            }
        }
        revert("Player not found");
    }

    //User name
    function getPropertyName(uint256 position) external view returns (string memory){
        return board.getLandName(position);
    }
    
    //Property buy price
    function getPrice(uint256 position) external view returns (uint256){
        uint256 price = board.getPrice(position);
        return price;
    }

    // get the update price
    function getUpgradePrice(uint256 position) external view returns (uint256){
        uint256 currentLevel = board.getLevel(position);
        uint256 basePrice = board.getPrice(position);
        uint256 upgradeCost = (basePrice * currentLevel) / 2; 
        return upgradeCost;
    }

    //get updated rent price
    function getRentPrice(uint256 position) external view returns (uint256){
        uint256 price = board.getRentPrice(position);
        return price;
    }

    //get property level
    function getLevel(uint256 position) external view returns (uint256){
        uint256 price = board.getLevel(position);
        return price;
    }

    //get user's total asset value (property + balance)
    function getAsset(address player) external view returns (uint256){
        for (uint i = 0; i < players.length; i++) {
            if (players[i].addr == player) {
                uint256 assetPrice = players[i].asset;
                return assetPrice;
            }
        }
        revert("Player not found");
    }

    //get user's property value (NFTs)
    function calcAsset(address player) external view returns (int256) {
        return _calcAsset(player);
    }

    //get the name of owner in string
    function getOwner(uint256 position) external view returns (string memory) {
        address temp = propertyOwner[position];
        if (temp == address(0)) {
            return "No owner";
        } else if (temp == players[0].addr) {
            return "Player 1";
        } else if (temp == players[1].addr) {
            return "Player 2";
        } else {
            return "Tax Officials";
        }
    }

    //get the winner after game ended
    function getWinner() external view returns (address) {
        // Check if someone went bankrupt
        if (_isBankrupt(players[0].balance)) return players[1].addr;
        if (_isBankrupt(players[1].balance)) return players[0].addr;
        // Otherwise return player with higher balance
        return _calcAsset(players[0].addr) > _calcAsset(players[1].addr)
            ? players[0].addr 
            : players[1].addr;
    }

    function changeTurn() external onlyCurrentPlayer {
        _nextTurn();
    }


//Below are internal functions
    
    //used to calculate player total asset
    function _calcAsset(address player) internal view returns (int256) {  
        for (uint i = 0; i < players.length; i++) {
            if (players[i].addr == player) {
                
                int256 eff_balance = int256(players[i].balance);
                if (999000 > eff_balance && eff_balance > 99900){
                    eff_balance -= 99900;
                    eff_balance = - eff_balance;
                }else if (999000 < eff_balance) {
                    eff_balance -= 999000;
                    eff_balance = - eff_balance;
                }else{
                    eff_balance -= 9990000;
                    eff_balance = - eff_balance;
                }
                
                int256 totalPrice = eff_balance + int(players[i].asset);
                return totalPrice;
            }
        }
        revert("Player not found");
    }

    //used to trigger relavant event when arriving at a land
    function _handlePosition() internal {
        uint256 position = players[currentPlayer].position;
        address owner = propertyOwner[position];
        
        if (owner == address(0) || owner == players[currentPlayer].addr) return;

        uint256 rent = board.getRentPrice(position);
        
        if ((position%10)==7){
            _upgradeTax();
        }

        if (players[currentPlayer].balance < rent) {
            uint256 value = rent - players[currentPlayer].balance;
            uint digits = 0;
            if (value <100){
                digits=2;
            }else if (value <1000 ){
                digits =3;
            }else if (value >=1000){
                digits =4;
            }
            uint256 new_balance = value + 999 * 10**digits;
            players[currentPlayer].balance = new_balance;
            _transfer(address(0),owner,rent);
            _endGame(owner);
            return;
        }
        
        _transfer(players[currentPlayer].addr,owner,rent);
        emit RentPaid(players[currentPlayer].addr, owner, rent);
        
        _nextTurn();
    }

    //generate a random dice
    function _randomDice() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))) % 6 + 1;
    }

    //update player position and call _handlePosition
    function _movePlayer(uint256 dice) internal {
        Player storage player = players[currentPlayer];
        if ((player.position + dice) >= 20) _reward();
        player.position = (player.position + dice) % 20;
        emit PlayerMoved(currentPlayer, player.position);
        _handlePosition();
    }

    //Switch player
    function _nextTurn() internal {
        canBuy = false;
        currentPlayer = (currentPlayer + 1) % 2;
        emit TurnSwitched(currentPlayer);
    }

    //terminate the game
    function _endGame(address immediateWinner) internal {
        gameState = GameState.ENDED;
        address winner = immediateWinner != address(0) ? 
            immediateWinner : 
            (_isBankrupt(players[0].balance) ? players[1].addr : 
            (_isBankrupt(players[1].balance) ? players[0].addr : 
            (players[0].balance > players[1].balance ? players[0].addr : players[1].addr)));
        emit GameEnded(winner);
    }

    //get player based on its address
    function _findPlayer(address addr) internal view returns (Player storage) {
        if (players[0].addr == addr) return players[0];
        if (players[1].addr == addr) return players[1];
        revert("Player not found");
    }

    //Conduct all transactions with SkipLabToken
    function _transfer(address from, address to, uint amount) internal {
        for (uint i = 0; i < players.length; i++) {
            if (players[i].addr == from) {
                require(players[i].balance >= amount, "Insufficient balance for transfer");
                players[i].balance -= amount;
            }
            if (players[i].addr == to){
                players[i].balance += amount;
            }
        }
    }

    //Update user asset when user purchase or upgrades property
    function _updateAsset(address player, uint256 amount) internal {
        for (uint i = 0; i < players.length; i++) {
            if (players[i].addr == player) {
                players[i].asset += amount;
                return ;
            }
        }
    }
    
    //provide bonus for finishing a round
    function _reward() internal{
        _transfer(address(0),players[currentPlayer].addr,500);
        round++;
        bonus=true;
        emit RoundReward(players[currentPlayer].addr, 500);
    }

    //Increase tax amount every time a user arrive at tax office
    function _upgradeTax() internal {
        uint256 position = players[currentPlayer].position;
        board.upgrade(position);
    }

    //Check if a user is bankrupt
    function _isBankrupt(uint256 balance) internal pure returns (bool) {
        return balance >= 99900 ; // Adjust based on your representation
    }

}
