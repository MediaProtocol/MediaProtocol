# Use cases

## User verification

The user verification is a service, handled by contract IdentityVerification. The verifiers can publicly acknowledge, that they have perform KYC and are aware of the identity of a given consumer. 
Anyone can check the KYC status, i.e. if the given userhas been verified by the given verifier. 

### Flow
1. First, the verifier has to register a service in the contract, using the ```registerService``` method.
2. Then, the verifier can confirm KYC status of one or more users with ```addUserVerification``` method. 
3. Anybody can check the KYC status of a user by calling the ```checkVerificationStatus``` call. 


## Promotions

### Flow for promotion creation
0. As a prerequisite, the promoter has to approve the ```Promotions``` contract to spend MEDIA tokens on his behalf using the ```approve``` method of ```MediaToken``` contract. 
1. The promoter starts with calling the method ```promotionRegister``` method of ```Promotions``` contract. New ```Promotion``` contract is created specifically for this promotion. The event ```CreatePromotion``` is generated.
2. The address of the ```Promotion``` contract can be retrieved using ```promotionGet``` call. 
3. If needed, one or more URLs can be associated with the promotion using the ```Promotions.promotionAddNewUrl``` method. The event ```AddPromotionUrl``` is generated in such case.
4. If needed, the promotion can be extended with more time slots, each having own budget allocation. E.g.  The promoter can allocate 1000 MEDIA for the rewards in first hour, and 500 MEDIA for the second hour. In such example, the initial slot (1000 MEDIA/1hour) is created by ```promotionRegister``` method (setting duration to 240 and budget to 1000), while the  second slot is added by ```addBudget``` method (add in another 240 blocks duration and 500 tokens allocation). Anytime the promotion time is extended, the event ```ExtendPromotion``` is generated.
5. If needed, the promoter can specify the user verification services with method ```Promotion.addVerificationAuthority```. 
6. During the validity period, the user can record their interactions. If one or more verification services are specified, only users who passed verification with any of these services can record their interactions. 
7. When the promotion ends, the promoter has to clean up with ```Promotion.endPromotion``` method. 

### Promotion interaction
The users can interact with the promotion through ```Promotions``` contract, using ```recordInteraction``` method. They can record only allowed events, and only once per user. Anytime new interaction is recorded, the event ```PromotionInteraction``` is generated.

## Delegations
Every user can delegate other account to act with the ```Promotions``` contract on his behalf. The delegating account, aka master, authorizes the delegate account using ```proposeDelegation```. The delegate account, similarly, accepts master authorisation with ```proposeMaster```. One master can have multiple delegates, one delegate can have only one master. 

Master account has to approve the ```Promotions``` contract to spend MEDIA tokens on his behalf to allow content buying and subscription buying (see bellow). 

## Content buying
Users can use their tokens to buy digital goods, e.g. paywalled articles. This is done using the ```buyContent``` method. The method transfers the MEDIA token to the receiving account and generates ```ContentPurchaseRecord``` event. It is up to the receiving contract to check the amount and other variables.
Delegation apply in this scenario.

## Subscriptions
Promotions contract provides support for subscriptions to digital content. 

### Subscription creation flow
0. The paywall administrator has to prepare definitions of allowed subscribtion durations.
1. The paywall administrator starts with creating an own ```SubscriptionDefinition``` contract (let's name it ```MySubscriptionDefinition```). This contract has to implement at least the ```getPrice(address subscriber, string url, uint period) view public returns(uint price, uint maxPrice)``` method, that assigns price for subscription per given subscriber. The price is price for initial subscription period, the maxPrice is the maximum price ever charged by the subscription (this allowes promotions like "subscribe and get the first month for 1 MEDIA, 10 MEDIA afterwards"). The contract has to be deployed to the network. 
2. The paywall administrator then register subscription offer using ```Promotions.registerSubscriptionOffer``` method. The address of the deployed ```MySubscriptionDefinition``` contract is passed as one parameter. 
3. ```RegisterSubscriptionOffer```event is generated. 
4. Later, the paywall administrator can delete the offer with ```cancelSubscriptionOffer method```. In that case, event ```CancelSubscriptionOffer``` is generated.

### Subscription flow
0. As a prerequisite, the subscriber must allow the ```Promotions``` contract to spend Media on his behalf using ```approve``` or preferably ```approveRecurrent``` methods. 
1. A potential subscribers can subscribe to a valid subscription offer with ```Promotions.subscribe``` method. They can check the price upfront with ```Promotions.getSubscriptionPrice``` call. 
2. Event ```Subscribe``` is generated in case subscription is successful. Initial subscription price is charged. Delegation apply in this scenario.
3a. The subscriber can prolong the subscription himself with another ```Promotions.subscribe``` call. 
3b. Alternatively, the paywall administrator can renew the subscription at the end of the period with ```Promotions.renewSubscription``` method. In both cases, the subscriber is charged the price, and ```Subscribe``` event is generated.
4. The paywall administrator, or any affiliate site administrator, can check the subscription status with ```Promotions.isSubscriber``` call.
5a. The subscriber can end the subscription with ```Promotions.unsubscribe``` method.
5b. The paywall administrator can end the subscription as well using the ```Promotions.cancelSubscription``` method. In both cases, the event ```Unsubscribe``` is generated.
