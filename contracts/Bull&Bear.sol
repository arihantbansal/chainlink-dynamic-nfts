// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, KeeperCompatibleInterface, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    AggregatorV3Interface public priceFeed;

    VRFCoordinatorV2Interface public COORDINATOR;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint32 public callbackGasLimit = 500000; 
    uint64 public s_subscriptionId;
    bytes32 keyhash =  0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; // keyhash, see for Rinkeby https://docs.chain.link/docs/vrf-contracts/#rinkeby-testnet
    

    /**
      * Use an interval in seconds and a timestamp to slow execution of Upkeep
      */

    uint public /* immutable */ interval; 
    uint public lastTimeStamp;
    int256 public currentPrice;
    
    enum MarketTrend { BULL, BEAR }
    MarketTrend public currentMarketTrend = MarketTrend.BULL; 


    // IPFS URIs for the dynamic nft graphics/metadata.
    // NOTE: These connect to my IPFS Companion node.
    // You should upload the contents of the /ipfs folder to your own node for development.
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRsTqwTXXkV8rFAT4XsNPDkdZs5WxUx9E5KwFaVfYWjMv?filename=party_bull.json",
        "https://ipfs.io/ipfs/Qmc3ueexsATjqwpSVJNxmdf2hStWuhSByHtHK5fyJ3R2xb?filename=simple_bull.json"
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/QmQMqVUHjCAxeFNE9eUxf89H1b7LpdzhvQZ8TXnj4FPuX1?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmP2v34MVdoxLSFj1LbGW261fvLcoAsnJWHaBK238hWnHJ?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmZVfjuDiUfvxPM7qAvq8Umk3eHyVh7YTbFon973srwFMD?filename=simple_bear.json"
    ];
    
    event TokensUpdated(string marketTrend);


    // For testing with the mock on Rinkeby, pass in 10(seconds) for `updateInterval` and the address of my 
    // deployed  MockPriceFeed.sol contract (0xD753A1c190091368EaC67bbF3Ee5bAEd265aC420).
    constructor(uint updateInterval, address _priceFeed, address _vrfCoordinator) ERC721("Bull&Bear", "BBTK") VRFConsumerBaseV2(_vrfCoordinator) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;

        // set the price feed address to
        // BTC/USD Price Feed Contract Address on Rinkeby: https://rinkeby.etherscan.io/address/0xECe365B379E1dD183B20fc5f022230C044d51404
        priceFeed = AggregatorV3Interface(_priceFeed);

        currentPrice = getLatestPrice();
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function safeMint(address to) public {
        // Current counter value will be the minted token's token ID.
        uint256 tokenId = _tokenIdCounter.current();

        // Increment it so next time it's correct when we call .current()
        _tokenIdCounter.increment();

        // Mint the token
        _safeMint(to, tokenId);

        // Default to a bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);

        console.log(
            unicode"Done!🚀 minted token ",
            tokenId,
            " and assigned token url: ",
            defaultUri
        );
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /*performData */) {
         upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        // revalidating the upkeep
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;         
            int latestPrice =  getLatestPrice();
        
            if (latestPrice == currentPrice) {
                console.log("Just the same!");
                return;
            }

            if (latestPrice < currentPrice) {
                console.log(unicode"It's a bear market 🐻");
                currentMarketTrend = MarketTrend.BEAR;
            } else {
                console.log(unicode"It's a bull market 🐂");
                currentMarketTrend = MarketTrend.BULL;
            }

            requestRandomnessForNFTUris();
            currentPrice = latestPrice;
        } else {
            console.log("Not time to update yet. Last update was at ", lastTimeStamp);
            return;
        }
    }

    // Helpers
    function getLatestPrice() public view returns (int256) {
        (, int price,,,) = priceFeed.latestRoundData();
        return price; //  example price returned 3034715771688
    }

    function requestRandomnessForNFTUris() internal {
      s_requestId = COORDINATOR.requestRandomWords(
        keyhash,
        s_subscriptionId,
        3, // min confirmations before response
        callbackGasLimit,
        1 // number of random values we want
      );

      console.log("Request ID: ", s_requestId);
    }

    function fulfillRandomWords(
      uint256 /* requestId */,
      uint256[] memory randomWords
    ) internal override {
      s_randomWords = randomWords;

      console.log("Fulfilling randomness...");

      string[] memory urisForTrend = currentMarketTrend == MarketTrend.BULL ? bullUrisIpfs : bearUrisIpfs;
      uint256 idx = randomWords[0] % urisForTrend.length;

      for (uint i = 0; i < _tokenIdCounter.current() ; i++) {
        _setTokenURI(i, urisForTrend[idx]);
      } 

      string memory trend = currentMarketTrend == MarketTrend.BULL ? "bullish" : "bearish";
    
      emit TokensUpdated(trend);
    }
  
    function updateAllTokenUris(string memory trend) internal {
        if (compareStrings("bear", trend)) {
            console.log("UPDATING TOKEN URIS WITH ", "bear", trend);
            for (uint i = 0; i < _tokenIdCounter.current() ; i++) {
                _setTokenURI(i, bearUrisIpfs[0]);
            }
        } else {     
            console.log("UPDATING TOKEN URIS WITH ", "bull", trend);

            for (uint i = 0; i < _tokenIdCounter.current() ; i++) {
                _setTokenURI(i, bullUrisIpfs[0]);
            }
        }   
        emit TokensUpdated(trend);
    }

    function setPriceFeed(address newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(newFeed);
    }
    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setSubscriptionId(uint64 _id) public onlyOwner {
      s_subscriptionId = _id;
    }

    function setCallbackGasLimit(uint32 maxGas) public onlyOwner {
        callbackGasLimit = maxGas;
    }

    function setVrfCoodinator(address _address) public onlyOwner {
      COORDINATOR = VRFCoordinatorV2Interface(_address);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
