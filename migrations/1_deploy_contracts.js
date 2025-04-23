// migrations/1_deploy_contracts.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // 1. 部署ERC20代币合约
  const SkipLabToken = await ethers.getContractFactory("SkipLabToken");
  const token = await SkipLabToken.deploy(ethers.utils.parseEther("1000000"));
  await token.deployed();
  console.log("SkipLabToken deployed to:", token.address);

  // 2. 部署NFT房产合约
  const MonopolyProperty = await ethers.getContractFactory("MonopolyProperty");
  const property = await MonopolyProperty.deploy();
  await property.deployed();
  console.log("MonopolyProperty deployed to:", property.address);

  // 3. 部署游戏面板合约（新增）
  const Board = await ethers.getContractFactory("Board");
  const board = await Board.deploy(property.address, token.address);
  await board.deployed();
  console.log("Board deployed to:", board.address);

  // 4. 部署主游戏合约（修改构造函数）
  const MonopolyGame = await ethers.getContractFactory("MonopolyGame");
  const game = await MonopolyGame.deploy(
    token.address,
    property.address,
    board.address // 新增参数
  );
  await game.deployed();
  console.log("MonopolyGame deployed to:", game.address);

  // 5. 配置权限系统（新增关键步骤）
  console.log("\nConfiguring permissions...");
  
  // 转移NFT合约所有权给游戏合约
  await property.transferOwnership(game.address);
  console.log("Transferred MonopolyProperty ownership to game contract");

  // 转移面板合约所有权给游戏合约
  await board.transferOwnership(game.address);
  console.log("Transferred Board ownership to game contract");

  // 设置房产合约的游戏合约地址
  await property.setGameContract(game.address);
  console.log("Configured game contract in property contract");

  // 授予游戏合约代币操作权限（新增）
  const GAME_ROLE = await token.GAME_ROLE();
  await token.grantRole(GAME_ROLE, game.address);
  console.log("Granted game contract token privileges");

  // 6. 初始化游戏数据（可选）
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
      position: 1 // 新增位置参数
    },
    // 其他房产数据...
  ];

  for (const prop of properties) {
    await gameContract.addProperty(
      prop.name,
      prop.price,
      prop.rent,
      prop.color,
      prop.position // 新增参数
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });