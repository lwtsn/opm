import { deployContract, MockProvider } from 'ethereum-waffle';
import PlayerArtifact from '../../artifacts/contracts/player/Player.sol/Player.json';
import PlayerStatsArtifact from '../../artifacts/contracts/player/PlayerStats.sol/PlayerStats.json';
import CashArtifact from '../../artifacts/contracts/Cash.sol/Cash.json';
import ShopArtifact from '../../artifacts/contracts/Shop.sol/Shop.json';
import SchemeManagerArtifact from '../../artifacts/contracts/Schemes/SchemeManager.sol/SchemeManager.json';
import TrainingArtifact from '../../artifacts/contracts/training/Training.sol/Training.json';
import JobArtifact from '../../artifacts/contracts/jobs/Jobs.sol/Jobs.json';
import TreasuryArtifact from '../../artifacts/contracts/player/Treasury.sol/Treasury.json';

import { SchemeManager, Cash, Player, PlayerStats, Shop, Training, Treasury, Jobs } from '../../typechain';

import { Signer } from 'ethers';
import { ethers } from 'hardhat';

let provider: MockProvider;

export function getProvider() {
  if (provider == undefined) {
    provider = new MockProvider();
  }
  return provider;
}

export async function getAccounts() {
  return await ethers.getSigners();
}

export async function deploySchemesContract(signer: Signer) {
  return (await deployContract(signer, SchemeManagerArtifact)) as SchemeManager;
}

export async function deployShopContract(signer: Signer) {
  return (await deployContract(signer, ShopArtifact)) as Shop;
}

export async function deployPlayerContract(signer: Signer) {
  return (await deployContract(signer, PlayerArtifact)) as Player;
}

export async function deployPlayerStatsContract(signer: Signer) {
  return (await deployContract(signer, PlayerStatsArtifact)) as PlayerStats;
}

export async function deployCashContract(signer: Signer) {
  return (await deployContract(signer, CashArtifact)) as Cash;
}

export async function deployTrainingContract(signer: Signer) {
  return (await deployContract(signer, TrainingArtifact)) as Training;
}

export async function deployTreasuryContract(signer: Signer) {
  return (await deployContract(signer, TreasuryArtifact)) as Treasury;
}
export async function deployJobContract(signer: Signer) {
  return (await deployContract(signer, JobArtifact)) as Jobs;
}

export async function mineBlock() {
  await getProvider().send('evm_mine', []);
}

export async function wait(secondsToWait: number) {
  // Update the clock
  await getProvider().send('evm_increaseTime', [secondsToWait]);

  // Process the block
  await mineBlock();
}

export async function getBlockTime() {
  return await getProvider()
    .getBlock(getBlockNumber())
    .then((block) => block.timestamp);
}

export async function getBlockNumber() {
  return await getProvider().getBlockNumber();
}
