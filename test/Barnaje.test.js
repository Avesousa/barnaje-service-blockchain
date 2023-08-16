const Barnaje = artifacts.require('Barnaje');
const TestUSDT = artifacts.require('TestUSDT');

const { expect } = require('chai');
const { BN } = require('web3-utils');

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Barnaje", function() {
    let Barnaje, barnaje, owner, addr1, addr2;
    beforeEach(async () => {
        Barnaje = await ethers.getContractFactory("Barnaje");
        [owner, addr1, addr2, _] = await ethers.getSigners();
        barnaje = await Barnaje.deploy();
        await barnaje.deployed();
    });

    it("Should deposit correctly", async function() {
        await barnaje.connect(addr1).deposit(100);
        let user = await barnaje.getUser(addr1.address);
        expect(user.balance).to.equal(100);
    });

    it("Should not allow deposit more than the balance", async function() {
        await expect(barnaje.connect(addr1).deposit(200)).to.be.reverted;
    });

    it("Should handle donation correctly", async function() {
        await barnaje.connect(addr1).deposit(100);
        await barnaje.connect(addr2).deposit(200);
        await barnaje.connect(addr1).donate(addr2.address);
        let user1 = await barnaje.getUser(addr1.address);
        let user2 = await barnaje.getUser(addr2.address);
        expect(user1.balance).to.equal(0);
        expect(user2.balance).to.equal(300);
    });

    it("Should not allow donation more than the balance", async function() {
        await barnaje.connect(addr1).deposit(100);
        await expect(barnaje.connect(addr1).donate(addr2.address)).to.be.reverted;
    });

    it("Should handle transfer correctly", async function() {
        await barnaje.connect(addr1).deposit(100);
        await barnaje.connect(addr1).transfer(addr2.address, 50);
        let user1 = await barnaje.getUser(addr1.address);
        let user2 = await barnaje.getUser(addr2.address);
        expect(user1.balance).to.equal(50);
        expect(user2.balance).to.equal(50);
    });

    it("Should not allow transfer more than the balance", async function() {
        await barnaje.connect(addr1).deposit(100);
        await expect(barnaje.connect(addr1).transfer(addr2.address, 200)).to.be.reverted;
    });

    it("Should create user correctly", async function() {
        await barnaje.createUser(addr1.address);
        let user = await barnaje.getUser(addr1.address);
        expect(user.isUser).to.be.true;
    });
});
