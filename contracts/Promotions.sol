pragma solidity ^0.4.18;

import './Promotion.sol';

import './InteractionsCounter.sol';
import './IdentityVerification.sol';
import './MediaTokenUser.sol';
import './MediaToken.sol';
import './Delegatable.sol';
import './ContentPurchaseTracker.sol';
import './SubscriptionManager.sol';

contract Promotions is Delegatable, InteractionsCounter, SubscriptionManager, ContentPurchaseTracker{

    event CreatePromotion(string url, uint start, uint duration, uint budget, address promotion, address indexed promoter );
    event AddPromotionUrl(string url, string newUrl, address indexed promoter);
    event ExtendPromotion(string url, uint addedDuration, uint addedBudget, address indexed promoter);

    /*
     * Group Promotions
     * Creates new Promotion instance.
     * @param start starting block
     * @param duration promotion duration, in blocks
     * @param budget allocated budget in media tokens
     * @param url identifier of the content being promoted
     * @param allowLikeIndifferent allow Like/Indifferent interactions
     * @param allowShare allow Share interaction
     * @param allowConsumption allow Consume interaction
     * @param allowSurvey allow Survey interaction
     * @param identityVerificationService pointer to the identity verification contract
     * @param referralShare Percentage of the budget reserved for referral rewards
     * @param referralDecrease Decrease of the reward per level in per cent. I.e. when level 1 reward is 1000, level2 is 1000/100*referralDecrease
     */
    function promotionRegister(uint start, uint duration, uint budget, string url, bool allowLikeIndifferent,
        bool allowShare, bool allowConsumption, bool allowSurvey, address identityVerificationService, uint referralShare, uint referralDecrease) public;

    /*
     * Group Promotions
     * Register another url to the given promotion. Only its owner can do it.
     * @param url One of the URLs associated with the promotion, identifier
     * @param newUrl URL that is also going to be associated with the promotion
     */
    function promotionAddNewUrl(string url, string newUrl) public;

    /*
     * Group Promotions
     * Record an interaction
     * @param url Identification of the promotion
     * @param interaction Type of the interaction
     * @param additionalData Any relevant additional data
     * @param referrers List of referrers. Referrer levels are determined by their index in the array, e.g. referrers[1] defines level 1 referrer. refferers[0] denominates the dApp, can be set to address(0).
     */
    function recordInteraction(string url, promotionLibrary.InteractionType interaction, string additionalData, address[4] referrers) public;

    /*
     * Group Promotions
     * Return the address of the Promotion contract, address(0) if no has been defined yet.
     * @param url URL associated with the promotion
     * @return address of the Promotion contract
    */
    function promotionGet(string url) public view returns(address);

    /*
      * Add another budget allocation (slot) to the promotion. The new slot is attached at the end of the promotion,
      * extending it by given duration. Every promotion can have different slots of different
      * duration to support reward discrimination based on time. E.g. The promoter can allocate 1000 MEDIA for the first
      * hour rewards and 500 MEDIA for  the second hour. In such example, the initial slot (1000 MEDIA/1hour) is created
      * by constructor (setting duration to 240 and budget to 1000, while second slot is added by this method (adding
      * another 240 duration and 500 allocation).
      * @param url Identification of the promotion
      * @param allocation Funds allocated to this slot
      * @param duration Duration of this slot
      */
    function addBudget(string url, uint allocation, uint32 duration) public;
}

contract PromotionsStorage{
    mapping (string => Promotion) internal _promotions;
}


contract PromotionsDispatcher is InteractionsCounterDispatcher, SubscriptionManagerDispatcher, ContentPurchaseTrackerDispatcher, PromotionsStorage {
    /* Constructor.
     * @param tokenAddress Addressof the media token contract.
     */
    function PromotionsDispatcher(address target, address tokenAddress) public{
        _owner = msg.sender;
        replaceImplementation(target);
        _token = tokenAddress;
    }

}

/*
 * Promotions contract is the factory and entry point for individual promotions contract. First, register a promotion with
 * an unique url, optionally assign it KYC verification authorities and the users can then record their interactions
 * (interactions) using the url as the key.
 */
contract PromotionsImplementation is InteractionsCounterImplementation, SubscriptionManagerImplementation, ContentPurchaseTrackerImplementation, PromotionsStorage, Promotions{

    /*
     * Creates new Promotion instance.
     * @param start starting block
     * @param duration promotion duration, in blocks
     * @param budget allocated budget in media tokens
     * @param url identifier of the content being promoted
     * @param allowLikeIndifferent allow Like/Indifferent interactions
     * @param allowShare allow Share interaction
     * @param allowConsumption allow Consume interaction
     * @param allowSurvey allow Survey interaction
     * @param identityVerificationService pointer to the identity verification contract
     * @param referralShare Percentage of the total budget reserved for referrals
     * @param referralDecrease Decrease of the reward per level in per cent. I.e. when level 1 reward is 1000, level2 is 1000/100*referralDecrease

     */
    function promotionRegister(uint start, uint duration, uint budget, string url, bool allowLikeIndifferent,
        bool allowShare, bool allowConsumption, bool allowSurvey, address identityVerificationService, uint referralShare, uint referralDecrease) public{
        require(_promotions[url] == address(0));
        MediaToken mt = MediaToken(_token);
        Promotion newPromo = new Promotion(start, duration, budget, url, allowLikeIndifferent, allowShare,
                                allowConsumption, allowSurvey, _token, this, identityVerificationService, referralShare, referralDecrease);
        require(mt.transferFrom(msg.sender, newPromo, budget));
        _promotions[url] = newPromo;
        CreatePromotion(url, start, duration, budget, newPromo, msg.sender);
    }

    function promotionAddNewUrl(string url, string newUrl) public{
        require(_promotions[url].getProvider() == msg.sender);
        _promotions[newUrl] = _promotions[url];
        AddPromotionUrl(url, newUrl, msg.sender);
    }

    function promotionGet(string url) public view returns(address){
        return _promotions[url];
    }

    function recordInteraction(string url, promotionLibrary.InteractionType interaction, string additionalData, address[4] referrers) public{
        require(_promotions[url]!= address(0));
        Promotion p = _promotions[url];
        p.recordInteraction(getRealActor(msg.sender), uint32(interaction), additionalData, url, referrers);
    }


     /*
      * Add another budget allocation (slot) to the promotion. The new slot is attached at the end of the promotion,
      * extending it by given duration. Every promotion can have different slots of different
      * duration to support reward discrimination based on time. E.g. The promoter can allocate 1000 MEDIA for the first
      * hour rewards and 500 MEDIA for  the second hour. In such example, the initial slot (1000 MEDIA/1hour) is created
      * by constructor (setting duration to 240 and budget to 1000, while second slot is added by this method (adding
      * another 240 duration and 500 allocation).
      * @param allocation Funds allocated to this slot
      * @param duration Duration of this slot
      */
    function addBudget(string url, uint allocation, uint32 duration) public{
        require(_promotions[url].getProvider() == msg.sender);
        MediaToken mt = MediaToken(_token);
        require(mt.transferFrom(msg.sender, _promotions[url], allocation));
        _promotions[url].addBudget(allocation, duration);
        ExtendPromotion(url, duration, allocation, msg.sender);//*/
    }
}

/*

mt=MediaToken.deployed()
psd = PromotionsDispatcher.deployed()
ps = Promotions.at('0xc9b5a7986c87cf48103533603d9c1a5090f0735f');
ivd = IdentityVerificationDispatcher.deployed();
iv= IdentityVerification.at('0x8fa8cf75a0ad9ef24118a738aa428681f4ae9c3c');

iv.then(function(i){return i.registerService("abcd");})
iv.then(function(i){return i.addUserVerification(web3.eth.accounts[2]);})
iv.then(function(i){return i.checkVerificationStatus("abcd",web3.eth.accounts[2]);})


mt.then(function(i){return i.approve('0xc9b5a7986c87cf48103533603d9c1a5090f0735f', 10000000000000000000000000);});
ps.then(function(i){return i.promotionRegister(25, 20, 10000, "http://sme.sk3",true, false, false, false, iv.address);});
ps.then(function(i){return i.promotionGet("http://sme.sk3");})

ps.then(function(i){return i.recordInteract("http://sme.sk3");});
ps.then(function(i){return i.getLike("http://sme.sk3", {from: web3.eth.accounts[1]});});
mt.then(function(i){return i.balanceOf(web3.eth.accounts[0]);})
*/