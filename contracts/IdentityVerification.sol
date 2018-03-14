pragma solidity ^0.4.18;
import './Upgradeable.sol';

/* Interface contract. Specifies interface methods of the Identity Verification Services.
 * The potential identity verification provider has to register first to provide mapping between them username
 * and ethereum address. ATM the mapping is 1:1.
 */
interface IdentityVerification{
   /*
    * Anyone can register his service with this method. His address will be associated with the newly registerd name.
    * The name is the unique identifier of the service. Only one service can be associated to an address.
    * @param name Name of the verification service. The name shall be at least 4 and up to 64 chars long.
    */
   function registerService(string name) public;

   /*
    * Register a new address for the given service
    * @param newAddress New address
    * @param name Name of the service
    */
   function transferService(string name, address newAddress) public;

   /*
    * Confirm that the user KYC has been performed.
    * @param user Address of the verified user
    */
   function addUserVerification(address user) public;

   /*
    * Remove user KYC verification.
    * @param user Address of the user
    */
   function removeUserVerification(address user) public;

   /*
    * Check the verificaiton status of a user by a service
    * @param verifier Name of the verificaiton service
    * @param user Address oft the user
    * @return true is the service has successfully performed KYC on the user, false otherwise
    */
   function checkVerificationStatus(string verifier, address user) public view returns (bool);

   /*
    * Get service name by user address.
    * @param user Address of the user owning the service
    * @return Name of the service if existing, empty string otherwise
    */
   function getServiceByUser(address user) public view returns (string);
   function getUserByService(string service) public view returns (address);

}


/* Defines storage of the Identity Verification. */
contract IdentityVerificationStorage{
   mapping (string => mapping(address => bool)) internal _verified_by;
   mapping (string => address) internal _name_to_address;
   mapping (address => string) internal _address_to_name;
}

contract IdentityVerificationDispatcher is UpgradeableDispatcher, IdentityVerificationStorage {
   function IdentityVerificationDispatcher(address target) public{
      _owner = msg.sender;
      replaceImplementation(target);
   }
}


/*
 * Contract IdentityVerification provides basis implementation of the Identity Verification Services.
 * The potential identity verification provider has to register first to provide mapping between them username
 * and ethereum address. ATM the mapping is 1:1.
 */
contract IdentityVerificationImplementation is IdentityVerification, UpgradeableImplementer, IdentityVerificationStorage {

   function registerService(string name) public{
      require(bytes(name).length > 3 && bytes(name).length <= 64);
      require(bytes(_address_to_name[msg.sender]).length == 0 ); //only one service can be associated with an address.
      require(_name_to_address[name] == address(0)); //cannot use existing service name
      _name_to_address[name] = msg.sender;
      _address_to_name[msg.sender] = name;
   }

   function transferService(string name, address newAddress) public{
      require(_name_to_address[name] == msg.sender);
      require(keccak256(_address_to_name[msg.sender]) == keccak256(name));
      delete _address_to_name[msg.sender];
      _name_to_address[name] = newAddress;
      _address_to_name[newAddress] = name;
   }

   function addUserVerification(address user) public{
      string memory service = _address_to_name[msg.sender];
      require( bytes(service).length != 0 );
      _verified_by[service][user] = true;
   }

   function removeUserVerification(address user) public{
      string memory service = _address_to_name[msg.sender];
      require( bytes(service).length != 0 );
      if(_verified_by[service][user])
         delete _verified_by[service][user];
   }

   function checkVerificationStatus(string verifier, address user) public view returns (bool){
      if(bytes(verifier).length <= 3 )
         return false;
      return _verified_by[verifier][user];
   }

   function initialize() public{
      _returnSizes[bytes4(keccak256("checkVerificationStatus(string,address)"))] = 32;
      _returnSizes[bytes4(keccak256("getServiceByUser(address)"))] = 64+64;
      _returnSizes[bytes4(keccak256("getUserByService(string)"))] = 32;
   }

   function getServiceByUser(address user) public view returns (string){
      return _address_to_name[user];
   }

   function getUserByService(string service) public view returns (address){
      return _name_to_address[service];
   }
}

