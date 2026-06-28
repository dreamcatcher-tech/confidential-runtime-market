require("dotenv").config();
require("@nomicfoundation/hardhat-ethers");

function accounts() {
  const key = process.env.DEPLOYER_PRIVATE_KEY || process.env.WALLET_PRIVATE_KEY || process.env.PRIVATE_KEY;
  return key ? [key] : [];
}

function network(url) {
  const acct = accounts();
  return url && acct.length ? { url, accounts: acct } : undefined;
}

const networks = {
  hardhat: {
    chainId: 31337,
  },
};

const sepolia = network(process.env.SEPOLIA_RPC_URL || process.env.ETHEREUM_SEPOLIA_RPC_URL);
if (sepolia) networks.sepolia = sepolia;

const baseSepolia = network(process.env.BASE_SEPOLIA_RPC_URL);
if (baseSepolia) networks.baseSepolia = baseSepolia;

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 }
    }
  },
  networks,
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
