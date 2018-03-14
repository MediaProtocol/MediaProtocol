

const BigNumber = web3.BigNumber;
var IdentityVerificationImplementation = artifacts.require("IdentityVerificationImplementation");
var IdentityVerificationDispatcher = artifacts.require("IdentityVerificationDispatcher");
var IdentityVerification = artifacts.require("IdentityVerification");

var MediaToken = artifacts.require("MediaToken");
var MediaManager = artifacts.require("MediaManager");
var Promotions = artifacts.require("Promotions");
var PromotionsDispatcher = artifacts.require("PromotionsDispatcher");
var PromotionsImplementation = artifacts.require("PromotionsImplementation");
var Promotion = artifacts.require("Promotion");
var promotionLibrary = artifacts.require("promotionLibrary");
var SimpleSubscriptionDefinition = artifacts.require("SimpleSubscriptionDefinition");


async function assertRevert(promise) {
    try {
        await promise;
        assert.fail('Expected revert not received');
    } catch (error) {
        const revertFound = error.message.search('revert') >= 0;
        assert(revertFound, `Expected "revert", got ${error} instead`);
    }
};


contract('MediaTokenTest', function(accounts) {
    it("Shall create token contract and transfer 100000000000000000000000 tokens to other user", async function() {
        let mt = await MediaToken.new(1000000000000000000000000);
        let et = mt.ExternalTransfer({}, {fromBlock: 0, toBlock: 'latest'});
        let st = mt.Transfer({}, {fromBlock: 0, toBlock: 'latest'});
        et.watch(function(error, result){
            console.log("External transfer, from: " + result.args.from, "to: " + result.args.to, "by: "+result.args.spender, "amount: "+result.args.tokens.toString());
        });

        st.watch(function(error, result){
            console.log("Standard transfer, from: " + result.args.from, "to: " + result.args.to, "amount: "+result.args.value.toString());
        });

        if( !(await mt.balanceOf(web3.eth.accounts[0])).equals("1000000000000000000000000") )
            throw new Error("Balance not euqal 1");
        await mt.transfer(web3.eth.accounts[1], 100000000000000000000000);
        if( !(await mt.balanceOf(web3.eth.accounts[1])).equals("100000000000000000000000") )
            throw new Error("Balance not euqal 2");
        if( !(await mt.balanceOf(web3.eth.accounts[0])).equals("900000000000000000000000") )
            throw new Error("Balance not euqal 3");

        //now get the management contract and run some transfers...
        let mc = MediaManager.at(await mt.managementContract());

        await mc.transferFrom(web3.eth.accounts[1], web3.eth.accounts[2], 50000000000000000000000);
        if( !(await mt.balanceOf(web3.eth.accounts[1])).equals("50000000000000000000000") )
            throw new Error("Balance not euqal 4");
        if( !(await mt.balanceOf(web3.eth.accounts[2])).equals("50000000000000000000000") )
            throw new Error("Balance not euqal 5");

        //and now test the approvals
        await mt.approve(web3.eth.accounts[3], 10000000000000000);
        await mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[3], "100000000", {from: web3.eth.accounts[3]});
        //and some time based approvals

        await mt.approveRecurrent(web3.eth.accounts[4], 100, 3);
        await assertRevert(mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[4], "200", {from: web3.eth.accounts[4]}));
        await mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[4], "100", {from: web3.eth.accounts[4]});
        await mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[4], "100", {from: web3.eth.accounts[4]});
        await assertRevert(mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[4], "100", {from: web3.eth.accounts[4]}));
        await assertRevert(mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[4], "100", {from: web3.eth.accounts[4]}));
        await mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[5], "100", {from: web3.eth.accounts[4]});
        await mt.approveRecurrent(web3.eth.accounts[4], 0, 3);
        await assertRevert(mt.transferFrom(web3.eth.accounts[0], web3.eth.accounts[4], "100", {from: web3.eth.accounts[4]}));

    });//*/
});

contract('PromotionsTest',  function(accounts){
    it("Shall create new promotion and create some events in it", async function(){
        let mt = await MediaToken.new(1000000000000000000000000);
        let psm = await PromotionsImplementation.new(mt.address);
        let psd = await PromotionsDispatcher.new(psm.address, mt.address);
        let ps = await Promotions.at(psd.address);
        let ivm = await IdentityVerificationImplementation.new();
        let ivd = await IdentityVerificationDispatcher.new(ivm.address);
        let iv = await IdentityVerification.at(ivd.address);


        await mt.approve(ps.address, 10000000000000000);
        //await mt.transfer(web3.eth.accounts[1], 1000, {from: web3.eth.accounts[0]})
        //await mt.transfer(web3.eth.accounts[2], 1000, {from: web3.eth.accounts[0]})


        let bn = web3.eth.blockNumber;
        await ps.promotionRegister(bn+3, 20, 2000000, "http://sme.sk",true, true, false, false, iv.address, 50, 10);
        await ps.addBudget("http://sme.sk", 200000, 10)
        let pa = await ps.promotionGet("http://sme.sk");
        let p = await Promotion.at(pa);
        await ps.recordInteraction("http://sme.sk", 0, "", [web3.eth.accounts[1]]);
        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[1]});
        await ps.recordInteraction("http://sme.sk", 2, "", [], {from: web3.eth.accounts[1]}); //share from the same account shall pass

        await assertRevert(ps.recordInteraction("http://sme.sk2", 0, "", [], {from: web3.eth.accounts[1]})); //non-existing promotion
        await assertRevert(ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[1]})); //another like from the same account


        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[2]});
        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[3]});
        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[4]});
        await assertRevert(ps.recordInteraction("http://sme.sk2", 0, "", [], {from: web3.eth.accounts[1]})); //non-existing promotion
        await assertRevert(ps.recordInteraction("http://sme.sk2", 0, "", [], {from: web3.eth.accounts[1]})); //non-existing promotion
        await assertRevert(ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[1]})); //another like from the same account
        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[5]});

        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[6]});
        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[7]});


        //generate few new blocks
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);

        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[8]});
        await mt.transfer(web3.eth.accounts[2], 10);
        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[9]});
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);


        await p.endPromotion();

        console.log(await mt.balanceOf(web3.eth.accounts[0]));
        console.log(await mt.balanceOf(web3.eth.accounts[1]));
        console.log(await mt.balanceOf(web3.eth.accounts[2]));
        console.log(await mt.balanceOf(web3.eth.accounts[3]));
        console.log(await mt.balanceOf(web3.eth.accounts[4]));
        console.log(await mt.balanceOf(web3.eth.accounts[5]));
        console.log(await mt.balanceOf(web3.eth.accounts[6]));
        console.log(await mt.balanceOf(web3.eth.accounts[7]));
        console.log(await mt.balanceOf(web3.eth.accounts[8]));
        console.log(await mt.balanceOf(web3.eth.accounts[9]));

        //since therere was no valid interaction in the two blocks, the reward is divided to 18 pieces instead of 20 - hence 554/556 instead of 500.
        if( !(await mt.balanceOf(web3.eth.accounts[0])).equals("999999999999999997849840") )
            throw new Error("Balance not euqal 4");
        if( !(await mt.balanceOf(web3.eth.accounts[1])).equals("1250000") )
            throw new Error("Balance not euqal 5");
        if( !(await mt.balanceOf(web3.eth.accounts[2])).equals("100160") )
            throw new Error("Balance not euqal 6");
        if( !(await mt.balanceOf(web3.eth.accounts[3])).equals("58332") )
            throw new Error("Balance not euqal 7");
        if( !(await mt.balanceOf(web3.eth.accounts[4])).equals("58332") )
            throw new Error("Balance not euqal 8");
        if( !(await mt.balanceOf(web3.eth.accounts[5])).equals("116666") )
            throw new Error("Balance not euqal 9");
        if( !(await mt.balanceOf(web3.eth.accounts[6])).equals("233334") )
            throw new Error("Balance not euqal 10");
        if( !(await mt.balanceOf(web3.eth.accounts[7])).equals("233334") )
            throw new Error("Balance not euqal 11");
        if( !(await mt.balanceOf(web3.eth.accounts[8])).equals("20000") )
            throw new Error("Balance not euqal 12");
        if( !(await mt.balanceOf(web3.eth.accounts[9])).equals("80002") )
            throw new Error("Balance not euqal 13");//*/
    }); //*/

    it("Shall allow actions only for verified users", async function(){
        let mt = await MediaToken.new(1000000000000000000000000);
        let psm = await PromotionsImplementation.new(mt.address);
        let psd = await PromotionsDispatcher.new(psm.address, mt.address);
        let ps = await Promotions.at(psd.address);
        let ivm = await IdentityVerificationImplementation.new();
        let ivd = await IdentityVerificationDispatcher.new(ivm.address);
        let iv = await IdentityVerification.at(ivd.address);

        await mt.approve(ps.address, 10000000000000000);

        await iv.registerService("myVerification", {from: web3.eth.accounts[8]});
        await iv.registerService("otherVerification", {from: web3.eth.accounts[9]});
        await iv.addUserVerification(web3.eth.accounts[1], {from: web3.eth.accounts[8]});
        await iv.addUserVerification(web3.eth.accounts[2], {from: web3.eth.accounts[9]});
        await assertRevert(iv.addUserVerification(web3.eth.accounts[3], {from: web3.eth.accounts[3]}));


        let bn = web3.eth.blockNumber;
        console.log((await ps.promotionRegister(bn+2, 20, 10000, "http://sme.sk",true, false, false, false, iv.address, 0, 10)));
        let p1 = Promotion.at(await ps.promotionGet("http://sme.sk"));
        await p1.addVerificationAuthority("myVerification");
        await assertRevert(ps.recordInteraction("http://sme.sk", 0, "", []));
        await ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[1]});
        await assertRevert(ps.recordInteraction("http://sme.sk", 0, "", [], {from: web3.eth.accounts[2]}));
    });//*/

    it("Shall allow actions on other account behalf", async function(){
        let mt = await MediaToken.new(1000000000000000000000000);
        let psm = await PromotionsImplementation.new(mt.address);
        let psd = await PromotionsDispatcher.new(psm.address, mt.address);
        let ps = await Promotions.at(psd.address);
        let ivm = await IdentityVerificationImplementation.new();
        let ivd = await IdentityVerificationDispatcher.new(ivm.address);
        let iv = await IdentityVerification.at(ivd.address);

        await mt.approve(ps.address, 10000000000000000);

        await ps.proposeDelegation(web3.eth.accounts[1]);
        await ps.proposeMaster(web3.eth.accounts[0], {from: web3.eth.accounts[1]});
        await ps.buyContent("http://abcd", web3.eth.accounts[2], 100, {from: web3.eth.accounts[1]});
        if( !(await mt.balanceOf(web3.eth.accounts[0])).equals("999999999999999999999900") )
            throw new Error("Balance not euqal 1");
        if( !(await mt.balanceOf(web3.eth.accounts[2])).equals("100") )
            throw new Error("Balance not euqal 2");
    });//*/

    /*it("Content buying and subscriptions shall work", async function(){
        let mt = await MediaToken.new(1000000000000000000000000);
        let psm = await PromotionsImplementation.new(mt.address);
        let psd = await PromotionsDispatcher.new(psm.address, mt.address);
        let ps = await Promotions.at(psd.address);
        let ivm = await IdentityVerificationImplementation.new();
        let ivd = await IdentityVerificationDispatcher.new(ivm.address);
        let iv = await IdentityVerification.at(ivd.address);
        let sd = await SimpleSubscriptionDefinition.new();


        await mt.approve(ps.address, 10000000000000000);
        await mt.approveRecurrent(ps.address, 100, 10, {from: web3.eth.accounts[2]});

        await ps.buyContent("http://abcd", web3.eth.accounts[1], 100);
        if( !(await mt.balanceOf(web3.eth.accounts[0])).equals("999999999999999999999900") )
            throw new Error("Balance not euqal 1");
        if( !(await mt.balanceOf(web3.eth.accounts[1])).equals("100") )
            throw new Error("Balance not euqal 2");

        await mt.transfer(web3.eth.accounts[2], 1000);
        await mt.approveRecurrent(ps.address, 100, 10, {from: web3.eth.accounts[2]});

        let su = ps.Subscribe({}, {fromBlock: 0, toBlock: 'latest'});
        su.watch(function(error, result){
            console.log("Subscribe, url: " + result.args.uri, "by: " + result.args.subscriber, "from: "+result.args.fromBlock.toString(), "to: "+result.args.toBlock.toString);
        });

        let rso = ps.RegisterSubscriptionOffer({}, {fromBlock: 0, toBlock: 'latest'});
        rso.watch(function(error, result){
            console.log("RegisterSubscriptionOffer, url: " + result.args.uri);
        });


        await ps.registerSubscriptionOffer("http://mypaywall", 5, sd.address );
        await ps.subscribe("http://mypaywall", 5, {from: web3.eth.accounts[2]});


        if( !(await mt.balanceOf(web3.eth.accounts[0])).equals("999999999999999999998905") )
            throw new Error("Balance not euqal 3");
        if( !(await mt.balanceOf(web3.eth.accounts[2])).equals("995") )
            throw new Error("Balance not euqal 4");
        if( !await ps.isSubscriber("http://mypaywall", web3.eth.accounts[2]))
            throw new Error("Not a subscriber!");
        if( await ps.isSubscriber("http://anotherpaywall", web3.eth.accounts[2]))
            throw new Error("Shall not be a subscriber!");

        //generate few new blocks
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);


        if( await ps.isSubscriber("http://mypaywall", web3.eth.accounts[2]))
            throw new Error("Shall not be a subscriber anymore!");

        await ps.renewSubscription("http://mypaywall", web3.eth.accounts[2]);
        await assertRevert(ps.renewSubscription("http://mypaywall", web3.eth.accounts[2]));
        await mt.transfer(web3.eth.accounts[2], 10);
        await mt.transfer(web3.eth.accounts[2], 10);
        await ps.renewSubscription("http://mypaywall", web3.eth.accounts[2]);
        await assertRevert(ps.renewSubscription("http://mypaywall", web3.eth.accounts[1]));


    }); //*/


});

