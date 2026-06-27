# Cross-Chain Identity

> Unified identity across all blockchains

Cross-Chain Identity provides a single, portable digital identity that works across all EVM-compatible and non-EVM blockchains. Users control one identity that seamlessly bridges across Ethereum, Solana, Cosmos, and other networks—eliminating fragmented identity management.

## On-Chain Proof (Deployed & Verified)

### Base Sepolia (OP Stack)

| Contract | Address | Tx Hash |
|----------|---------|--------|
| **CrossChainIdentity** | [`0x4cBd...9995`](https://sepolia.basescan.org/address/0x4cBd36b8a58972d69294C751C62cfBa0B64b9995) | [`0xea82...7ad6`](https://sepolia.basescan.org/tx/0xea82d1ca1c5dbbf3cedf0a05f6d895d8dfea4e7d3f45871baa8bbeb42e1f7ad6) |
| **IdentityVerifier** | [`0xCcD3...E64A`](https://sepolia.basescan.org/address/0xCcD30AD16857DeBa2c14bA66A2FDd3bA445EE64A) | [`0x69c8...d049`](https://sepolia.basescan.org/tx/0x69c8bdf97e4d12c7fce2c963bd9c1f818962a4a3b4e3d261d1f0e77c691dd049) |

**Deployer**: [`0x7F75...C739`](https://sepolia.basescan.org/address/0x7F75bfAfeD5c96584774c7F2Bc33F3bF887BC739) | **Network**: Base Sepolia
## How It Works

1. **Identity Creation**: A user creates a master identity on Ethereum, linking their wallet address, verified credentials, and reputation scores. The identity is anchored as a soulbound NFT.

2. **Chain Registration**: The user registers their identity across target chains. Each chain receives a lightweight identity pointer (cross-chain message) that references the master identity on Ethereum.

3. **Cross-Chain Messages**: A relayer network (using LayerZero or CCIP) propagates identity updates, credential changes, and revocation events across all registered chains in near real-time.

4. **Universal Verification**: dApps on any chain can verify a user's identity by querying the local chain's identity contract, which resolves to the canonical on-chain identity via a cross-chain message.

5. **Identity Updates**: Users can update profile data, link new wallets, or revoke credentials. Changes are automatically synced across all chains through the relayer network.

## Smart Contracts

```
contracts/
├── CrossChainIdentity.sol         # Master identity contract (Ethereum)
├── ChainBridgeRegistry.sol        # Manages cross-chain identity pointers
├── IdentityVerifier.sol           # On-chain identity verification
├── AttestationHub.sol             # Aggregates attestations from multiple sources
├── relayers/
│   ├── LayerZeroRelayer.sol       # LayerZero integration
│   └── CCIPRelayer.sol            # Chainlink CCIP integration
├── interfaces/
│   ├── IIdentity.sol
│   └── IBridgeRelayer.sol
└── libraries/
    ├── ChainConfig.sol
    └── IdentityCodec.sol
```

### Key Features

- **Multi-Chain Identity**: One identity works across Ethereum, Solana, Cosmos, and all EVM chains.
- **Privacy-Preserving**: ZK proofs allow selective disclosure of identity attributes.
- **Portable Reputation**: Reputation scores earned on one chain are accessible on all chains.
- **Federated Attestations**: Third parties can attest to identity attributes (employment, KYC, education).
- **Recovery Mechanism**: Social recovery and multi-sig wallet recovery for identity restoration.

## Setup

### Prerequisites

- Node.js >= 18
- Foundry
- Wallet with testnet ETH

### Installation

```bash
git clone https://github.com/Souravjoy7/crosschain-identity.git
cd crosschain-identity
npm install
```

### Compile

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Environment Variables

```
RPC_URL=<your-rpc-url>
PRIVATE_KEY=<your-deployer-key>
ETHERSCAN_API_KEY=<your-etherscan-key>
LAYERZERO_ENDPOINT=<layerzero-endpoint-address>
CCIP_ROUTER=<ccip-router-address>
```

## License

MIT License. See [LICENSE](LICENSE) for details.
