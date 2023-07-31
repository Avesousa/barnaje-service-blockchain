const Barnaje = artifacts.require("Barnaje");
// const DonationHandler = artifacts.require("DonationHandler");
// const SponsorHandler = artifacts.require("SponsorHandler");
const TestUSDT = artifacts.require("TestUSDT");

module.exports = async function (deployer, network, accounts) {
    if(network === "development"){  
        await deployer.deploy(TestUSDT);
        const testUSDT = await TestUSDT.deployed();
        const USDT_ADDRESS = testUSDT.address;
        await deployer.deploy(Barnaje, USDT_ADDRESS, '0xE22C71c76a3b443D7fBc8E93C4b2E8A5735fc29b');
    }else {
        const USDT_ADDRESS = "";
        const DAO = "0xf65dB4D5c32144e7b11450c580d2518F5A8E6d7D";
        deployer.deploy(Barnaje, USDT_ADDRESS, DAO); 
    }
};
