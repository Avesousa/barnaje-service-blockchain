const Barnaje = artifacts.require("Barnaje");
const TreeHandler = artifacts.require("TreeHandler");
const DonationHandler = artifacts.require("DonationHandler");
const SponsorHandler = artifacts.require("SponsorHandler");
const DaoWallet = artifacts.require("DaoWallet");
const TestUSDT = artifacts.require("TestUSDT");

module.exports = async function (deployer, network, accounts) {
    let USDT_ADDRESS = "";
    if(network === "development"){  
        await deployer.deploy(TestUSDT);
        const testUSDT = await TestUSDT.deployed();
        USDT_ADDRESS = testUSDT.address;
    } else if (network === "testnet") {
        await deployer.deploy(TestUSDT);
        const testUSDT = await TestUSDT.deployed();
        USDT_ADDRESS = testUSDT.address;
    } else {
        USDT_ADDRESS = "";
    }
    
    await deployer.deploy(Barnaje, USDT_ADDRESS);
    const barnaje = await Barnaje.deployed();

    await deployer.deploy(DaoWallet, USDT_ADDRESS, barnaje.address);
    const daoWallet = await DaoWallet.deployed();
     
    await deployer.deploy(TreeHandler, barnaje.address);
    const treeHandler = await TreeHandler.deployed();

    await deployer.deploy(DonationHandler, barnaje.address, treeHandler.address);
    await deployer.deploy(SponsorHandler, barnaje.address);

    const donationHandler = await DonationHandler.deployed();
    const sponsorHandler = await SponsorHandler.deployed();
    
    await barnaje.completeGenesis();
    await barnaje.initialize(sponsorHandler.address, treeHandler.address, donationHandler.address, daoWallet.address);
};
