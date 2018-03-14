












# IdentityVerification

### The potential identity verification provider has to register first to provide mapping between them usernameand ethereum address. ATM the mapping is 1:1.



## Functions



### Constant functions





### State changing functions

#### addUserVerification

Confirm that the user KYC has been performed.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|user|address||Address of the verified user|


#### checkVerificationStatus

Check the verificaiton status of a user by a service


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|verifier|string||Name of the verificaiton service|
|1|user|address||Address oft the user|


#### getServiceByUser

Get service name by user address.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|user|address||Address of the user owning the service|


#### getUserByService




##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|service|string|||


#### registerService

Anyone can register his service with this method. His address will be associated with the newly registerd name.The name is the unique identifier of the service. Only one service can be associated to an address.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|name|string||Name of the verification service. The name shall be at least 4 and up to 64 chars long.|


#### removeUserVerification

Remove user KYC verification.


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|user|address||Address of the user|


#### transferService

Register a new address for the given service


##### Inputs

|#  |Param|Type|TypeHint|Description|
|---|-----|----|--------|-----------|
|0|name|string||Name of the service|
|1|newAddress|address||New address|






### Events




### Enums




### Structs



