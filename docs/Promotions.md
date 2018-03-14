












# Promotions

### Promotions



## Functions



### Constant functions





### State changing functions

#### addBudget

Add another budget allocation (slot) to the promotion. The new slot is attached at the end of the promotion,extending it by given duration. Every promotion can have different slots of differentduration to support reward discrimination based on time. E.g. The promoter can allocate 1000 MEDIA for the firsthour rewards and 500 MEDIA for  the second hour. In such example, the initial slot (1000 MEDIA/1hour) is createdby constructor (setting duration to 240 and budget to 1000, while second slot is added by this method (addinganother 240 duration and 500 allocation).


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|url|string||Identification of the promotion|
|1|allocation|uint||Funds allocated to this slot|
|2|duration|uint32||Duration of this slot|


#### buyContent

The user can buy content by issuing this method. He (his dAPP) has to take care that the address and the price match the given piece of content. Content is identified by its ID, usually URL. The contentcan be purchased several times, in which case the total sum and block of last action is recorded.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|id|string||Content identification, usually URL.|
|1|provider|address||Address where the funds has to be send.|
|2|price|uint||Price to be paid. Has to be same or higher as actual price for the given user.|


#### getDelegates

Group DelegatableGet list of delegates associated with the master account.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|master|address||Master account for which we are looking for delegates|


#### getPrice




##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|subscriber|address|||
|1|url|string|||
|2|period|uint|||


#### getRealActor

Group DelegatableThis method shall be called at the beginning of any "delegateable" function


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|sender|address||Find out the master account on behalf of which the sender acts.|


#### promotionAddNewUrl

Group PromotionsRegister another url to the given promotion. Only its owner can do it.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|url|string||One of the URLs associated with the promotion, identifier|
|1|newUrl|string||URL that is also going to be associated with the promotion|


#### promotionGet

Group PromotionsReturn the address of the Promotion contract, address(0) if no has been defined yet.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|url|string||URL associated with the promotion|


#### promotionRegister

Group PromotionsCreates new Promotion instance.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|start|uint256||starting block|
|1|duration|uint||promotion duration, in blocks|
|2|budget|uint256||allocated budget in media tokens|
|3|url|string||identifier of the content being promoted|
|4|allowLikeIndifferent|bool||allow Like/Indifferent interactions|
|5|allowShare|bool||allow Share interaction|
|6|allowConsumption|bool||allow Consume interaction|
|7|allowSurvey|bool||allow Survey interaction|
|8|identityVerificationService|address||pointer to the identity verification contract|
|9|referralShare|uint||Percentage of the budget reserved for referral rewards|
|10|referralDecrease|uint||Decrease of the reward per level in per cent. I.e. when level 1 reward is 1000, level2 is 1000/100*referralDecrease


#### proposeDelegation

Group DelegatableSend by master account to specify delegates. Can add more than one delegate.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|delegate|address||Delegate address to add.|


#### proposeMaster

Group DelegatableSend by potential delegate to specify new master. Can add only one master.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|master|address||Master account address to add.|


#### recordInteraction

Group PromotionsRecord an interaction


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|url|string||Identification of the promotion|
|1|interaction|promotionLibrary||Type of the interaction|
|2|additionalData|string||Any relevant additional data|
|3|referrers|address||List of referrers. Referrer levels are determined by their index in the array, e.g. referrers[1] defines level 1 referrer. refferers[0] denominates the dApp, can be set to address(0).|


#### removeDelegate

Group DelegatableRemoves existing delegate-to-master relationship, where master is the sender


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|delegate|address||Delegate address|


#### removeMaster

Group DelegatableRemoves existing delegate-to-master relationship, where delegate is the sender


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|delegate|address|||






### Events

#### ContentPurchaseRecord

Event generated when some buying happens. It is on the application to check that the price match the requirements.


##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|id|string|||
|1|provider|address|||
|2|price|uint|||
|3|block|uint|||


#### CreatePromotion




##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|url|string|||
|1|start|uint|||
|2|expiration|uint|||
|3|budget|uint|||
|4|promotion|address|||


#### AddPromotionUrl




##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|url|string|||
|1|newUrl|string|||


#### ExtendPromotion




##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|url|string|||
|1|addedDuration|uint32|||
|2|addedBudget|uint|||





### Enums




### Structs



