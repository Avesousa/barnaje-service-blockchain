const Barnaje = artifacts.require("Barnaje");
const TreeHandler = artifacts.require("TreeHandler");
const DonationHandler = artifacts.require("DonationHandler");
const SponsorHandler = artifacts.require("SponsorHandler");
const TestUSDT = artifacts.require("TestUSDT");

module.exports = async function (deployer, network, accounts) {
    let USDT_ADDRESS = "";
    let DAO = ""
    if(network === "development"){  
        await deployer.deploy(TestUSDT);
        const testUSDT = await TestUSDT.deployed();
        USDT_ADDRESS = testUSDT.address;
        DAO = '0xE22C71c76a3b443D7fBc8E93C4b2E8A5735fc29b';
    }else {
        USDT_ADDRESS = "";
        DAO = "0xf65dB4D5c32144e7b11450c580d2518F5A8E6d7D";
    }
    await deployer.deploy(Barnaje, USDT_ADDRESS, DAO);
    const barnaje = await Barnaje.deployed();
     
    await deployer.deploy(TreeHandler, barnaje.address);
    const treeHandler = await TreeHandler.deployed();

    await deployer.deploy(DonationHandler, barnaje.address, treeHandler.address);
    await deployer.deploy(SponsorHandler, barnaje.address);

    const donationHandler = await DonationHandler.deployed();
    const sponsorHandler = await SponsorHandler.deployed();
    
    await barnaje.completeGenesis();
    await barnaje.initialize(sponsorHandler.address, treeHandler.address, donationHandler.address);

    const users_genesis = [
        { me: accounts[1], balance: web3.utils.toWei('67350','mwei'), sponsor: '0x0000000000000000000000000000000000000000' }, 
        { me: accounts[0], balance: web3.utils.toWei('67350','mwei'), sponsor: accounts[1] }, 
        { me: accounts[2], balance: web3.utils.toWei('67350','mwei'), sponsor: accounts[0] }, 
        { me: accounts[3], balance: web3.utils.toWei('1850','mwei'), sponsor: accounts[2] }, 
        { me: accounts[4], balance: web3.utils.toWei('67350','mwei'), sponsor: accounts[0] }, 
        { me: accounts[5], balance: web3.utils.toWei('21350','mwei'), sponsor: accounts[3] }, 
        { me: accounts[6], balance: web3.utils.toWei('67350','mwei'), sponsor: accounts[0] }, 
        { me: accounts[7], balance: web3.utils.toWei('13850','mwei'), sponsor: accounts[0] }, 
        { me: accounts[8], balance: web3.utils.toWei('13850','mwei'), sponsor: accounts[0] }, 
        { me: accounts[9], balance: web3.utils.toWei('6050','mwei'), sponsor: accounts[4] }
    ];

    for (let i = 0; i < users_genesis.length; i++) {
        const user = users_genesis[i];
        console.log('User ', user.me, ' creating...');
        await barnaje.completeUser(user.me, user.balance, user.sponsor, { from: DAO, gas: 5000000 })
        .then((res) => {
            console.log('[',res.receipt.transactionHash,'] User ', user.me, ' created');
        })
        .catch((e) => {
            console.error( '[',e.data?.hash ? e.data.hash : e.hijackedStack,'] User ', user.me, e.data?.message || '', e.data?.reason || '');
            throw e.data?.reason ? `${e.data.message} ${e.data.reason}` : e.hijackedStack;
        });
        console.log('User ', user.me, ' donating...');
        await barnaje.completeDonation(user.me, { from: DAO, gas: 5000000 })
        .then((res) => {
            console.log('[',res.receipt.transactionHash,'] User ', user.me, ' donated');
        })
        .catch((e) => {
            console.error( '[',e.data?.hash ? e.data.hash : e.hijackedStack,'] User ', user.me, e.data?.message || '', e.data?.reason || '');
            throw e.data?.reason ? `${e.data.message} ${e.data.reason}` : e.hijackedStack;
        });
    }
    const convertWeiToUSDT = (wei) => {
        let balanceUSDTBigNumber = new web3.utils.BN(wei);
        return parseFloat(web3.utils.fromWei(balanceUSDTBigNumber, 'mwei'));
    }

    
    for(let i = 0; i < users_genesis.length; i++){
        await barnaje.getUser(users_genesis[i].me)
            .then(async (res) => { 
                const trees = await barnaje.getTree(users_genesis[i].me).then((res) => {return res});
                console.log('\nUser =>',users_genesis[i].me, '| Balance:', convertWeiToUSDT(res.balance), 'Sponsor:', res.sponsor, 'Step:', res.step, 'Direct Referrals:', res.directReferrals, 'Tree:',  trees);
            });
    }
};
