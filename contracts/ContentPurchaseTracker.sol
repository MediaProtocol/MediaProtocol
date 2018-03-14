pragma solidity ^0.4.18;


import './Upgradeable.sol';
import './Delegatable.sol';

import './MediaToken.sol';
import './MediaTokenUser.sol';

/*
 * BuyingTracker keeps track of all content buyings. Since buying tracker cannot determine if the paid price for
 * a content was high enough (it can change over time, even for different customers based on actual promotions),
 * or even paid to the right account, it is up the content provider to verify it. BuyingTracker can only confirm
 * that at the given time, so much MEDIA have been paid paid to that address for content with given identifier.
 */
interface ContentPurchaseTracker {
    /*
     * Event generated when some buying happens. It is on the application to check that the price match the requirements.
     */
    event ContentPurchaseRecord(
        string id,
        address provider,
        uint price,
        uint block
    );

    /*
     * The user can buy content by issuing this method. He (his dAPP) has to take care that the address and
     * the price match the given piece of content. Content is identified by its ID, usually URL. The content
     * can be purchased several times, in which case the total sum and block of last action is recorded.
     * @param id Content identification, usually URL.
     * @param provider Address where the funds has to be send.
     * @param price Price to be paid. Has to be same or higher as actual price for the given user.
     */
    function buyContent(string id, address provider, uint price ) public;
}

contract ContentPurchaseTrackerDispatcher is DelegatableDispatcher, MediaTokenUser{}

contract ContentPurchaseTrackerImplementation is DelegatableImplementation, MediaTokenUser, ContentPurchaseTracker {
    /*
     * Event generated when some buying happens. It is on the application to check that the price match the requirements.
     */
    event ContentPurchaseRecord(
        string indexed id,
        address indexed provider,
        address indexed buyer,
        uint price,
        uint block
    );

    /*
     * The user can buy content by issuing this method. He (his dAPP) has to take care that the address and
     * the price match the given piece of content. Content is identified by its ID, usually URL. The content
     * can be purchased several times, in which case the total sum and block of last action is recorded.
     * @param id Content identification, usually URL.
     * \provider Address where the funds has to be send.
     * \price Price to be paid. Has to be same or higher as actual price for the given user.
     */
    function buyContent(string id, address provider, uint price ) public {
        address user = getRealActor(msg.sender);
        MediaToken mt = MediaToken(_token);

        mt.transferFrom(user, provider,price);

        ContentPurchaseRecord(id, provider, user, price, block.number);
    }//*/

}
