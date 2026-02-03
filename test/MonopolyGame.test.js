const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MonopolyGame", function () {
  let game, property, board;
  let owner, player1, player2;

  before(async () => {
    [owner, player1, player2] = await ethers.getSigners();

    // deploy the board
    const Board = await ethers.getContractFactory("Board");
    board = await Board.deploy();
    await board.waitForDeployment();
    

    //deploy property
    const Property = await ethers.getContractFactory("MonopolyProperty");
    property = await Property.deploy();
    await property.waitForDeployment();
    
    // deploy game
    const Game = await ethers.getContractFactory("MonopolyGame");
    game = await Game.deploy(
      [player1.address, player2.address],
      board.target,
      property.target
    );
    await game.waitForDeployment();
    await (await property.setGame(game.target)).wait();
  });

  //Test 1: initialize user
  it("Should initialize users properly", async () => {
    const p1 = await game.players(0);
    const p2 = await game.players(1);
    expect(p1.addr).to.equal(player1.address);
    expect(p2.addr).to.equal(player2.address);
    
    // check initial balance
    expect(await game.getBalance(player1.address)).to.equal(4000);
    expect(await game.getBalance(player2.address)).to.equal(4000);
  });

  //Test 2: handle property purchase properly
  it("Should handle property purchase properly", async () => {
    // Setup Player
    await (await game.debugForceSetup(
      player1.address,
      5,     
      2000,  
      true   
    ));
    
    // purchase
    await (await game.connect(player1).buyProperty());
    
    // Outcomes
    expect(await property.ownerOf(5)).to.equal(player1.address);
    expect(await game.currentPlayer()).to.equal(1);
    expect(await game.getBalance(player1.address)).to.equal(1450); 
    expect(await game.getPrice(6)).to.equal(400);
  });

  //Test 3: Rent or tax deduction
  it("Should handle rent and tax peyment properly", async () => {
    // Set up player1 property
    await (await game.debugForceSetup(
      player1.address,
      5,
      2000,
      false
    ));
    
    // Set up player 2
    await (await game.debugForceSetup(
      player2.address,
      5,     
      2000,
      true
    ));

    // trigger rent transaction
    const beforeBalance = await game.getBalance(player2.address);
    await (await game.connect(player2).debugMovePlayer(player2.address, 0));
    
    // verify outcome
    expect(await game.getBalance(player2.address)).to.equal(1700);
    expect(await game.getBalance(player1.address)).to.equal(2300);
  });


  //Test 4: property upgrade
  it("Should handle property upgrade properly", async () => {
    await (await game.debugForceSetup(
      player1.address,
      5,     
      2000, 
      true   
    ));
    
    // upgrade
    await (await game.connect(player1).upgradeProperty());
    
    // verify
    expect(await game.getRentPrice(5)).to.equal(600);
    expect(await game.getLevel(5)).to.equal(2);
    expect(await game.getBalance(player1.address)).to.equal(1725);
    expect(await game.getAsset(player1.address)).to.equal(825);
});

//Test 5: check reward 
it("Should offer reward properly", async () => {
    await (await game.debugForceSetup(
      player1.address,
      19,     
      2000,  
      true   
    ));
    
    // pass the start point
    await (await game.connect(player1).rollDice());

    // verify balance
    expect(await game.getBalance(player1.address)).to.equal(2500);
});


//Test 6: handle game end
  it("Should end game when player went bankrupt", async () => {
    await (await game.debugForceSetup(
      player1.address,
      19,     
      2000,  
      true   
    ));
    await (await game.connect(player1).buyProperty());

    //Player 2, about to go bankrupt
    await (await game.debugForceSetup(
      player2.address,
      18, 
      1,    
      true
    ));

    // trigger rent payment
    await (await game.connect(player2).debugMovePlayer(player2.address, 1));
    
    // verify game end
    expect(await game.gameState()).to.equal(1); // 1 = GameState.ENDED
  });
});
