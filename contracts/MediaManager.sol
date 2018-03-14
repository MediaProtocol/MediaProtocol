
pragma solidity ^0.4.18;

import './MediaToken.sol';

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
contract MediaManager {
    address private owner;
    address private token;

    /*
     * MediaManager constructor. It is expected that constructor is run from the Token
     * initialization procedure, as it uses msg.sender as token address.
     * @param _manager the new owner of the contract.
     */
    function MediaManager(address _manager)public {
        owner = _manager;
        token = msg.sender;
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
     * Executes transferFrom on the associated token. Unless the user has opt-outed, the token
     * shall allow such transferFrom set out of the MediaManager contract.
     * @param _from Address to transfer from
     * @param _to Address to which funds are transferred
     * @param _value Number of tokes to be transfered
     * @return True on success
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyOwner returns (bool){
        MediaToken mt = MediaToken(token);
        return mt.transferFrom(_from, _to, _value);
    }

    /*
     * Transfer ownership to new owner
     * @param newOwner New owner. No validity check is performed, execute this method with great care!
     */
    function transferOwnership(address newOwner)public onlyOwner{
        owner=newOwner;
    }

    /*
     * Destroy this contract. Execute when switching from hybrid model to fully blockchain model.
     */
    function exit() public onlyOwner{
        selfdestruct(owner);
    }
}
