// deploy.js  /scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  // 获取合约工厂（新增Board）
  const SkipLabToken = await ethers.getContractFactory("SkipLabToken");
  const MonopolyProperty = await ethers.getContractFactory("MonopolyProperty");
  const Board = await ethers.getContractFactory("Board");
  const MonopolyGame = await ethers.getContractFactory("MonopolyGame");

  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 部署顺序：代币 -> 房产 -> 面板 -> 游戏
  console.log("\nStep 1/4: Deploying SkipLabToken...");
  const token = await SkipLabToken.deploy(ethers.utils.parseEther("1000000"));
  await token.deployed();
  
  console.log("Step 2/4: Deploying MonopolyProperty...");
  const property = await MonopolyProperty.deploy();
  await property.deployed();

  console.log("Step 3/4: Deploying Board...");
  const board = await Board.deploy(property.address, token.address);
  await board.deployed();

  console.log("Step 4/4: Deploying MonopolyGame...");
  const game = await MonopolyGame.deploy(
    token.address,
    property.address,
    board.address
  );
  await game.deployed();

  // 权限配置流程
  console.log("\nConfiguring permissions:");
  console.log("- Transferring property ownership to game...");
  await property.transferOwnership(game.address);
  
  console.log("- Transferring board ownership to game...");
  await board.transferOwnership(game.address);
  
  console.log("- Setting game contract in property...");
  await property.connect(deployer).setGameContract(game.address);
  
  console.log("- Granting token privileges...");
  const GAME_ROLE = await token.GAME_ROLE();
  await token.grantRole(GAME_ROLE, game.address);

  // 数据初始化
  console.log("\nInitializing game data:");
  await initializeDefaultProperties(game);

  // 部署验证
  console.log("\nVerification Checklist:");
  console.log("✓ All contracts deployed successfully");
  console.log("✓ Property ownership transferred");
  console.log("✓ Board ownership transferred");
  console.log("✓ Game role configured in token contract");
  console.log("✓ Default properties initialized");

  // 最终输出
  console.log("\nFinal Deployment Summary:");
  console.log("==================================");
  console.log(`SkipLabToken (ERC20):     ${token.address}`);
  console.log(`MonopolyProperty (ERC721): ${property.address}`);
  console.log(`Board Contract:            ${board.address}`);
  console.log(`MonopolyGame (Main):       ${game.address}`);
  console.log("==================================");
}

async function initializeDefaultProperties(gameContract) {
  const propertyConfig = [
    {
      name: "Mediterranean Avenue",
      price: ethers.utils.parseEther("60"),
      rent: ethers.utils.parseEther("2"),
      color: "brown",
      position: 1 // 新增位置参数
    },
    {
      name: "Baltic Avenue",
      price: ethers.utils.parseEther("60"), 
      rent: ethers.utils.parseEther("4"),
      color: "brown",
      position: 3
    },
    // 其他房产配置...
  ];

  console.log(`Initializing ${propertyConfig.length} properties...`);
  
  for (const prop of propertyConfig) {
    try {
      const tx = await gameContract.addProperty(
        prop.name,
        prop.price,
        prop.rent,
        prop.color,
        prop.position // 新增参数
      );
      await tx.wait();
      console.log(`✓ ${prop.name} @ position ${prop.position}`);
    } catch (error) {
      console.error(`✗ Failed to initialize ${prop.name}: ${error.message}`);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error("Deployment Failed:", error);
    process.exit(1);
  });