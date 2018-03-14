












# Promotion

### Contract Promotion keeps data of and handles an individual promotion. Please note that methods addVerificationAuthority and endPromotion can't be accessed via proxy must be called directly on the Promotion contract



## Functions



### Constant functions

#### rewardPeriod

Reward period is by default set to 2 blocks, i.e. ~30 seconds.


##### Inputs

empty list


##### Returns

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|return0|uint32||rewardPeriod|






### State changing functions

#### addBudget

Add another budget allocation (slot) to the promotion. The new slot is attached at the current end of the promotion, extending it by given duration. Every promotion can have different slots of different duration to support reward discrimination based on time. E.g. The promoter can allocate 1000 MEDIA for the first hour rewards and 500 MEDIA for  the second hour. In such example, the initial slot (1000 MEDIA/1hour) is created by constructor (setting duration to 240 and budget to 1000), while the second slot is added by this method (addinganother 240 duration and 500 allocation). Number of slots is not limited.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|allocation|uint||Funds allocated to this slot|
|1|duration|uint||Duration of this slot|


#### addVerificationAuthority

Add verification authority the promoter trust. Only users verified by one of the authorities can participate in the promotion and push interactions.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|authority|string||Authority name|


#### checkAuthority

Check if a particular user has been verified (KYC performed) by any of the authorities.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|user|address||User whose KYC status is being verified|


#### endPromotion

Ends the promotion contract, finish remaining backlog and return funds.


##### Inputs

empty list


#### getProvider

Return the address of the provider (promoter). Useful for contract factory to do security checks.


##### Inputs

empty list


#### recordInteraction

Record a new interaction.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|user|address||Address of the user who performed the interaction|
|1|interaction|uint32||Interaction type. Shall be one the value of one of the InteractionType|
|2|additionalData|string||Anything else that can be relevant (survey answers etc.)|
|3|referrers|address||List of referrers. Referrer levels are determined by their index in the array, e.g. referrers[1] defines level 1 referrer. refferers[0] denominates the dApp, can be set to address(0).|






### Events




### Enums




### Structs



