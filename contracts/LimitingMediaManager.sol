
pragma solidity ^0.4.18;

import './MediaManager.sol';

/*
 * The MediaManager is a contract associated in 1-1 relationship with a MediaToken.
 * This contract allows its owner to run transferFrom on the associated token for any users.
 * It is created together with the token as part of the token initialization procedure, and
 * is expected to run only temporarily. It can be destructed, and then no new managing contract
 * will be associated with the token.
 * This mechanism has been added to allow hybrid-model deployment, when trusted non-blockchain
 * application evaluates various conditions and manages transfers accordingly.
 * Users can opt-out from this mechanism, in which case the application can't transfer anything
 * on their behalf.
 */
contract LimitingMediaManager {
    address private owner;
    address private transferer;
    address private mediaManager;
    uint private limit;

    /*
     * MediaManager constructor. It is expected that constructor is run from the Token
     * initialization procedure, as it uses msg.sender as token address.
     * @param _mediaManager
     */
    function LimitingMediaManager(address _mediaManager, address _transferer, uint _limit)public {
        owner = msg.sender;
        mediaManager = _mediaManager;
        transferer = _transferer;
        limit = _limit;
    }

    /*
     * Modifier. Any method can be called only by the owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    /*
     * Modifier. Any method can be called only by the owner
     */
    modifier onlyTransferer() {
        if (msg.sender != transferer) {
            revert();
        }
        _;
    }

    /*
     * Set new transfer limit
     */
    function setNewLimit(uint newLimit) public onlyOwner{
       limit = newLimit;
    }

    /*
     * Executes transferFrom on the associated token. Unless the user has opt-outed, the token
     * shall allow such transferFrom set out of the MediaManager contract.
     * @param _from Address to transfer from
     * @param _to Address to which funds are transferred
     * @param _value Number of tokes to be transfered
     * @return True on success
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyTransferer returns (bool){
        assert(_value < limit);
        MediaManager mm = MediaManager(mediaManager);
        return mm.transferFrom(_from, _to, _value);
    }

    /*
     * Transfer ownership to new owner
     * @param newOwner New owner. No validity check is performed, execute this method with great care!
     */
    function transferOwnership(address newOwner)public onlyOwner{
        owner=newOwner;
    }

    /*
     * Transfer transfership to new transferer
     * @param newTransferer New transferer. No validity check is performed, execute this method with great care!
     */
    function transferTransferer(address newTransferer)public onlyOwner{
        transferer=newTransferer;
    }

    /*
     * Destroy this contract and the underlying MediaManager contract. Execute when switching from hybrid model to fully blockchain model.
     */
    function exit() public onlyOwner{
        MediaManager mm = MediaManager(mediaManager);
        mm.exit();
        selfdestruct(owner);
    }
}
