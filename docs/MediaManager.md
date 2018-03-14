












# MediaManager

### The MediaManager is a contract associated in 1-1 relationship with a MediaToken.This contract allows its owner to run transferFrom on the associated token for any users.It is created together with the token as part of the token initialization procedure, andis expected to run only temporarily. It can be destructed, and then no new managing contractwill be associated with the token.This mechanism has been added to allow hybrid-model deployment, when trusted non-blockchainapplication evaluates various conditions and manages transfers accordingly.Users can opt-out from this mechanism, in which case the application can't transfer anythingon their behalf.



## Functions



### Constant functions





### State changing functions

#### exit

Destroy this contract. Execute when switching from hybrid model to fully blockchain model.


##### Inputs

empty list


#### transferFrom

Executes transferFrom on the associated token. Unless the user has opt-outed, the tokenshall allow such transferFrom set out of the MediaManager contract.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|_from|address||Address to transfer from|
|1|_to|address||Address to which funds are transferred|
|2|_value|uint256||Number of tokes to be transfered|


#### transferOwnership

Transfer ownership to new owner


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|newOwner|address||New owner. No validity check is performed, execute this method with great care!|






### Events




### Enums




### Structs



