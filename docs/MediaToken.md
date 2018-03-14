












# MediaToken

### An ERC20 token, that can be managed by external MediaManager contract. This MediaManager contractis created during creation of the MediaToken, and can't be changed. Once MediaManager exits, noother can't be set.transferFrom transcations are not subject to tests if the contract has been approved or not.\see MediaManager



## Functions



### Constant functions

#### allowanceRecurrent

Check the recurrent spending approval for a given holder and spender.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|tokenOwner|address||Holder of the tokens|
|1|spender|address||Spender|


##### Returns

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|remaining|uint|||
|1|totalLimit|uint|||
|2|interval|uint32|||
|3|intervalStart|uint|||


#### decimals




##### Inputs

empty list


##### Returns

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|return0|uint8||decimals|


#### managementContract




##### Inputs

empty list


##### Returns

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|return0|MediaManager||managementContract|


#### name




##### Inputs

empty list


##### Returns

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|return0|string||name|


#### symbol




##### Inputs

empty list


##### Returns

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|return0|string||symbol|


#### totalSupply




##### Inputs

empty list


##### Returns

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|return0|uint256||totalSupply|






### State changing functions

#### allowance

Function to check the amount of tokens that an owner allowed to a spender.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|_owner|address||address The address which owns the funds.|
|1|_spender|address||address The address which will spend the funds.|


#### approve

Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
Beware that changing an allowance with this method brings the risk that someone may use both the oldand the new allowance by unfortunate transaction ordering. One possible solution to mitigate thisrace condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|_spender|address||The address which will spend the funds.|
|1|_value|uint256||The amount of tokens to be spent.|


#### approveRecurrent

Allow recurrent payments by spender on sender's account, in max. amount of token per interval.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|spender|address||who is being authorized|
|1|tokens|uint||maximum allowed per interval|
|2|interval|uint32||Interval length in blocks|


#### balanceOf

Gets the balance of the specified address.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|_owner|address||The address to query the the balance of.|


#### decreaseApproval




##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|_spender|address|||
|1|_subtractedValue|uint|||


#### disableManager

opt-out from the MediaManager services.


##### Inputs

empty list


#### increaseApproval

approve should be called when allowed[_spender] == 0. To incrementallowed value is better to use this function to avoid 2 calls (and wait untilthe first transaction is mined)From MonolithDAO Token.sol


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|_spender|address|||
|1|_addedValue|uint|||


#### managerAllowed

Check if the given user is managed by the management contract.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|user|address||User to check|


#### transfer




##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|to|address|||
|1|value|uint256|||


#### transferFrom

transferFrom transfers user balances on his behalf. Unless the user has opt-outed, the tokenshall allow transferFrom set out of the MediaManager contract.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|_from|address||Address to transfer from|
|1|_to|address||Address to which funds are transferred|
|2|_value|uint256||Number of tokes to be transfered|






### Events

#### Transfer




##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|from|address|||
|1|to|address|||
|2|value|uint256|||


#### Approval




##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|owner|address|||
|1|spender|address|||
|2|value|uint256|||


#### ApprovalRecurrent




##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|tokenOwner|address|||
|1|spender|address|||
|2|tokens|uint|||
|3|interval|uint32|||


#### ExternalTransfer

Event ExternalTransfer is fired every time a transfer that is not initiated by managementContract happens


##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|from|address|||
|1|to|address|||
|2|spender|address|||
|3|tokens|uint|||





### Enums




### Structs

#### recurrentAllowance




##### Params

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|allowed|uint256|||
|1|interval|uint32|||
|2|remains|uint256|||
|3|intervalStart|uint|||




