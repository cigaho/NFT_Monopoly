// migrations/1_deploy_contracts.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // 1. deploy ERC20 token contracts
  const SkipLabToken = await ethers.getContractFactory("SkipLabToken");
  const token = await SkipLabToken.deploy(ethers.utils.parseEther("1000000"));
  await token.deployed();
  console.log("SkipLabToken deployed to:", token.address);

  // 2. deploy NFT property contracts
  const MonopolyProperty = await ethers.getContractFactory("MonopolyProperty");
  const property = await MonopolyProperty.deploy();
  await property.deployed();
  console.log("MonopolyProperty deployed to:", property.address);

  // 3. deploy game board contracts
  const Board = await ethers.getContractFactory("Board");
  const board = await Board.deploy(property.address, token.address);
  await board.deployed();
  console.log("Board deployed to:", board.address);

  // 4. deploy game contracts
  const MonopolyGame = await ethers.getContractFactory("MonopolyGame");
  const game = await MonopolyGame.deploy(
    token.address,
    property.address,
    board.address 
  );
  await game.deployed();
  console.log("MonopolyGame deployed to:", game.address);

  // 5. Set access system
  console.log("\nConfiguring permissions...");
  
  // transfer NFT ownership to game contracts
  await property.transferOwnership(game.address);
  console.log("Transferred MonopolyProperty ownership to game contract");

  // transfer board contracts ownership to game contracts
  await board.transferOwnership(game.address);
  console.log("Transferred Board ownership to game contract");

  // set property's address
  await property.setGameContract(game.address);
  console.log("Configured game contract in property contract");

  // access token manipulation
  const GAME_ROLE = await token.GAME_ROLE();
  await token.grantRole(GAME_ROLE, game.address);
  console.log("Granted game contract token privileges");

  // 6. Initialize game data
  console.log("\nInitializing game data...");
  await initializeDefaultProperties(game);
  console.log("Default properties initialized");

  console.log("\nFinal deployment addresses:");
  console.log("----------------------------------");
  console.log("SkipLabToken (ERC20):", token.address);
  console.log("MonopolyProperty (ERC721):", property.address);
  console.log("Board Contract:", board.address);
  console.log("MonopolyGame (Main Logic):", game.address);
  console.log("----------------------------------");
}

async function initializeDefaultProperties(gameContract) {
  const properties = [
    {
      name: "Mediterranean Avenue",
      price: ethers.utils.parseEther("60"),
      rent: ethers.utils.parseEther("2"),
      color: "brown",
      position: 1 
    },
  ];

  for (const prop of properties) {
    await gameContract.addProperty(
      prop.name,
      prop.price,
      prop.rent,
      prop.color,
      prop.position 
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);

  });
