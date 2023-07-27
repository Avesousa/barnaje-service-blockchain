const Barnaje = artifacts.require("Barnaje");
const TestUSDT = artifacts.require("TestUSDT");

module.exports = async function (deployer, network, accounts) {
    if(network === "development"){  
        await deployer.deploy(TestUSDT);
        const testUSDT = await TestUSDT.deployed();
        const USDT_ADDRESS = testUSDT.address;
        await deployer.deploy(Barnaje, USDT_ADDRESS);
    }else {
        const USDT_ADDRESS = "";
        deployer.deploy(Barnaje, USDT_ADDRESS); 
    }
};
