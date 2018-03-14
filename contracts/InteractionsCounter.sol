pragma solidity ^0.4.18;
import './Delegatable.sol';
import './MediaTokenUser.sol';

contract InteractionsCounterStorage{

    mapping(address => mapping(uint32 => uint32)) internal _interactions;
    mapping(address => uint) internal _lastAction;
    uint constant internal _resetInterval = 5760; //24 * 60 * 60 / 15, i.e. 1 day
}

/*
 * Contract InteractionsCounter keeps track on number of user interactions during each resetInterval (5760 blocks or appr. 24h).
 * InteractionsCounter is not marked as upgradeable, as the interactions can be reported even after pause for existing promotions.
 */
contract InteractionsCounter{
    enum InteractionType{short, medium, long, LAST, NONE}
    /*
     * Group InteractionCounter
     * Record interaction with this method. Used by the Promotion contracts.
     * @param ineractionType Type of the interaction - short/medium/long.
     */
    function addInteraction( uint32 interactionType )public returns (uint32);

}

contract InteractionsCounterDispatcher is DelegatableDispatcher, MediaTokenUser, InteractionsCounterStorage{}

contract InteractionsCounterImplementation is DelegatableImplementation, MediaTokenUser, InteractionsCounterStorage, InteractionsCounter{
    /*
     * User record interactions with this method.
     * \param ineractionType Type of the interaction - short/medium/long.
     */
    function addInteraction( uint32 interactionType )public returns (uint32){
        var user = tx.origin;
        resetInteractions(user);
        require(interactionType < uint32(InteractionType.LAST));
        _lastAction[user] = block.number;
        return ++_interactions[user][interactionType];
    }

    /*
     * Private method that checks current interval, and if new one beginned, resets user stats.
     * \param user User in concern.
     */
    function resetInteractions( address user )private{
        if( (_lastAction[user] / _resetInterval) != (block.number / _resetInterval) ){
            for( uint32 i = 0; i< uint32(InteractionType.LAST); i++)
                _interactions[user][i] = 0;
        }
    }

}
