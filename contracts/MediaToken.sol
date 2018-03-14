pragma solidity ^0.4.18;

import './MediaManager.sol';
import './StandardTokenWithRecurrency.sol';



/*
 * An ERC20 token, that can be managed by external MediaManager contract. This MediaManager contract
 * is created during creation of the MediaToken, and can't be changed. Once MediaManager exits, no 
 * other can't be set. 
 * transferFrom transcations are not subject to tests if the contract has been approved or not.
 * \see MediaManager
 */
contract MediaToken is StandardTokenWithRecurrency {

   /*
    *Event ExternalTransfer is fired every time a transfer that is not initiated by managementContract happens
    */
   event ExternalTransfer(address indexed from, address indexed to, address indexed spender, uint tokens);

   string public constant name = "MediaToken";
   string public constant symbol = "MEDIA";
   uint8 public constant decimals = 18;
   MediaManager public managementContract;

   struct recurrentAllowance{
      uint256 allowed;
      uint32 interval;
      uint256 remains;
      uint intervalStart;
   }
   mapping (address => mapping (address => recurrentAllowance)) internal recurrentAllowed;


   mapping(address=>bool) private disabledManager; //<uninitialized = 0, allowed = 1, disabled = 2

   /*
    * Allow recurrent payments by spender on sender's account, in max. amount of token per interval.
    * @param spender who is being authorized
    * @param tokens maximum allowed per interval
    * @param interval Interval length in blocks
    * @return bool on success
    */
   function approveRecurrent(address spender, uint tokens, uint32 interval) public returns (bool success){
      recurrentAllowance memory al;
      al.allowed = tokens;
      al.interval = interval;
      al.remains = tokens;
      al.intervalStart = block.number;
      recurrentAllowed[msg.sender][spender] = al;
      ApprovalRecurrent(msg.sender, spender, tokens, interval);
      return true;
   }

   /*
    * Check the recurrent spending approval for a given holder and spender.
    * @param tokenOwner Holder of the tokens
    * @param spender Spender
    * @returns remaining Tokens available to spend in this interval
    * @returns totalLimit Tokens available to spend each interval
    * @returns interval Interval length in blocks
    * @returns intervalStart Blocks when the current interval starts
    */
   function allowanceRecurrent(address tokenOwner, address spender) public constant returns (uint remaining, uint totalLimit, uint32 interval, uint intervalStart){
      return (recurrentAllowed[tokenOwner][spender].remains, recurrentAllowed[tokenOwner][spender].allowed, recurrentAllowed[tokenOwner][spender].interval, recurrentAllowed[tokenOwner][spender].intervalStart);
   }

   function canSpend(address spender, address from, uint256 value) internal returns (bool){
      if( recurrentAllowed[from][spender].interval > 0 && block.number >= recurrentAllowed[from][spender].intervalStart + recurrentAllowed[from][spender].interval ){ //we shall reset the interval now
         uint newIntervalStart =  recurrentAllowed[from][spender].intervalStart + ((block.number - recurrentAllowed[from][spender].intervalStart) / recurrentAllowed[from][spender].interval) * recurrentAllowed[from][spender].interval;
         recurrentAllowed[from][spender].intervalStart = newIntervalStart;
         recurrentAllowed[from][spender].remains = recurrentAllowed[from][spender].allowed;
      }

      if( value <= allowed[from][spender] + recurrentAllowed[from][spender].remains)
         return true;

      return false;

   }

   /* 
    * Constructor. Also creates associated MediaManager and stores its address to managementContract field
    * @param initialBalance Contract initial balance. All will be allocated to the caller(msg.sender).
    */
   function MediaToken(uint initialBalance) public{
      totalSupply = initialBalance;
      balances[msg.sender] = initialBalance;
      managementContract = new MediaManager(msg.sender);
   }

   /*
    * transferFrom transfers user balances on his behalf. Unless the user has opt-outed, the token 
    * shall allow transferFrom set out of the MediaManager contract.
    * @param _from Address to transfer from
    * @param _to Address to which funds are transferred
    * @param _value Number of tokes to be transfered
    * @return True on success
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
      require(_to != address(0));
      require(_value <= balances[_from]);
      if(msg.sender == address(managementContract)){
         require(!disabledManager[_from]);
      }else{
         require(canSpend(msg.sender, _from, _value));
         uint fromRecurrent;
         if(recurrentAllowed[_from][msg.sender].remains >= _value) //take as much as possible from recurrent first
            fromRecurrent = _value;
         else
            fromRecurrent = recurrentAllowed[_from][msg.sender].remains;
         recurrentAllowed[_from][msg.sender].remains = recurrentAllowed[_from][msg.sender].remains.sub(fromRecurrent);
         allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value - fromRecurrent); //take the rest from ordinary allowance
      }   
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      if(msg.sender != address(managementContract)){
         ExternalTransfer(_from, _to, msg.sender, _value);
      }
      Transfer(_from, _to, _value);
      return true;   
   }

   function transfer(address to, uint256 value) public returns (bool){
      if(super.transfer(to, value)){
         ExternalTransfer(msg.sender, to, msg.sender, value);
         return true;
      }
      throw;
   }

   /*
    * Opt-out from the MediaManager services. The opt-out is permanent. In order to use hybrid solution, transer some funds to a new account.
    */
   function disableManager()public {
      disabledManager[msg.sender] = true;
   }

   /*
    * Check if the given user is managed by the management contract.
    * @param user User to check
    */
   function managerAllowed(address user) public view returns (bool) {
      return !disabledManager[user]; 
   }


}


