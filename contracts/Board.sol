// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Board {
    //The struct defines the buyPrice, current rentPrice & property level for the land.
    struct LandPrice {
        uint256 buyPrice;
        uint256 rentPrice;
        uint256 level;
    }
    
    LandPrice[20] public basePrices;
    address public owner;
    mapping(uint256 => LandPrice) private _customPrices;
    mapping(uint256 => string) private _landNames;

    //construct the initial board
    constructor() {
        owner = msg.sender;
        initializeBasePrices();
        _initializeDefaultNames();
    }

    //set initial landprice, rentprice and level
    function initializeBasePrices() private {
        basePrices[0] = LandPrice(200, 100, 1);
        basePrices[1] = LandPrice(500, 2010, 1);
        basePrices[2] = LandPrice(350, 150, 1);
        basePrices[3] = LandPrice(700, 300, 1);
        basePrices[4] = LandPrice(500, 250, 1);
        basePrices[5] = LandPrice(550, 300, 1);
        basePrices[6] = LandPrice(400, 150, 1);
        basePrices[7] = LandPrice(200, 100, 1);
        basePrices[8] = LandPrice(650, 250, 1);
        basePrices[9] = LandPrice(300, 100, 1);
        basePrices[10] = LandPrice(300, 100, 1);
        basePrices[11] = LandPrice(600, 250, 1);
        basePrices[12] = LandPrice(350, 200, 1);
        basePrices[13] = LandPrice(200, 100, 1);
        basePrices[14] = LandPrice(250, 150, 1);
        basePrices[15] = LandPrice(450, 200, 1);
        basePrices[16] = LandPrice(600, 300, 1);
        basePrices[17] = LandPrice(300, 150, 1);
        basePrices[18] = LandPrice(650, 350, 1);
        basePrices[19] = LandPrice(400, 200, 1);
    }

    //Set property name
    function _initializeDefaultNames() private {
        _landNames[0] = "Start";
        _landNames[1] = "HKU";
        _landNames[2] = "Exhibition Center";
        _landNames[3] = "Central";
        _landNames[4] = "Admiralty";
        _landNames[5] = "Ocean Park";
        _landNames[6] = "South Horizons";
        _landNames[7] = "Tax Office";
        _landNames[8] = "Causeway Bay";
        _landNames[9] = "North Point";
        _landNames[10] = "City One";
        _landNames[11] = "Racecourse";
        _landNames[12] = "CUHK";
        _landNames[13] = "Austin";
        _landNames[14] = "Olympic";
        _landNames[15] = "World-Expo";
        _landNames[16] = "Airport";
        _landNames[17] = "Tax Office";
        _landNames[18] = "Disney Resort";
        _landNames[19] = "Kennedy Town";
    }

    //update new price and new level
    function upgrade(uint256 position) external {
        require(position < 20, "Invalid position");
        basePrices[position].rentPrice *= 2;
        basePrices[position].level += 1;
    }

    //obtain buyprice for vacant property
    function getPrice(uint256 position) external view returns (uint256) {
        if (_customPrices[position].buyPrice > 0) {
            return _customPrices[position].buyPrice;
        }
        return basePrices[position % 20].buyPrice;
    }

    //obtain rentprice for property at position
    function getRentPrice(uint256 position) external view returns (uint256) {
        if (_customPrices[position].rentPrice > 0) {
            return _customPrices[position].rentPrice;
        }
        return basePrices[position % 20].rentPrice;
    }

    //obtain property name
    function getLandName(uint256 position) external view returns (string memory) {
        require(position < 20, "Invalid position");
        return _landNames[position];
    }

    //obtain property level
    function getLevel(uint256 position) external view returns (uint256) {
        return _customPrices[position].level > 0 
            ? _customPrices[position].level 
            : basePrices[position % 20].level;
    }

    //restricted certain function to be called by property owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

}
