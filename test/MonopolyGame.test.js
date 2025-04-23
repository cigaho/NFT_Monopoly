const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Monopoly Game", function () {
  let skipLabToken;
  let monopolyProperty;
  let monopolyGame;
  let owner;
  let player1;
  let player2;

  before(async function () {
    [owner, player1, player2] = await ethers.getSigners();

    // Deploy $SKIPLAB Token (ERC20)
    const SkipLabToken = await ethers.getContractFactory("SkipLabToken");
    skipLabToken = await SkipLabToken.deploy(ethers.utils.parseEther("1000000"));
    await skipLabToken.deployed();

    // Deploy Property NFTs (ERC721)
    const MonopolyProperty = await ethers.getContractFactory("MonopolyProperty");
    monopolyProperty = await MonopolyProperty.deploy();
    await monopolyProperty.deployed();

    // Deploy Main Game Contract
    const MonopolyGame = await ethers.getContractFactory("MonopolyGame");
    monopolyGame = await MonopolyGame.deploy(skipLabToken.address, monopolyProperty.address);
    await monopolyGame.deployed();

    // Transfer NFT contract ownership to the game
    await monopolyProperty.transferOwnership(monopolyGame.address);
  });

  describe("$SKIPLAB Token (ERC20)", function () {
    it("Should mint initial supply to owner", async function () {
      expect(await skipLabToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("1000000"));
    });

    it("Should allow transfers between players", async function () {
      await skipLabToken.transfer(player1.address, ethers.utils.parseEther("100"));
      expect(await skipLabToken.balanceOf(player1.address)).to.equal(ethers.utils.parseEther("100"));
    });
  });

  describe("Property NFTs (ERC721)", function () {
    it("Should let the game contract mint properties", async function () {
      await monopolyGame.connect(owner).addProperty("Boardwalk", ethers.utils.parseEther("400"), ethers.utils.parseEther("50"), "blue");
      expect(await monopolyProperty.ownerOf(1)).to.equal(monopolyGame.address);
    });

    it("Should store property metadata correctly", async function () {
      const property = await monopolyProperty.getPropertyDetails(1);
      expect(property.name).to.equal("Boardwalk");
      expect(property.price).to.equal(ethers.utils.parseEther("400"));
    });
  });

  describe("Game Mechanics", function () {
    before(async function () {
      // Players join the game
      await monopolyGame.connect(player1).joinGame();
      await monopolyGame.connect(player2).joinGame();
    });

    it("Should give starting money to new players", async function () {
      expect(await skipLabToken.balanceOf(player1.address)).to.equal(ethers.utils.parseEther("1500"));
    });

    it("Should allow property purchases", async function () {
      await skipLabToken.connect(player1).approve(monopolyGame.address, ethers.utils.parseEther("400"));
      await monopolyGame.connect(player1).buyProperty(1);
      expect(await monopolyProperty.ownerOf(1)).to.equal(player1.address);
    });

    it("Should enforce rent payments", async function () {
      const initialBalance = await skipLabToken.balanceOf(player2.address);
      await skipLabToken.connect(player2).approve(monopolyGame.address, ethers.utils.parseEther("50"));
      await monopolyGame.connect(player2).payRent(1);
      expect(await skipLabToken.balanceOf(player2.address)).to.equal(initialBalance.sub(ethers.utils.parseEther("50")));
      expect(await skipLabToken.balanceOf(player1.address)).to.equal(ethers.utils.parseEther("1100"));
    });

    it("Should track player movement", async function () {
      await monopolyGame.connect(player1).movePlayer(5);
      const player = await monopolyGame.players(player1.address);
      expect(player.position).to.equal(5);
    });
  });

  describe("Edge Cases", function () {
    it("Should prevent buying owned properties", async function () {
      await expect(
        monopolyGame.connect(player2).buyProperty(1)
      ).to.be.revertedWith("Property not available");
    });

    it("Should prevent rent payments to self", async function () {
      await expect(
        monopolyGame.connect(player1).payRent(1)
      ).to.be.revertedWith("Invalid rent payment");
    });
  });
});
