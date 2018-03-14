pragma solidity ^0.4.18;

import './Upgradeable.sol';


interface Delegatable{
    /*
     * Group Delegatable
     * Send by master account to specify delegates. Can add more than one delegate.
     * @param delegate Delegate address to add.
     */
    function proposeDelegation ( address delegate ) public;

    /*
     * Group Delegatable
     * Send by potential delegate to specify new master. Can add only one master.
     * @param master Master account address to add.
     */
    function proposeMaster ( address master ) public;

    /*
     * Group Delegatable
     * This method shall be called at the beginning of any "delegateable" function
     * @param sender Find out the master account on behalf of which the sender acts.
     * @return Address of the master account
     */
    function getRealActor( address sender) public view returns (address);

    /*
     * Group Delegatable
     * Removes existing delegate-to-master relationship, where master is the sender
     * @param delegate Delegate address
     */
    function removeDelegate(address delegate) public;

    /*
     * Group Delegatable
     * Removes existing delegate-to-master relationship, where delegate is the sender
     * @param master Master account address
     */
    function removeMaster(address delegate) public;

    /*
     * Group Delegatable
     * Get list of delegates associated with the master account.
     * @param master Master account for which we are looking for delegates
     * @return List of delegates
     */
    function getDelegates(address master)public view returns (address[]);
}

contract DelegatableStorage {
    mapping (address=>address) internal _delegates_to_masters;
    mapping (address=>address[]) internal _masters_to_delegates;

    mapping (address=>mapping(address=>bool)) internal _proposed_delegates;
    mapping (address=>address) internal _proposed_masters;
}

contract DelegatableDispatcher is UpgradeableDispatcher, DelegatableStorage{}

/* This contract allows to create "delegates" to the master account. The delegates can
 * execute certain methods on behalf of the master account. It allows to use delegate private
 * keys on a potentially insecure device without giving too much power to the key.
 */
contract DelegatableImplementation is UpgradeableImplementer, DelegatableStorage, Delegatable {

    /*
     * Group Delegatable
     * Send by master account to specify delegates. Can add more than one delegate.
     * @param delegate Delegate address to add.
     */
    function proposeDelegation ( address delegate ) public {

        if( _delegates_to_masters[delegate] == msg.sender)
            return;
        if( _proposed_masters[delegate] == msg.sender ){
            _delegates_to_masters[delegate] = msg.sender;
            _masters_to_delegates[msg.sender].push(delegate);
            delete _proposed_masters[delegate];
            return;
        }
        _proposed_delegates[msg.sender][delegate] = true;

    }

    /*
     * Send by potential delegate to specify new master. Can add only one master.
     * @param master Master account address to add.
     */
    function proposeMaster ( address master ) public {
        if(_delegates_to_masters[msg.sender]==master)
            return;
        if( _proposed_delegates[master][msg.sender] ){
            _delegates_to_masters[msg.sender] = master;
            _masters_to_delegates[master].push(msg.sender);
            delete _proposed_delegates[master][msg.sender];
        }
        _proposed_masters[msg.sender] = master;
    }

    /*
     * This method shall be called at the beginning of any "delegateable" function
     * @param sender Find out the master account on behalf of which the sender acts.
     * @return Address of the master account
     */
    function getRealActor( address sender) public view returns (address){
        if( _delegates_to_masters[sender]!=address(0) )
            return _delegates_to_masters[sender];
        return sender;
    }

    /*
     * Removes existing delegate-to-master relationship
     * @param delegate Delegate address
     * @param master Master account address
     */
    function removeRelationship(address delegate, address master) private {
        assert(_delegates_to_masters[delegate] == master );
        delete _delegates_to_masters[delegate];
        for(uint i=0; i<_masters_to_delegates[master].length; i++)
            if(_masters_to_delegates[master][i] == delegate)
                delete _masters_to_delegates[master][i];
    }

    /*
     * Removes existing delegate-to-master relationship, where master is the sender
     * @param delegate Delegate address
     */
    function removeDelegate(address delegate) public {
        removeRelationship(delegate, msg.sender);
    }

    /*
     * Removes existing delegate-to-master relationship, where delegate is the sender
     * @param master Master account address
     */
    function removeMaster(address master) public {
        removeRelationship(msg.sender, master);
    }

    /*
     * Get list of delegates associated with the master account.
     * @param master Master account for which we are looking for delegates
     * @return List of delegates
     */
    function getDelegates(address master)public view returns (address[]) {
        return _masters_to_delegates[master];
    }

}
