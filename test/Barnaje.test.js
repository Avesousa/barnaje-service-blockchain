const Barnaje = artifacts.require('Barnaje');
const TestUSDT = artifacts.require('TestUSDT');

const { expect } = require('chai');
const { BN } = require('web3-utils');

contract('Barnaje', ([deployer, user1, user2]) => {
  let barnaje;
  let testUsdt;

  beforeEach(async function () {
    // Desplegar el contrato TestUSDT
    testUsdt = await TestUSDT.new({ from: deployer });

    // Dar algunos tokens a los usuarios
    await testUsdt.transfer(user1, (6050 * 10**6).toString(), { from: deployer });
    await testUsdt.transfer(user2, (6050 * 10**6).toString(), { from: deployer });

    // Desplegar el contrato Barnaje
    barnaje = await Barnaje.new(testUsdt.address, { from: deployer });
  });

  describe('donate()', function () {
    it('donates the correct amount', async function () {
      const amount = new BN((50 * 10**6).toString());

      // Deposit the tokens to Barnaje
      await testUsdt.approve(barnaje.address, amount, { from: user1 });
      await barnaje.deposit(amount, { from: user1 });

      const initialBalanceUser1 = await testUsdt.balanceOf(user1);
      const initialBalanceSponsor = await testUsdt.balanceOf(user2);

      // Make the donation
      await barnaje.donate(user2, { from: user1 });

      const finalBalanceUser1 = await testUsdt.balanceOf(user1);
      const finalBalanceSponsor = await testUsdt.balanceOf(user2);

      expect(finalBalanceUser1).to.be.bignumber.equal(initialBalanceUser1.sub(amount));
      expect(finalBalanceSponsor).to.be.bignumber.equal(initialBalanceSponsor.add(amount));
    });
  });
});
