# Dynamic NFTs using Chainlink Keepers and VRF

This project mints Dynamic NFTs that change based on the market price of an asset pair (for example, the BTC/USD asset price). When prices go up, its a bull trend and when the go down its a bear trend. We run [Chainlink Keepers](https://docs.chain.link/docs/chainlink-keepers/introduction/) to have our smart contract automatically called at specified intervals so that on-chain logic checks the [Chainlink Price Feed](https://docs.chain.link/docs/using-chainlink-reference-contracts/) to see if there has been a change in price. Accordingly the minted NFTs dynamically alternate between three images.

Contract deployed to: [0xaFa4830d2b398cdaf8b8dccBdc4c27C76a1f9514](https://rinkeby.etherscan.io/address/0xaFa4830d2b398cdaf8b8dccBdc4c27C76a1f9514)
