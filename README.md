# NFT_Monopoly

## 📋 Project Overview
**Group Members:**
- Huang Yingrui 
- Wang Yankai 

This README introduces the NFT Monopoly game, covers the project's key features, and provides instructions for setting up and playing the game. We hope you enjoy playing NFT Monopoly on the blockchain!

---

## 🎮 Game Introduction

At the start, each player receives **4000 tokens** for property purchase/upgrades or rent/tax payments.

When a player lands on a position, the following occurs:

1. **Vacant Property**: Player is asked whether to buy the property
2. **Own Property**: Player is asked whether to upgrade the owned property (unless it's at max level)
3. **Other's Property**: Player must pay rent to the property owner
4. **Tax Office**: Player must pay tax issued by the tax office

**Key Mechanics:**
- Higher property levels yield higher rent from other players
- Each time someone lands on the tax office, the tax price increases
- **Bankruptcy** (negative balance) results in immediate loss
- Players can customize the number of rounds to play
- Players receive **500 tokens** as a round-based award when passing the starting position
- If no one goes bankrupt after the specified rounds, the winner is determined by **total assets** (Property At Cost + Balances)

---

## 💡 Innovation & Originality

Our NFT Monopoly project brings classic board gaming to blockchain with innovative features:

1. **Digitized Economy**: Combines ERC-721 properties with ERC-20 native tokens ("$SKIPLAB") for a unique gaming economy
2. **Negative Balance Representation**: Novel system using prefix patterns (999 prefix) to represent negative balances
3. **On-chain Experience**: Optimal balance between on-chain operations and local computation for seamless gameplay
4. **Atmospheric Game Setting**: Properties named after MTR stations with realistic buy/rent prices

---

## ⚙️ Smart Contract Functionality

### Core Features Implemented
- ✅ Player movement with dice rolls
- ✅ Property purchasing as NFTs
- ✅ Rent collection mechanics
- ✅ Property upgrading system
- ✅ Bankruptcy detection
- ✅ Turn-based gameplay
- ✅ Round tracking and bonuses

### Best Practices Followed
- ✅ Solidity 0.8.x for built-in overflow protection
- ✅ Clear separation of concerns between contracts
- ✅ Proper access control modifiers
- ✅ Event emission for all major actions
- ✅ View functions for game state inspection
- ✅ Safe arithmetic operations
- ✅ Comprehensive input validation

---

## 🔐 Code Quality & Security

### Source Code Structure

**Solidity Contracts:**
- `MonopolyGame.sol`: Game configuration, trade protocols, turn handling, and player management
- `Board.sol`: Property data, position management, upgrade logic
- `MonopolyProperty.sol`: NFT implementation for properties
- `SkipLabToken.sol`: ERC-20 implementation for custom tokens

**JavaScript Files:**
- `game.js`: Main game logistics, I/O handling, and hardhat/terminal interaction
- `MonopolyGame.test.js`: Comprehensive test cases

### Security Measures
1. **Secure Transaction Flow**: Property transfers/upgrades only after transaction confirmation
2. **Reentrancy Protection**: Checks-effects-interactions pattern implementation
3. **Overflow Protection**: Solidity 0.8.x built-in protection
4. **Access Control**: `onlyCurrentPlayer` modifier enforcement
5. **Input Validation**: Validation on all public functions
6. **Secure Randomness**: Safe random number generation
7. **AFK Penalty**: Locks purchases/upgrades/rewards for inactive users while allowing mandatory payments

### Error Handling
- ✅ Custom error messages for revert conditions
- ✅ Balance checks before transactions
- ✅ State validation before actions
- ✅ Iterative valid input requests
- ✅ Clear failure modes for all operations

---

## 💻 Interaction & Usability

### Hardhat Integration
- ✅ Easy deployment scripts
- ✅ Clear test cases
- ✅ Simple interaction patterns
- ✅ Automated contract verification

### Terminal Interface
- ✅ Intuitive text-based UI
- ✅ Clear player prompts
- ✅ Visual game state display (color-coded messages, board visualization)
- ✅ Responsive input handling
- ✅ Automatic turn progression

---

## 🚀 Setup & Installation Instructions

### Step 1: Create Project Folder
- Create a project folder "NFT_Monopoly" as workspace
### Step 2: Create directories and files so that the workspace looks like this:
- //contracts
- Board.sol
- MonopolyGame.sol
- MonopolyProperty.sol
- SkipLabToken.sol
- //scripts:
- game.js
- //test:
- MonopolyGame.test.js
- //hardhat.config.js
- //package-lock.js
- //package.json
### Step 3: Copy Files
Copy and paste the submitted file contents into their respective locations.

### Step 4: Initialize & Configure
(cd to the workspace)
- npm init
- npm install
- npx hardhat compile

### Step 5: Test & Play

**Important**: Maximize your terminal to full screen before playing.

#### Option A: Run Tests
npx hardhat test

#### Option B: Play games
npx hardhat run scripts/game.js

#### Option C: Play with Local Blockchain
1. Open a new terminal and run:
- npx hardhat node
2. Return to the first terminal and run:
  - npx hardhat run scripts/game.js --network localhost
---

## 🎯 Quick Start Summary
1. **Clone/Create** the project structure
2. **Copy** provided files to correct locations
3. **Install** dependencies with `npm install`
4. **Compile** contracts with `npx hardhat compile`
5. **Test** with `npx hardhat test` or **Play** with `npx hardhat run scripts/game.js`

**Enjoy playing NFT Monopoly on the blockchain!**

> **Note**: For the best gaming experience, please maximize your terminal to full screen before starting the game.
