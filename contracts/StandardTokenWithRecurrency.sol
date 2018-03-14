pragma solidity ^0.4.18;

import '../node_modules/zeppelin-solidity/contracts/token/StandardToken.sol';


contract StandardTokenWithRecurrency is StandardToken {

    event ApprovalRecurrent(address indexed tokenOwner, address indexed spender, uint tokens, uint32 interval);

    /*
     * Allow recurrent payments by spender on sender's account, in max. amount of token per interval.
     * @param spender who is being authorized
     * @param tokens maximum allowed per interval
     * @param interval Interval length in blocks
     * @return bool on success
     */
    function approveRecurrent(address spender, uint tokens, uint32 interval) public returns (bool success);

    /*
     * Check the recurrent spending approval for a given holder and spender.
     * @param tokenOwner Holder of the tokens
     * @param spender Spender
     * @returns remaining Tokens available to spend in this interval
     * @returns totalLimit Tokens available to spend each interval
     * @returns interval Interval length in blocks
     * @returns intervalStart Blocks when the current interval starts
     */
    function allowanceRecurrent(address tokenOwner, address spender) public constant returns (uint remaining, uint totalLimit, uint32 interval, uint intervalStart);

}
