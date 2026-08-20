# 💰 Decentralized Crowdfunding Smart Contract (FundMe)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-orange)](https://getfoundry.sh/)

A decentralized, gas-optimized crowdfunding smart contract built on Ethereum using Solidity and the [Foundry](https://getfoundry.sh/) development framework.

> 📚 **Educational Project**: This repository was built as a self-study learning project guided by the **Foundry Fundamentals** course on [Cyfrin Updraft](https://updraft.cyfrin.io/) by [Patrick Collins](https://github.com/PatrickAlphaC).

---

## 📌 Project Overview

The **FundMe** smart contract allows users to send ETH to fund a common treasury, enforcing a minimum funding threshold denominated in **USD** rather than ETH. Only the designated contract owner has the authority to withdraw the accumulated funds.

### 🌟 Key Features

1. **Real-Time Price Feeds**: Integrates **Chainlink Price Feeds (Data Feeds / `AggregatorV3Interface`)** to dynamically calculate the real-time ETH/USD exchange rate.
2. **Minimum USD Contribution**: Enforces a minimum contribution threshold (e.g. $5 USD) calculated using custom library functions (`PriceConverter`).
3. **Strict Access Control**: Protects administrative actions with an `onlyOwner` custom modifier and custom errors (`FundMe__NotOwner`) for gas efficiency.
4. **Gas Optimization (`cheaperWithdraw`)**: Implements storage-to-memory caching patterns to minimize costly EVM `SLOAD`/`SSTORE` operations during bulk fund withdrawals.
5. **Multi-Chain Deployment & Testing**: Configured with `HelperConfig` to seamlessly operate across local Anvil (using `MockV3Aggregator`), Sepolia testnet, and Ethereum mainnet.

---

## 🏗️ Architecture & Core Components

```
├── src/
│   ├── FundMe.sol                     # Core Crowdfunding Smart Contract
│   └── PriceConverter.sol             # Library for ETH/USD Price Conversion
├── script/
│   ├── DeployFundMe.s.sol             # Deployment script with network configuration
│   ├── HelperConfig.s.sol             # Multi-chain network configuration & Mock Price Feeds
│   └── Interactions.s.sol             # Scripts to fund and withdraw from the contract
└── test/
    ├── integration_test/
    │   └── IntegrationTest.t.sol      # Integration test suite
    ├── mocks/
    │   └── MockV3Aggregator.sol       # Mock Chainlink Price Feed for local testing
    └── unit_test/
        └── FundMeUnitsTest.t.sol      # Unit test suite
```

---

## 🚀 Getting Started

### Prerequisites

- [Git](https://git-scm.com/)
- [Foundry](https://getfoundry.sh/) (Run `foundryup` to ensure you are on the latest version)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/duongtm2003/foundry-fund-me.git
   cd foundry-fund-me
   ```

2. **Install dependencies:**
   ```bash
   forge install
   ```

3. **Environment Setup:**
   Copy `.env.example` to `.env` and fill in your private key and RPC URL:
   ```bash
   cp .env.example .env
   ```

---

## 🛠️ Usage

### Build
Compile the smart contracts:
```bash
forge build
```

### Test
Run the full test suite (Unit tests, Integration tests, and Fork tests):
```bash
# Run all unit tests locally
forge test

# Run tests with detailed call traces
forge test -vvvv

# Run tests on a Sepolia Fork
forge test --fork-url sepolia
```

### Gas Snapshots
Inspect gas consumption for contract functions:
```bash
forge snapshot
```

### Format Code
Format Solidity code style:
```bash
forge fmt
```

### Deploy to Sepolia Testnet
Deploy the contract to Sepolia testnet using Foundry script:
```bash
forge script script/DeployFundMe.s.sol:DeployFundMe \
  --rpc-url sepolia \
  --account <your_account_name> \
  --broadcast \
  --verify
```

---

## 📖 Acknowledgments & References

- **Course Platform**: [Cyfrin Updraft](https://updraft.cyfrin.io/) by [Patrick Collins](https://github.com/PatrickAlphaC)
- **Chainlink Data Feeds Documentation**: [Chainlink Price Feeds](https://docs.chain.link/data-feeds)
- **Foundry Book**: [getfoundry.sh](https://book.getfoundry.sh/)

---

## 📄 License

This project is open source and licensed under the [MIT License](https://opensource.org/licenses/MIT).
