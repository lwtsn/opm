gimport { ItemBase, Player, Shop, Treasury } from '../typechain';
import { deployShopContract, getProvider } from './helpers/contract';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import ItemArtifact from '../artifacts/contracts/item/ItemBase.sol/ItemBase.json';
import TreasuryArtifact from '../artifacts/contracts/player/Treasury.sol/Treasury.json';
import { oneEther } from './helpers/numbers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';

const [alice] = getProvider().getWallets();

describe('Shop', () => {
  let shop: Shop;
  let item: ItemBase | MockContract;
  let treasury: Treasury | MockContract;

  beforeEach(async () => {
    shop = await deployShopContract(alice);

    item = await deployMockContract(alice, ItemArtifact.abi);
    treasury = await deployMockContract(alice, TreasuryArtifact.abi);

    await shop.setTreasuryContract(treasury.address);
  });

  it('Should allow listing of items', async () => {
    await shop.list(item.address, oneEther.mul(100));

    await shop.itemStructs(item.address).then((item: any) => {
      expect(item.listPointer).to.eq(0);
      expect(item.price).to.eq(oneEther.mul(100));
    });
  });

  it('Should allow an item to be updated', async () => {
    await shop.list(item.address, oneEther.mul(100));

    await shop.update(item.address, oneEther.mul(400));

    await shop.itemStructs(item.address).then((item: any) => {
      expect(item.listPointer).to.eq(0);
      expect(item.price).to.eq(oneEther.mul(400));
    });
  });

  it('Should allow an item to be deleted', async () => {
    await shop.list(item.address, oneEther.mul(100));

    await shop.remove(item.address);

    await shop.itemStructs(item.address).then((item: any) => {
      expect(item.listPointer).to.eq(0);
      expect(item.price).to.eq(oneEther.mul(0));
    });
  });

  it('Should allow multiple items to be added and a random element to be deleted', async () => {
    const item2 = await deployMockContract(alice, ItemArtifact.abi);
    const item3 = await deployMockContract(alice, ItemArtifact.abi);

    await shop.list(item.address, oneEther.mul(100));
    await shop.list(item2.address, oneEther.mul(500));
    await shop.list(item3.address, oneEther.mul(800));

    await shop.remove(item2.address);

    await shop.getItemCount().then((itemCount: BigNumber) => {
      expect(itemCount).to.eq(2);
    });

    await shop.itemStructs(item.address).then((item: any) => {
      expect(item.listPointer).to.eq(0);
      expect(item.price).to.eq(oneEther.mul(100));
    });

    await shop.itemStructs(item3.address).then((item: any) => {
      expect(item.listPointer).to.eq(1);
      expect(item.price).to.eq(oneEther.mul(800));
    });

    await shop.itemStructs(item2.address).then((item: any) => {
      expect(item.listPointer).to.eq(0);
      expect(item.price).to.eq(oneEther.mul(0));
    });
  });

  it('Should return a list of items', async () => {
    const item2 = await deployMockContract(alice, ItemArtifact.abi);
    const item3 = await deployMockContract(alice, ItemArtifact.abi);

    await shop.list(item.address, oneEther.mul(100));
    await shop.list(item2.address, oneEther.mul(500));
    await shop.list(item3.address, oneEther.mul(800));

    await shop.getItems().then((items: any) => {
      const addresses: string[] = items[0];
      const prices: string[] = items[1];

      expect(addresses[0]).to.eq(item.address);
      expect(addresses[1]).to.eq(item2.address);
      expect(addresses[2]).to.eq(item3.address);

      expect(prices[0]).to.eq(oneEther.mul(100));
      expect(prices[1]).to.eq(oneEther.mul(500));
      expect(prices[2]).to.eq(oneEther.mul(800));
    });
  });

  describe('Item purchasing', () => {
    it('Should allow purchasing of registered items', async () => {
      await treasury.mock.balances.withArgs(alice.address).returns(oneEther.mul(200));
      await treasury.mock.spendCash.withArgs(alice.address, oneEther.mul(100)).returns();
      await item.mock.mint.withArgs(alice.address, 1).returns();

      await shop.list(item.address, oneEther.mul(100));

      await shop.purchase(item.address, 1);
    });

    it('Should prevent purchasing items if player balance is too low', async () => {
      await treasury.mock.balances.withArgs(alice.address).returns(oneEther.mul(200));

      await shop.list(item.address, oneEther.mul(100));

      await expect(shop.purchase(item.address, 4)).to.be.revertedWith('Not enough funds');
    });
  });
});
