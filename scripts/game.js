const { ethers } = require("hardhat");
const readline = require('readline-sync');

async function main() {
  // Initialize game
  const [owner, player1, player2] = await ethers.getSigners();
  console.log("🚀 Starting Monopoly Game...");
  
  // Deploy contracts
  const Board = await ethers.getContractFactory("Board");
  const board = await Board.deploy();
  await board.waitForDeployment();

  const Property = await ethers.getContractFactory("MonopolyProperty");
  const property = await Property.deploy();
  await property.waitForDeployment();
  
  const Game = await ethers.getContractFactory("MonopolyGame");
  const game = await Game.deploy(
    [player1.address, player2.address],
    board.target,
    property.target
  );
  await game.waitForDeployment();
  await (await property.setGame(game.target)).wait();

  //Tranfer initial ownership of tax office to tax officials
  const wallet = ethers.Wallet.createRandom();
  const tax_address = wallet.address;
  await game.setOwner(7, tax_address);
  await game.setOwner(17,tax_address);

  //Initial game setup done by user
  console.log(`\n👤 Player 1: ${player1.address}`);
  console.log(`👤 Player 2: ${player2.address}`);
  console.log("💰 Starting balance: 4000 each\n");
  const regex = /^\d+$/; 
  let maxRound = readline.question("How many rounds do you want to play? (a positive integer): ");
  while (!regex.test(maxRound)){
    maxRound = readline.question("Invalid input. How many rounds do you want to play? (a positive integer): ");
  }
  let num = parseInt(maxRound);

// Game loop
  while (await game.round() <= num && Number(await game.gameState()) === 0) {
    
//print board before each round
    const names = [];
    const levels = [];
    const owners = [];
    for (let position = 4; position >= 0; position-=1) {const name = await game.getPropertyName(position);const level = await game.getLevel(position);const owner = await game.getOwner(position);names.push(name);levels.push(level.toString());owners.push(owner);} 
    for (let position = 5; position < 20; position++) {
    const name = await game.getPropertyName(position);
    const level = await game.getLevel(position);
    const owner = await game.getOwner(position);
    names.push(name);
    levels.push(level.toString());
    owners.push(owner);
    }
    printBoard(names, levels, owners);

//Set current state variable for later reference
    const currentPlayerIndex = Number(await game.currentPlayer());
    const currentPlayerData = await game.players(currentPlayerIndex);
    const currentPlayerAddr = currentPlayerData.addr;
    const currentSigner = currentPlayerAddr === player1.address ? player1 : player2;
    const balance_before = await game.getBalance(currentPlayerAddr);

    console.log(`\n=== Player ${currentPlayerIndex + 1}'s Turn ===`);
    console.log(`📍 Position: ${Number(currentPlayerData.position)}`);
    console.log(`💰 Balance: ${Number(currentPlayerData.balance)}`);
    
    // Roll dice
    readline.question("🎲 Press ENTER to roll dice...");
    const diceRoll = await game.connect(currentSigner).rollDice();
    const newPosition = Number((await game.players(currentPlayerIndex)).position);
    const newLandName = (await game.getPropertyName(newPosition));
    console.log(`\n🛣️ Landed on \"${newLandName}\", position ${newPosition}`);

    //Check is ther's bonus
    if (await game.bonus()){
        console.log("🎉 Congrats! You successfully finish another round and receive 500 Bonus!")
        await game.changeBonus();
    }
    const pos_level = await game.getLevel(newPosition);
    const propertyOwner = await game.propertyOwner(newPosition);

//For property available for purchase
    if (propertyOwner === ethers.ZeroAddress && await game.canBuy()) {
        const price = Number(await board.getPrice(newPosition));
        const currentBalance = Number(await game.getBalance(currentPlayerAddr));
        console.log(`🏚️ Property available for ${price}`);
        console.log(`💳 Your balance: ${currentBalance}`);
    
        if (currentBalance < price) {
            console.log("❌ Insufficient balance to purchase");
            // Auto-pass turn if can't afford
            console.log("🔄 Passing turn to next player");
            await game.connect(currentSigner).changeTurn();
        } else {
            let answer = readline.question("Buy? (y/n): ").toLowerCase();
            while (answer !== 'y' && answer !== 'n'){
                answer = readline.question("Invalid Input, please choose again: Buy? (y/n): ").toLowerCase();
            }
            if (answer === 'y') {
                const tx = await game.connect(currentSigner).buyProperty();
                await tx.wait();
                console.log(`✅ Purchased! New balance: ${currentBalance-price}`);
            } else {
                await game.connect(currentSigner).changeTurn();
                console.log("🔄 Passing turn to next player");
            }
        }
    } 
// For property of others
    else if (propertyOwner !== currentPlayerAddr) {
      //Pay tax
        if (newPosition%10===7){
            let t_price = BigInt(await(game.getRentPrice(newPosition)));
            t_price = t_price / BigInt(2);
            console.log(`💸 Tax price of the property: ${t_price}`);
            console.log("💸 Paid tax to the tax officials.");
        }
        //Pay tuition fee
        else if (newPosition===1){
            console.log(`💸 Tuition fee of HKU Course FITE2010: ${await(game.getRentPrice(newPosition))}`);
            console.log("💸 Paid tuition fee to Liu Qi.");
        }
        //Pay rent
        else{
            console.log(`💸 Rent price of the property: ${await(game.getRentPrice(newPosition))}`);
            console.log("💸 Paid rent to owner.");
        }
        let new_balance = Number(await game.getBalance(currentPlayerAddr));
        const str = new_balance.toString();
        if (str.startsWith('999')) {
            // Extract the number without the leading 9's
            const extractedNum = str.slice(3); // Use `str` instead of `strNum`
            // Convert back to a number and return with a negative sign
            new_balance = -Number(extractedNum); // Convert extracted string to number
        }
        console.log(`New balance: ${new_balance}`);
    }
    //Moving to property owned by player
    else {
        console.log(`🏚️ You own the property. Current Level: ${pos_level}`);
        console.log(`💳 Your balance: ${await Number(await game.getBalance(currentPlayerAddr))}`);
        const up_price = await game.getUpgradePrice(newPosition);
        if (pos_level ===4){
            console.log("This property is already at the max level.")
        }else if(await game.getBalance(currentPlayerAddr) < up_price){
            console.log(`Price for upgrade this property: ${up_price}`);
            console.log("❌ Insufficient balance to upgrade");
        }else{
            console.log(`Price for upgrade this property: ${up_price}`);
            let answer = readline.question("Upgrade? (y/n): ").toLowerCase();
            while (answer!=='n' && answer!=='y'){
                answer = readline.question("Invalid Input, please choose again: Update? (y/n): ").toLowerCase();
            }
            if (answer==='y'){
                game.connect(currentSigner).upgradeProperty();
                console.log(`✅ Upgraded! New balance: ${await Number(await game.getBalance(currentPlayerAddr))}`);
                console.log(`The property is upgraded to Level ${await game.getLevel(newPosition)} with rent price ${await game.getRentPrice(newPosition)}`);
            }
        }
        console.log("🔄 Passing turn to next player");
        await game.connect(currentSigner).changeTurn();
    }
    console.log("\n" + "=".repeat(40));
  }
  
//If we move out of game loop, this indicates bankrupt or reaching maximum round  --> We have a winner
  const winner = await game.getWinner();
  console.log("\nGame Over!");
  if (Number(await game.gameState()) ===1){
    console.log("💀 You went Bankrupt!");
  }else{
    console.log(`Player 1 Total Asset ${await game.calcAsset(player1.address)}`);
    console.log(`Player 2 Total Asset ${await game.calcAsset(player2.address)}`);
  }
  console.log(`Winner: 🏆 Player ${winner === player1.address ? 1 : 2}`);
}

//Function used for board_printing with color
function printBoard(names, levels, owners) {
  const GRID_ROWS = 9;
  const GRID_COLS = 5;
  const CELL_WIDTH = 24;     
  const CELL_HEIGHT = 5;     
  const COL_SPACING = 1;    

  const COLORS = {
    "Player 1": "\x1b[31m",      
    "Player 2": "\x1b[96m",      
    "Tax Officials": "\x1b[34m", 
    "reset": "\x1b[0m"
  };

  
  const POSITION_MAP = [    
    { row: 0, col: 4 }, { row: 0, col: 3 }, { row: 0, col: 2 }, { row: 0, col: 1 }, { row: 0, col: 0 },

    { row: 1, col: 4 }, { row: 2, col: 4 }, { row: 3, col: 4 }, { row: 4, col: 4 }, { row: 5, col: 4 },
    
    { row: 6, col: 4 }, { row: 6, col: 3 }, { row: 6, col: 2 }, { row: 6, col: 1 }, { row: 6, col: 0 },
    
    { row: 5, col: 0 }, { row: 4, col: 0 }, { row: 3, col: 0 }, { row: 2, col: 0 }, { row: 1, col: 0 }
  ];

  const totalWidth = GRID_COLS * (CELL_WIDTH + COL_SPACING);
  let boardGrid = Array(GRID_ROWS * CELL_HEIGHT).fill().map(() => 
    Array(totalWidth).fill(' ')
  );

  // Go through all lands
  for (let position = 0; position < 20; position++) {
    const { row, col } = POSITION_MAP[position];
    const startX = col * (CELL_WIDTH + COL_SPACING);
    const startY = row * CELL_HEIGHT;


    let displayPos = position;
    if (position < 5) displayPos = 4 - position; 

    // get color based on property owner
    const owner = owners[position];
    const color = COLORS[owner] || COLORS.reset;
    const name = `${color}${names[position].slice(0, 17).padEnd(17)}${COLORS.reset}`;
    const ownerText = `${color}${formatOwner(owner).padEnd(15)}${COLORS.reset}`;
    const level = `${color}Position: ${displayPos}, Lv${levels[position]}${COLORS.reset}`;

    //draw all the cells
    drawCell(
      boardGrid,
      startX,
      startY,
      CELL_WIDTH,
      CELL_HEIGHT,
      [name, ownerText, level]
    );
  }

  // print out board
  console.log('\n' + '═'.repeat(totalWidth + 2));
  boardGrid.forEach(line => console.log(' ' + line.join('') + ' '));
  console.log('═'.repeat(totalWidth + 2) + '\n');

  // helper function for formatting
  function formatOwner(owner) {
    return owner.startsWith("0x") 
      ? owner.slice(0, 4) + '...' + owner.slice(-4)
      : owner;
  }
}

// function used to draw each cell
function drawCell(grid, startX, startY, width, height, content) {
  const borderTop = '┌' + '─'.repeat(width - 2) + '┐';
  const borderBottom = '└' + '─'.repeat(width - 2) + '┘';
  const borderSide = '│';

  // Upper frame
  grid[startY].splice(startX, width, ...borderTop.split(''));

  // content + color
  content.forEach((line, index) => {
    const y = startY + 1 + index;
    const rawLength = line.replace(/\x1b\[\d+m/g, '').length;
    const padding = ' '.repeat(width - 2 - rawLength);
    grid[y].splice(startX, width, borderSide + line + padding + borderSide);
  });

  // lower frame
  grid[startY + height - 1].splice(startX, width, ...borderBottom.split(''));
}


main().catch(console.error);
