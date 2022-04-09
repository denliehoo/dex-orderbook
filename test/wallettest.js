
const Dex = artifacts.require("Dex")
const Link = artifacts.require("Link")
const truffleAssert = require('truffle-assertions'); // npm install truffle-assertions

/* contract accepts two params: the smart contract name & a function which takes accounts (as in addresses
    as a param) */
contract.skip("Dex", accounts => {
    /* 
it("statement, async function")
Note: each of this "it" functions are dependent on each other; e.g. if in one the it function
we deposit 100 LINK, then that means the balance of LINK in the next it function is 100
and so on...
 */
    it("should only be possible for owner to add tokens", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await truffleAssert.passes( // we assert that it passes since accounts[0] is the owner
            dex.addToken(web3.utils.fromUtf8("LINK"), link.address, { from: accounts[0] })
        )
        await truffleAssert.reverts( //we say it will fail and revert since accounts[1] isn't the owner
            dex.addToken(web3.utils.fromUtf8("AAVE"), link.address, { from: accounts[1] })
        )
    })
    it("should handle deposits correctly", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await link.approve(dex.address, 500);
        await dex.deposit(100, web3.utils.fromUtf8("LINK"));
        let balance = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"))

        // why assert and not truffleAssert?
        assert.equal(balance.toNumber(), 100)
    })
    it("should handle faulty withdrawals correctly", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        // remember: default is {from: accounts[0]};
        // this fails because accounts[0] only has depositted 100 LINK into the wallet
        // as seen from the previous test
        await truffleAssert.reverts(dex.withdraw(500, web3.utils.fromUtf8("LINK")))
    })
    it("should handle correct withdrawals correctly", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await truffleAssert.passes(dex.withdraw(100, web3.utils.fromUtf8("LINK")))
    })
    it("should deposit the correct amount of ETH", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await dex.depositEth({ value: 1000 });
        let balance = await dex.balances(accounts[0], web3.utils.fromUtf8("ETH"))
        assert.equal(balance.toNumber(), 1000);
    })
    it("should withdraw the correct amount of ETH", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await dex.withdrawEth(1000);
        let balance = await dex.balances(accounts[0], web3.utils.fromUtf8("ETH"))
        assert.equal(balance.toNumber(), 0);
    })
    it("should not allow over-withdrawing of ETH", async () => {
        let dex = await Dex.deployed()
        let link = await Link.deployed()
        await truffleAssert.reverts(dex.withdrawEth(100));
    })
})

/* 
truffle develop
test // this will compile, migrate and test
*/