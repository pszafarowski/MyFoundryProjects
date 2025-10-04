# MyFoundryProjects
This repository is a collection of smart contract projects built with **Foundry**. It includes a variety of decentralized applications, from a simple fund-me contract and a provably fair raffle using **Chainlink VRF**, to custom **ERC20** and **ERC721** tokens, and a full-fledged stablecoin system.

---

### fund-me
A simple smart contract for collecting funds on the Ethereum blockchain. It utilizes **Chainlink Data Feeds** to verify a minimum contribution amount in USD and allows only the owner to withdraw the collected funds.

---

### raffle
This project is a simple raffle smart contract using **Chainlink VRF 2.5** to generate a verifiable random winner. It includes an `enterRaffle` function for participants and a `checkUpkeep` function to determine if the conditions for picking a winner have been met. The contract handles the state of the raffle, from open to calculating, and transfers all collected funds to the randomly selected winner.

---

### my-nft
This project contains two different NFT contracts built with **OpenZeppelin's ERC721**. `BasicNft.sol` is a standard NFT that allows you to mint a token with a specific URI. `MoodNft.sol` is a more dynamic NFT where the owner can change the token's mood between happy and sad, which in turn updates its image.

---

### stable-coin
This project is an exogenous, decentralized, and crypto-collateralized stablecoin system. It consists of three main contracts: `DSCEngine.sol`, which is the core logic for minting, redeeming, and liquidating collateral; `DecentralizedStableCoin.sol`, which is the **ERC20** token itself; and the `OracleLib.sol` library, which ensures that prices from Chainlink are not stale before being used in calculations. The system is designed to be over-collateralized and pegged to the US Dollar.

