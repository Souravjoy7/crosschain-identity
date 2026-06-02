import hre from "hardhat";

async function main() {
  const { ethers } = await hre.network.connect();
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const networkName = chainId === 59141 ? "Linea" : chainId === 84532 ? "Base" : `Chain ${chainId}`;
  console.log(`Deploying to ${networkName} Sepolia (chainId: ${chainId})...`);
  console.log(`Deployer: ${deployer.address}`);
  const contracts = {};

  const CrossChainIdentityArtifact = await hre.artifacts.readArtifact("CrossChainIdentity");
  const cciFactory = new ethers.ContractFactory(CrossChainIdentityArtifact.abi, CrossChainIdentityArtifact.bytecode, deployer);
  const crossChainIdentity = await cciFactory.deploy();
  await crossChainIdentity.waitForDeployment();
  contracts.CrossChainIdentity = await crossChainIdentity.getAddress();
  console.log(`  CrossChainIdentity: ${contracts.CrossChainIdentity}`);

  const IdentityVerifierArtifact = await hre.artifacts.readArtifact("IdentityVerifier");
  const ivFactory = new ethers.ContractFactory(IdentityVerifierArtifact.abi, IdentityVerifierArtifact.bytecode, deployer);
  const identityVerifier = await ivFactory.deploy();
  await identityVerifier.waitForDeployment();
  contracts.IdentityVerifier = await identityVerifier.getAddress();
  console.log(`  IdentityVerifier: ${contracts.IdentityVerifier}`);

  const baseUrl = chainId === 59141 ? "https://sepolia.lineascan.build" : "https://sepolia.basescan.org";
  console.log(`\nVerify on ${networkName} Explorer:`);
  for (const [name, addr] of Object.entries(contracts)) {
    console.log(`  ${name}: ${baseUrl}/address/${addr}`);
  }
  console.log(JSON.stringify({ network: `${networkName.toLowerCase()}_sepolia`, chainId, deployer: deployer.address, contracts }, null, 2));
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });