pragma solidity ^0.4.18;

import './Upgradeable.sol';
import './Delegatable.sol';

import './MediaToken.sol';
import './MediaTokenUser.sol';

interface SubscriptionDefinition{
    function getPrice(address subscriber, string url, uint period) view public returns(uint price, uint maxPrice);
}

contract SimpleSubscriptionDefinition{
    function getPrice(address subscriber, string url, uint period) view public returns(uint price, uint maxPrice){ return (period,period);}
}

library subscriptionManagerLibrary{
    function registerSubscriptionOffer(string uri, uint period, address definition, SubscriptionManagerStorage.SubscriptionData storage data)public{
        require(bytes(uri).length > 3 && bytes(uri).length<=160);
        require(data._subscriptionOffers[uri][period]._provider == address(0)|| data._subscriptionOffers[uri][period]._provider == msg.sender);
        data._subscriptionOffers[uri][period]._definition = definition;
        data._subscriptionOffers[uri][period]._subscriptionPeriod = period;
        data._subscriptionOffers[uri][period]._uri = uri;
        data._subscriptionOffers[uri][period]._provider = msg.sender;

    }

    function subscribe(address subscriber, string uri, uint period, SubscriptionManagerStorage.SubscriptionData storage data, address token) public{
        MediaToken mt = MediaToken(token);
        require(data._subscriptionOffers[uri][period]._definition != address(0));

        uint expiration;
        if( data._subscriptionRecords[subscriber][uri].expiration > block.number )
            expiration = data._subscriptionRecords[subscriber][uri].expiration + period;
        else
            expiration = block.number + period;

        uint price;
        uint maxPrice;
        (price, maxPrice) = SubscriptionDefinition(data._subscriptionOffers[uri][period]._definition).getPrice(msg.sender, uri, period);

        require(data._subscriptionRecords[subscriber][uri].maxPrice >= price && data._subscriptionRecords[subscriber][uri].maxPrice >= maxPrice);
        data._subscriptionRecords[subscriber][uri].duration = uint32(period);
        data._subscriptionRecords[subscriber][uri].expiration = expiration;
        data._subscriptionRecords[subscriber][uri].maxPrice = maxPrice;
        mt.transferFrom(subscriber, data._subscriptionOffers[uri][period]._provider, price);

    }

    function renewSubscription( string uri, address subscriber, SubscriptionManagerStorage.SubscriptionData storage data, address token ) public{
        uint period = data._subscriptionRecords[subscriber][uri].duration;
        require(data._subscriptionOffers[uri][period]._provider == msg.sender );
        MediaToken mt = MediaToken(token);

        uint price;
        uint maxPrice;
        (price, maxPrice) = SubscriptionDefinition(data._subscriptionOffers[uri][period]._definition).getPrice(subscriber, uri, period);

        require( data._subscriptionRecords[subscriber][uri].maxPrice >= price );

        uint difference;
        if(data._subscriptionRecords[subscriber][uri].expiration > block.number){
            difference = data._subscriptionRecords[subscriber][uri].expiration - block.number;
            data._subscriptionRecords[subscriber][uri].expiration += period;
        }else{
            difference = block.number - data._subscriptionRecords[subscriber][uri].expiration;
            data._subscriptionRecords[subscriber][uri].expiration = block.number + period;
        }
        require(difference <= (period +3) / 4);
        mt.transferFrom(subscriber, data._subscriptionOffers[uri][period]._provider, price);

    }

    //function cancelSubscription( string uri, address subscriber ) public;
}

/*
 * Contract SubscriptionManager stores information about subscription offers and the actual subscriptions.
 *
 */
interface SubscriptionManager{
    event Subscribe(string indexed uri, address indexed subscriber, uint fromBlock, uint toBlock);
    event Unsubscribe(string indexed uri, address indexed subscriber, uint fromBlock);
    event RegisterSubscriptionOffer(string indexed uri, uint period, address definition);
    event CancelSubscriptionOffer(string indexed uri, uint period );

    /*
     * Group Subscriptions
     *
     * Creates new subscription offer. Each offer is defined by its uri and period as unique identifier and definition
     * contract. Definition contract is of type SubscriptionDefinition and must define method "getPrice(address subscriber,
     * string url, uint period) returns(uint price, uint maxPrice)". This method will calculate the price for a given
     * subscriber, as well as maximum price used during renewals. This allows flexible promotions like "pay 1 MEDIA for
     * initial month, and 10 MEDIA/month afterwards" or "since you filled our survey, you get 10% discount for next 3
     * months".
     *
     * Each subscription offering is identified by both URI and duration, allowing subscription of different lenght, e.g.
     * weekly and yearly subscriptions to the same page.
     *
     * @param uri Offer identifier' at least 4 and at most 160 characters
     * @param period Lenght of the subscription in blocks (appr. 15s)
     * @param definition Contract defining the price
     */
    function registerSubscriptionOffer(string uri, uint period, address definition)public ;

    /*
     * Group Subscriptions
     *
     * Ends the subscription offering
     * @param uri Identifier of the offering
     * @param period Identifier of the offering
     */
    function cancelSubscriptionOffer(string uri, uint period) public;

    /*
     * Group Subscriptions
     *
     * Get subscription offering price for the calling user. Also, sets the maximum price the user will be charged, to
     * avoid scenarios when one price is advertised and different charged.
     * @param uri Identifier of the offering
     * @param period Identifier of the offering
     */
    function getSubscriptionPrice(string uri, uint period) public returns (uint price, uint maxPrice);

    /*
     * Group Subscriptions
     *
     * Subscribe to an offering. The subscribe can be called only after getSubscriptionPrice, to make sure customer is
     * sure about the pricing.
     * @param uri Identifier of the offering
     * @param period Identifier of the offering
     */
    function subscribe(string uri, uint period) public;

    /*
     * Group Subscriptions
     * Unsubscribe from an offering
     * @param uri Identifier of the offering
     */
    function unsubscribe(string uri) public;

    /*
     * Group Subscriptions
     *
     * The subscription provider can automatically renew the subscription. The subscription can be renewed only in
     * time slot from 'expiration time - subscription length/4'  to 'expiration time + subscription length/4' to avoid
     * frauds
     * @param uri Identifier of the offering
     * @param subscriber Subscriber
     */
    function renewSubscription( string uri, address subscriber ) public;

    /*
     * Group Subscriptions
     *
     * The subscription provider can cancel the subscription - e.g. if the recurring payment fails. Only expired
     * subscriptions can be canceled
     * @param uri Identifier of the offering
     * @param subscriber Subscriber
     */
    function cancelSubscription( string uri, address subscriber ) public;

    /*
     * Group Subscriptions
     *
     * Check the subscription status.
     * @param uri Identifier of the offering
     * @param subscriber Subscriber
     */
    function isSubscriber(string uri, address subscriber ) public view returns (bool);
}

contract SubscriptionManagerStorage{
    struct subscriptionInfo{
        uint32 duration;
        uint expiration;
        uint maxPrice;
    }

    /*
     * Group Subscriptions
     * This structure stores the possible subscription offers.
     */
    struct SubscriptionOffer{
        address _provider;
        address _definition;
        string _uri;
        uint _subscriptionPeriod;
    }

    struct SubscriptionData{
        mapping (address=>mapping(string => subscriptionInfo ))  _subscriptionRecords;
        mapping (string=>mapping(uint=>SubscriptionOffer)) _subscriptionOffers;
    }

    SubscriptionData internal _subscriptionData;
}

contract SubscriptionManagerDispatcher is DelegatableDispatcher, MediaTokenUser, SubscriptionManagerStorage{}

contract SubscriptionManagerImplementation is DelegatableImplementation, MediaTokenUser, SubscriptionManagerStorage, SubscriptionManager {

    function registerSubscriptionOffer(string uri, uint period, address definition)public {
        subscriptionManagerLibrary.registerSubscriptionOffer(uri, period, definition, _subscriptionData);
        RegisterSubscriptionOffer(uri, period, definition);
    }

    function cancelSubscriptionOffer(string uri, uint period) public{
        require(_subscriptionData._subscriptionOffers[uri][period]._provider == msg.sender);
        delete _subscriptionData._subscriptionOffers[uri][period];
        CancelSubscriptionOffer(uri, period);
    }

    function getSubscriptionPrice(string uri, uint period) public returns (uint price, uint maxPrice){
        require(_subscriptionData._subscriptionOffers[uri][period]._definition != address(0));
        (price, maxPrice) = SubscriptionDefinition(_subscriptionData._subscriptionOffers[uri][period]._definition).getPrice(msg.sender, uri, period);
        _subscriptionData._subscriptionRecords[msg.sender][uri].maxPrice = maxPrice;
        return (price, maxPrice);
    }

    function subscribe(string uri, uint period) public {
        address subscriber = getRealActor(msg.sender);
        subscriptionManagerLibrary.subscribe(subscriber, uri, period, _subscriptionData, _token);
        Subscribe(uri, subscriber, block.number, _subscriptionData._subscriptionRecords[subscriber][uri].expiration);
    }

    function unsubscribe(string uri) public{
        address subscriber = getRealActor(msg.sender);
        _subscriptionData._subscriptionRecords[subscriber][uri].maxPrice = 0;
        Unsubscribe(uri, subscriber, block.number);
    }

    function cancelSubscription( string uri, address subscriber ) public{
        uint period = _subscriptionData._subscriptionRecords[subscriber][uri].duration;
        require(_subscriptionData._subscriptionOffers[uri][period]._provider == msg.sender );
        _subscriptionData._subscriptionRecords[subscriber][uri].maxPrice = 0;
        Unsubscribe(uri, subscriber, block.number);
    }

    function renewSubscription( string uri, address subscriber ) public{
        subscriptionManagerLibrary.renewSubscription(uri, subscriber, _subscriptionData, _token);
        Subscribe(uri, subscriber, block.number, _subscriptionData._subscriptionRecords[subscriber][uri].expiration );
    }

    /*
     * Check the subscription status.
     * @param uri Identifier of the offering
     * @param subscriber Subscriber
     */
    function isSubscriber(string uri, address subscriber ) public view returns (bool){
        return _subscriptionData._subscriptionRecords[subscriber][uri].expiration >= block.number;
    }


}
