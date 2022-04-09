const Link = artifacts.require("Link");
const Dex = artifacts.require("Dex");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Link);
}



/*
Edit: moved code to wallettest.js to do for testing
// deployer is the normal param
// network will tell us whether it is testnet/mainnet/local
// accounts will give us access to the accounts[0] etc; without this param, we will get an error if we use accounts[0] in our code below
module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Link);
  let dex = await Dex.deployed()
  let link = await Link.deployed()

  await link.approve(dex.address, 500)
  dex.addToken(web3.utils.fromUtf8("LINK"), link.address)

  await dex.deposit(100, web3.utils.fromUtf8("LINK"))

  let balanceOfLink = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"))
  console.log(balanceOfLink.toNumber())

};
*/
/* 
We can do the code above instead of the code below and we can do a "preset"
so that we dont have to do all the .transfer etc on the cmd line
however, we will still need to do let dex = await .... and let link = await...
if we want to do more testing because in the cmd line and the code above is separate.

Now, we just need to do truffle migrate --reset and it will automatically show the balance
as opposed to typing all the stuff over and over again to test

*/

/*
  // Initial code
const Link = artifacts.require("Link");

module.exports = function (deployer) {
  deployer.deploy(Link);
};

 */


/* 
// In cmd line (with the initial code): 
// deploys the smart contracts
let dex = await Dex.deployed()
let link = await Link.deployed()

let b = await link.balanceOf(accounts[0])
b.toNumber()

// we can't just do "LINK" because we are using bytes32 for the ticket
// usually for solidity we can just do bytes32("LINK") to get the bytes32 of a string
// but for truffle, we have to use the web3 utils to convert it to bytes32
// link.address would be the token contract address
dex.addToken(web3.utils.fromUtf8("LINK"), link.address)

// shows the bytes32 ticker value of the 0th in the tokenList
dex.tokenList(0)  // 0x................
dex.tokenMapping(web3.utils.fromUtf8("LINK")) // we can verify that the ticker is the same as above and also verify the tokenAddress


//failed deposit token; this will give an error because owner hasn't approved spending yet
dex.deposit(100, web3.utils.fromUtf8("LINK") )

// approve
// approve(_spenderAddress, _amount) ; note: we dont have to do ,{from: accounts[0]} since by default it will be
// accounts[0] whenever we interact with contracts through truffle w/o specifying which account we are using
link.approve(dex.address, 500)

// deposits token
dex.deposit(100, web3.utils.fromUtf8("LINK") )
// checks the balance in the dex 
b = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"))
b.toNumber() 


 */