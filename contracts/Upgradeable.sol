pragma solidity ^0.4.18;

contract Upgradeable{
    /*
     * Modifier. Any method can be called only by the owner
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert();
        }
        _;
    }


    address internal _implementation;
    mapping(bytes4=>uint32) internal _returnSizes;
    address internal _owner;
}

contract UpgradeableDispatcher is Upgradeable{

    /*
     * Event ContractUpgrade is fired to notify stakeholders about contract code upgrade.
     */
    event ContractUpgrade(address dispatcher, address oldImplementation, address newImplementation);

    /**
     * Performs a handover to a new implementing contract.
     */
    function replaceImplementation(address newImplementation) public onlyOwner{
        ContractUpgrade(this, _implementation, newImplementation );
        _implementation = newImplementation;
    }


    /*
     * Set the owner. Useful when constructor is not practical to call (e.g. in some cases in inherited classes
     * constructor). Can be called only once.
     * \param owner The new owner address to add.
     */
    function setOwner(address owner) public{
        require(_owner == address(0));
        _owner = owner;
    }

    /*
     * Change the contract owner.
     * \param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner)public onlyOwner{
        _owner = newOwner;
    }


    /*
     * Default function handler. If there is no matching function, do delegatecall of the implementation contract
     */
    function() public{
        require(msg.gas > 10000 ); //TODO: replace with gasleft() when upgrading to 0.4.21
        address _impl = _implementation;
        require(_impl != address(0));
        bytes memory data = msg.data;

        assembly {
            let result := delegatecall(sub(gas, 10000), _impl, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }

    } //*/
}


contract UpgradeableImplementer is Upgradeable{

}
