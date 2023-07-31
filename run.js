const Web3 = require('web3');
const fs = require('fs');
const path = require('path');

// Define the provider
const provider = "http://localhost:7545";
const web3 = new Web3(new Web3.providers.HttpProvider(provider));

async function run() {
    // Use the first account as the default account
    const accounts = await web3.eth.getAccounts();

    // Read the compiled contract (the JSON output from the Solidity compiler)
    const contractPath = path.resolve(__dirname, 'build/contracts/Barnaje.json');
    const contractJson = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

    // Get the deployed address from the Truffle Contract JSON
    const networkId = await web3.eth.net.getId();
    const deployedAddress = contractJson.networks[networkId].address;

    // Create a new contract instance with the contract at the deployed address
    const contract = new web3.eth.Contract(contractJson.abi, deployedAddress);

    // Create a function for view users
    const users = async (user) => console.log('User ', user, await contract.methods.getUser(user).call());
    const treeNode = async (user) => console.log('Tree node ', user, await contract.methods.getTree(user).call());
    // Get the default account
    const dao = accounts[1];

    // Call your contract's methods
    await contract.methods.initialize().call({ from: dao });
    await contract.methods.completeGenesis.call({ from: dao });

    // Call the tree node function
    // const users_genesis = [{me:accounts[1], balance: 67350, sponsor: '0x0000000000000000000000000000000000000000'},{me:accounts[0], balance: 67350, sponsor: accounts[1]},{me:accounts[2], balance: 67350, sponsor: accounts[0]},{me:accounts[3], balance: 1850, sponsor: accounts[2]},{me:accounts[4], balance: 67350, sponsor: accounts[0]},{me:accounts[5], balance: 21350, sponsor: accounts[3]},{me:accounts[6], balance: 67350, sponsor: accounts[0]},{me:accounts[7], balance: 13850, sponsor: accounts[0]},{me:accounts[8], balance: 13850, sponsor: accounts[0]},{me:accounts[9], balance: 6050, sponsor: accounts[4]}];
    // const users_genesis = [
    //     { me: accounts[1], balance: 67350, sponsor: '0x0000000000000000000000000000000000000000' }, 
    //     { me: accounts[0], balance: 67350, sponsor: accounts[1] }, 
    //     { me: accounts[2], balance: 67350, sponsor: accounts[0] }, 
    //     { me: accounts[3], balance: 1850, sponsor: accounts[2] }, 
    //     { me: accounts[4], balance: 67350, sponsor: accounts[0] }, 
    //     { me: accounts[5], balance: 21350, sponsor: accounts[3] }, 
    //     { me: accounts[6], balance: 67350, sponsor: accounts[0] }, 
    //     { me: accounts[7], balance: 13850, sponsor: accounts[0] }, 
    //     { me: accounts[8], balance: 13850, sponsor: accounts[0] }, 
    //     { me: accounts[9], balance: 6050, sponsor: accounts[4] }
    // ];

    // for (let i = 0; i < users_genesis.length; i++) {
    //     const user = users_genesis[i];
    //     console.log('User ', user.me, ' run');
    //     await contract.methods.completeUser(user.me, user.balance, user.sponsor).send({ from: dao, gas: 5000000 })
    //         .then(() => {
    //             console.log('User ', user.me, ' initialized');
    //             // users(user.me);
    //         })
    //         .catch(e => console.error('User initialized error ', e));
    // }

}

run().then(() => process.exit(0));