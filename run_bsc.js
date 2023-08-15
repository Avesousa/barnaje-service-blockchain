const Web3 = require('web3');
const fs = require('fs');
const path = require('path');
const apiSecret = fs.readFileSync(".apiSecretWallet").toString().trim();

// Read file .csv
const users_genesis = require('./resource/output.json');


// Define the provider
const provider = "https://data-seed-prebsc-1-s1.bnbchain.org:8545";
const web3 = new Web3(new Web3.providers.HttpProvider(provider));

// Define the function  
async function run() {
    // Read the compiled contract (the JSON output from the Solidity compiler)
    const contractPath = path.resolve(__dirname, 'build/contracts/Barnaje.json');
    const contractJson = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
    
    // Wallet developer
    const account = await web3.eth.accounts.privateKeyToAccount(apiSecret);
    const dev = account.address;
    web3.eth.accounts.wallet.add(account);
    console.log('Wallet developer ', dev);


    // Get the deployed address from the Truffle Contract JSON
    const networkId = await web3.eth.net.getId();
    const deployedAddress = contractJson.networks[networkId].address;

    // Create a new contract instance with the contract at the deployed address
    const contract = new web3.eth.Contract(contractJson.abi, deployedAddress);

    // Get the DAO
    const dao = await contract.methods.getDao().call();

    // Create a function for view users
    const users = async (user) => console.log('User ', user, await contract.methods.getUser(user).call());
    const treeNode = async (user) => console.log('Tree node ', user, await contract.methods.getTree(user).call());


    // Call the tree node function
    for (let i = 0; i < users_genesis.length; i++) {
        const user = users_genesis[i];
        const wallet = i == 0 ? dao : user.wallet;
        const walletSponsor = i == 1 ? dao : user.wallet_sponsor;
        const walletPartner = i == 1 ? dao : user.wallet_partner;
        const balance = web3.utils.toWei(user.balance,'mwei');
        
        // console.log('[',user.order, '] User ', wallet, ' creating...');
        await contract.methods.completeUser(wallet, balance, walletSponsor, walletPartner, user.wallet_left_child, user.wallet_right_child)
        .send({ from: dev, gas: 5000000, gasPrice: web3.utils.toWei('20', 'gwei') })
        .then((_res) => {
            // console.log("User ok");
            // console.log('[',user.order,'] User ', wallet, ' created');
        })
        .catch((e) => {
            console.log("User error", e);
            console.error( '[',e.data?.hash || e.hijackedStack,'] User ', wallet, e.data?.message || '', e.data?.reason || '');
            throw e.data?.reason ? `${e.data.message} ${e.data.reason}` : e.hijackedStack;
        });

        // console.log('User ', wallet, ' donating...');

        await contract.methods.completeDonation(wallet)
        .send({ from: dev, gas: 5000000, gasPrice: web3.utils.toWei('20', 'gwei') })
        .then((_res) => {
            // console.log('[',user.order,'] User ', wallet, ' donated');
        })
        .catch((e) => {
            console.error( '[',e.data?.hash || e.hijackedStack,'] User ', wallet, e.data?.message || '', e.data?.reason || '', 'Error', e);
            throw e.data?.reason ? `${e.data.message} ${e.data.reason}` : e.hijackedStack;
        });
        // users(wallet);
        treeNode(wallet, user.full_name);
    }

}

run().then(() => process.exit(0));