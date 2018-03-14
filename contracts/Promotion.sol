pragma solidity ^0.4.18;

import './InteractionsCounter.sol';
import './IdentityVerification.sol';
import './MediaTokenUser.sol';
import './MediaToken.sol';
import './Delegatable.sol';


/*
 * promotionLibrary contains most of the code executed in the individual promotion contract. Only methods, where cost
 * of remote library call will be more expensive as deploying the code directly will stay inside the promotion
 * contracts.
 */
library promotionLibrary {
    using SafeMath for uint256;

    uint32 constant public rewardPeriod=2;

    event Debug(string d1, string d2, uint u1, uint u2);

    struct Budget{
        uint switchTime;
        uint allocation;
    }

    /* data about the individual promotion */
    struct PromotionData{
        address provider; //<who runs the promotion
        string url;       //<identifier of the content being promoted
        uint start;       //<starting block
        uint32 duration;  //<promotion duration, in blocks
        Budget[] budgets;
        uint32 currentBudget;
        uint budgetEnd;
        uint remainingBudgetAllocation; //<the unspent part of the budget
        uint remainingAllocation; //<the unspent part of total allocation
        bool allowLikeIndifferent; //<list of allowed interactions
        bool allowShare;
        bool allowConsumption;
        bool allowSurvey;
        uint lastProcessedBlock; //block when the distribution happened last time.
        uint32 referralShare;
        uint referralBudget;
        uint32 referralDecrease;
        ReferralsData referrals;

    }

    struct ReferralsData{
        mapping (address => uint64) referrerLevels;
        address [] referrers;
        uint totalLevels;
    }

    enum InteractionType{
        like,
        indifferent,
        share,
        consumption,
        survey
    }



    /*
     * interactions recorded for further processing. This can be replaced with interactions in order to decrease storage costs.
     */
    struct InteractionRecord{
        address user;
        uint weight;
    }

    /*
     * structure keeping all the interactions recorded. These has to be recorded in order to prevent abuses in form of
     * multiple actions
     */
    struct InteractionRecords{
        mapping( uint=> InteractionRecord) records;
        uint32 lastProcessed;
        uint32 total;
        uint thisIntervalTotalWeight;
        mapping( address => bool ) _likeIndifferent;
        mapping( address => bool ) _share;
        mapping( address => bool ) _consumption;
        mapping( address => bool ) _survey;
    }

    /*
     * evaluate and record the short interaction. It can also process backlog of previous interactions, at the beginning of
     * a block right after the reward period.
     * @param interaction type of the interaction
     * @param p PromotionData of the individual promotion
     * @param r structure InteractionRecords keeping backlog of potentially unprocessed interactions. Used only in case of backlog processing.
     * @param user User performing the given interaction
     * @param intCounter Pointer to the interactions counter contract
     * @param mediaToken Pointer to the media token contract
     */
    function getInteraction(uint32 interaction, PromotionData storage p, InteractionRecords storage r, address user, address intCounter, address mediaToken) public  {
        InteractionsCounter ic = InteractionsCounter(intCounter);
        uint32 interactions;
        if(InteractionType(interaction) == InteractionType.share){ //the inner part of the cycle cost 37.000 GAS
            require (p.allowShare);
            require( r._share[user] == false);
            r._share[user] = true;
            interactions = ic.addInteraction(uint32(InteractionsCounter.InteractionType.short));
        }else if(InteractionType(interaction) == InteractionType.consumption){
            require (p.allowConsumption);
            require( r._consumption[user] == false);
            r._consumption[user] = true;
            interactions = ic.addInteraction(uint32(InteractionsCounter.InteractionType.medium));
        }else if(InteractionType(interaction) == InteractionType.survey){
            require (p.allowSurvey);
            require( r._survey[user] == false);
            r._survey[user] = true;
            interactions = ic.addInteraction(uint32(InteractionsCounter.InteractionType.long));
        }else{ //like or indifferent
            require (p.allowLikeIndifferent);
            require( r._likeIndifferent[user] == false);
            r._likeIndifferent[user] = true;
            interactions = ic.addInteraction(uint32(InteractionsCounter.InteractionType.short));
        }
        require (block.number >= p.start);
        if(block.number >= p.lastProcessedBlock + rewardPeriod ){
            processBacklog(p, r, mediaToken);
            switchBudget(p);
        }
        if( block.number >= p.start + p.duration ){
            //finishPromotion(url);
            return;
        }
        InteractionRecord memory ir;
        ir.user = user;
        ir.weight = getWeight( interactions );


        if(ir.weight > 0){ //omit interactions without weight, as they won't help postprocessing
            r.records[r.total++]=ir; //40.000 GAS
            r.thisIntervalTotalWeight += ir.weight;
        }
    }

    function getForwardedInteraction(uint32 interaction, PromotionData storage p, InteractionRecords storage r, address payout, address mediaToken) public  {
        if(InteractionType(interaction) == InteractionType.share){
            require (p.allowShare);
        }else if(InteractionType(interaction) == InteractionType.consumption){
            require (p.allowConsumption);
        }else if(InteractionType(interaction) == InteractionType.survey){
            require (p.allowSurvey);
        }else{ //like or indifferent
            require (p.allowLikeIndifferent);
        }
        require (block.number >= p.start);
        if(block.number >= p.lastProcessedBlock + rewardPeriod ){
            processBacklog(p, r, mediaToken);
            switchBudget(p);
        }
        if( block.number >= p.start + p.duration ){
            //finishPromotion(url);
            return;
        }
        InteractionRecord memory ir;
        ir.user = payout;
        ir.weight = 100;

        r.records[r.total]=ir;
        r.thisIntervalTotalWeight+=ir.weight;
    }

    function switchBudget(PromotionData storage d) internal{
        if (d.budgets[d.currentBudget].switchTime >= block.number) //no time to switch yet
            return;
        while( d.budgets[d.currentBudget].switchTime < block.number ){
            d.currentBudget++;
            if(d.currentBudget == d.budgets.length)
                return;
            d.remainingBudgetAllocation += d.budgets[d.currentBudget].allocation;
        }
        d.budgetEnd = d.budgets[d.currentBudget].switchTime;
    }

    /*
     * Internal function to get weight of the given interaction (interaction) based on number of interactions from the interactions counter
     */
    function getWeight(uint32 count) internal pure returns(uint32){
        if(count <= 10 ) return 200;
        if(count <= 25 ) return 150;
        if(count <= 50 ) return 100;
        if(count <= 120 ) return 50;
        if(count <= 300 ) return 25;
        return 0;
    }

    /*
     * At the first transaction after the end of the reward period process the interaction backlog and distribute rewards for the users.
     * @param p promotionData of the individual promotion
     * @param r structure InteractionRecords keeping backlog of unprocessed interactions.
     * @param mediaToken Pointer to the media token contract
     */
    function processBacklog(PromotionData storage p, InteractionRecords storage r, address mediaToken) internal {
        if(r.total == r.lastProcessed)
            return;

        uint newLastProcessedBlock = block.number - (( block.number - p.start ) % rewardPeriod );

        MediaToken mt = MediaToken(mediaToken);
        uint blocksToEnd;
        if( block.number > p.budgets[p.currentBudget].switchTime)
            blocksToEnd = rewardPeriod;
        else
            blocksToEnd = p.budgets[p.currentBudget].switchTime - newLastProcessedBlock + rewardPeriod;

        uint totalWeight = r.thisIntervalTotalWeight;
        uint remainingBudgetAllocation = p.remainingBudgetAllocation;
        uint remainingAllocation = p.remainingAllocation;
        if(blocksToEnd>0 && totalWeight >0){
            uint reward = (remainingBudgetAllocation * 100 * rewardPeriod / blocksToEnd) / totalWeight;
            for(uint i = r.lastProcessed; i< r.total; i++){
                uint actualReward = reward * r.records[i].weight / 100;
                //This shall actually never happen; if it does, either the internal logic is broken or someone
                // found a way to exploit it. However, we shall not throw here as it will basically stop the contract,
                // with all funds unreachable.
                //require(p.remainingBudgetAllocation >= actualReward && p.remainingAllocation >= actualReward);
                if( remainingBudgetAllocation < actualReward)
                    actualReward = remainingBudgetAllocation;
                remainingBudgetAllocation -= actualReward;

                if( remainingAllocation < actualReward )
                    actualReward = remainingAllocation;
                remainingAllocation -= actualReward;
                address user = r.records[i].user;
                delete r.records[i];
                mt.transfer(user, actualReward );
            }
        }
        p.remainingAllocation = remainingAllocation;
        p.remainingBudgetAllocation = remainingBudgetAllocation;
        r.thisIntervalTotalWeight = 0;
        r.lastProcessed = r.total;
        p.lastProcessedBlock = newLastProcessedBlock;
    }

    function processReferralBacklog(PromotionData storage p, address mediaToken) internal {
        if(p.referralBudget == 0)
            return;

        MediaToken mt = MediaToken(mediaToken);
        uint totalWeight = p.referrals.totalLevels;
        uint rewardPerPoint = 0;

        if(totalWeight > 0)
            rewardPerPoint = p.referralBudget / totalWeight;
        uint referralBudget = p.referralBudget;
        for(uint i=0; i<p.referrals.referrers.length; i++){
            uint currentReward = rewardPerPoint * p.referrals.referrerLevels[p.referrals.referrers[i]];
            if(referralBudget < currentReward)
                currentReward = referralBudget;
            referralBudget -= currentReward;
            address user = p.referrals.referrers[i];
            delete p.referrals.referrerLevels[p.referrals.referrers[i]];
            delete p.referrals.referrers[i];
            mt.transfer(user, currentReward);
        }
        p.referralBudget = referralBudget;
    }

    function adjustToRewardPeriod(uint what) pure public returns (uint adjustedWhat){
        require((what + rewardPeriod -1 ) > what);
        return ((what + rewardPeriod - 1) / rewardPeriod) * rewardPeriod;
    }

    function addBudget(PromotionData storage p, uint allocation, uint duration) public{
        uint adjustedDuration = adjustToRewardPeriod(duration);
        p.duration += uint32(adjustedDuration);
        Budget memory newBudget;
        newBudget.switchTime = p.start + p.duration;
        newBudget.allocation = (allocation * (100 - p.referralShare)) / 100;
        p.budgets.push(newBudget);
        p.remainingAllocation += newBudget.allocation;
        p.referralBudget += allocation - newBudget.allocation;
    }

    function endPromotion(PromotionData storage p, InteractionRecords storage r, address token)public{
        require( msg.sender == p.provider);
        require( p.start+p.duration < block.number);
        processBacklog(p, r, token);
        processReferralBacklog(p, token);
        MediaToken mt = MediaToken(token);
        mt.transfer(p.provider, p.remainingAllocation + p.referralBudget);
        selfdestruct(p.provider);
    }

    function getReferral(PromotionData storage p, address referrer, uint32 level) private{
        if(p.referralShare == 0)
            return;
        if(level == 0)
            return;
        uint32 value = 10000;
        for( uint i = 1; i<level; i++)
            value = value * (100 - p.referralDecrease) / 100;

        if( p.referrals.referrerLevels[referrer] == 0 )
            p.referrals.referrers.push(referrer);
        p.referrals.referrerLevels[referrer] += value;
        p.referrals.totalLevels += value;
    }

    function recordReferrers(PromotionData storage p,address[4] referrers) public{
        if(referrers[0]!=address(0))
            getReferral(p, referrers[0], 1);
        for(uint32 i=1; i<referrers.length; i++ ){
            if(referrers[i]!=address(0)){
                getReferral(p, referrers[i], i);
            }
        }
    }
}
/*
 *Contract Promotion keeps data of and handles an individual promotion. Please note that methods addVerificationAuthority
 * and endPromotion can't be accessed via proxy must be called directly on the Promotion contract
 */
contract Promotion{
    event PromotionInteraction(
        uint interaction,
        address indexed user,
        string indexed url,
        string additionalData
    );

    event PromotionForwardedInteraction(
        uint interaction,
        address indexed payout,
        string indexed url,
        string additionalData
    );

    uint32 constant public rewardPeriod=2;
    uint constant private _maxBudgets=10;
    uint constant private _maxVerifiers=10;
    promotionLibrary.PromotionData private _data;
    promotionLibrary.InteractionRecords private _records;
    address private _token;  //<pointer to the media token contract
    address private _parent; //<pointer to the Promotions contract
    string[] private _verificationAuthorities; //<list of verifiers the contract owner trust. If empty, anu user, also not verified, can participate
    IdentityVerification private _identityVerificationService; //<pointer to the identity verification contract
    mapping(address => bool) private _forwarders;

    /*
     * Constructor. Creates new Promotion instance and initial budget allocation.
     * @param start starting block
     * @param duration promotion duration, in blocks
     * @param budget allocated budget in media tokens
     * @param url identifier of the content being promoted
     * @param allowLikeIndifferent allow Like/Indifferent interactions
     * @param allowShare allow Share interaction
     * @param allowConsumption allow Consume interaction
     * @param allowSurvey allow Survey interaction
     * @param token pointer to the media token contract
     * @param parent pointer to the Promotions contract
     * @param identityVerificationService pointer to the identity verification contract
     * @param referralShare Percentage of the budget reserved for referral rewards
     * @param referralDecrease Decrease of the reward per level in per cent. I.e. when level 1 reward is 1000, level2 is 1000/100*referralDecrease
     */
    function Promotion(uint start, uint duration, uint budget, string url, bool allowLikeIndifferent,
        bool allowShare, bool allowConsumption, bool allowSurvey, address token, address parent,
        address identityVerificationService, uint referralShare, uint referralDecrease) public{
        require(referralShare <= 100 );
        uint consumerBudget = (budget * (100 - referralShare)) / 100;
        _token = token;
        _parent = parent;
        require(start >= block.number );
        _data.provider = tx.origin;
        _data.url = url;
        _data.start = start;
        _data.duration = uint32(promotionLibrary.adjustToRewardPeriod(duration));
        _data.remainingBudgetAllocation = consumerBudget;
        _data.remainingAllocation = consumerBudget;
        _data.allowLikeIndifferent = allowLikeIndifferent;
        _data.allowShare = allowShare;
        _data.allowConsumption = allowConsumption;
        _data.allowSurvey = allowSurvey;
        _data.lastProcessedBlock = start;
        _data.referralBudget = budget - consumerBudget;
        _data.referralShare = uint32(referralShare);
        require(referralDecrease <= 100);
        _data.referralDecrease = uint32(referralDecrease);
        promotionLibrary.Budget memory initialBudget;
        initialBudget.switchTime = start + duration;
        initialBudget.allocation = consumerBudget;
        _data.budgets.push(initialBudget);
        _identityVerificationService = IdentityVerification(identityVerificationService);
        _forwarders[parent] = true;
    }



    /*
     * Add another budget allocation (slot) to the promotion. The new slot is attached at the end of the promotion,
     * extending it by given duration. Every promotion can have different slots of different
     * duration to support reward discrimination based on time. E.g. The promoter can allocate 1000 MEDIA for the first
     * hour rewards and 500 MEDIA for  the second hour. In such example, the initial slot (1000 MEDIA/1hour) is created
     * by constructor (setting duration to 240 and budget to 1000, while second slot is added by this method (adding
     * another 240 duration and 500 allocation). Can be called only from Promotions contract to ensure funds have been
     * successfully transferred.
     * @param allocation Funds allocated to this slot
     * @param duration Duration of this slot
     */
    function addBudget(uint allocation, uint duration) public{
        require(_data.budgets.length < _maxBudgets);
        require(msg.sender == _parent);
        promotionLibrary.addBudget(_data, allocation, duration);
    }


    /*
     * Add verification authority the promoter trust. Only users verified by one of the authorities can participate in the promotion and push interactions.
     * @param authority Authority name
     */
    function addVerificationAuthority(string authority) public{
        require(_verificationAuthorities.length < _maxVerifiers);
        require(msg.sender == _data.provider);
        _verificationAuthorities.push(authority);
    }

    /*
     * Check if a particular user has been verified (KYC performed) by any of the authorities.
     * @param user User whose KYC status is being verified
     * @return True if user KYC has been performed by some of the added authorities, False otherwise
     */
    function checkAuthority(address user) public view returns (bool){
        if(_verificationAuthorities.length == 0)
            return true;
        for(uint32 i =0; i<_verificationAuthorities.length; i++)
            if(_identityVerificationService.checkVerificationStatus(_verificationAuthorities[i], user))
                return true;
        return false;
    }


    /*
     * Ends the promotion contract, finish remaining backlog and return funds.
     */
    function endPromotion() public{
        promotionLibrary.endPromotion(_data, _records, _token);
    }

    /*
     * Record a new interaction.
     * @param user Address of the user who performed the interaction
     * @param interaction Interaction type. Shall be one the value of one of the InteractionType
     * @param additionalData Anything else that can be relevant (survey answers etc.)
     * @param referrers List of referrers. Referrer levels are determined by their index in the array, e.g. referrers[1] defines level 1 referrer. refferers[0] denominates the dApp, can be set to address(0).
     */
    function recordInteraction(address user, uint32 interaction, string additionalData, string url, address [4]referrers) public{
        require(_forwarders[msg.sender] == true || tx.origin == user);
        require(checkAuthority(user));
        promotionLibrary.getInteraction(interaction, _data, _records, user, _parent, _token);
        promotionLibrary.recordReferrers(_data, referrers);
        PromotionInteraction(interaction, user, url, additionalData);
    }


    /*
     * Record a new interaction, forwarded from trusted partner. This interaction can be done from user outside of the
     * network, and the payout goes directly to the partner to distribute. The partner can also include itself into the list of referrers.
     * @param user Address of the user who performed the interaction
     * @param interaction Interaction type. Shall be one the value of one of the InteractionType
     * @param additionalData Anything else that can be relevant (survey answers etc.)
     * @param referrers List of referrers. Referrer levels are determined by their index in the array, e.g. referrers[1] defines level 1 referrer. refferers[0] denominates the dApp, can be set to address(0).
     */
    function recordForwardedInteraction(address payout, uint32 interaction, string additionalData, string url, address [4]referrers) public{
        require(_forwarders[msg.sender] == true);
        promotionLibrary.getForwardedInteraction(interaction, _data, _records, payout, _token);
        promotionLibrary.recordReferrers(_data, referrers);
        PromotionForwardedInteraction(interaction, payout, url, additionalData);
    }

    /*
     * the contract allow interactions to be recorded from verified providers as well. The forwarders can collect the reward and distribute at their will.
     * This function add one to the list of forwarders.
     */
    function addForwarder(address forwarder) public{
        require(msg.sender == _data.provider);
        _forwarders[forwarder] = true;
    }

    /*
     * Return the address of the provider. Useful for contract factory to do security checks.
     */
    function getProvider() public view returns(address){
        return _data.provider;
    }

}
