pragma solidity >=0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2022 Debond Protocol <info@debond.org>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IBankStorage {
    /** updating the new bankAddress by governorExecutable to be referenced by this storage
    @param _bankAddress is the new bankAddress.
     */

    function updateBankAddress(address _bankAddress) external;

    /** updating the mapping of Bond Symbol and underlying collateral that can be bought/stake by the bond.
    this is used during the creation of the new bond class, also can be used as circuitBreaker in case of the 
    @param classIdIn is the id of the whitelisted bond(DBIT and DGOV by default).
    @param classIdOut is the id of underlying collateral token that is reserved.
    @param _canPurchase bool that sets the status of the canPurchase mapping.
     */

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external;

    /** updating the benchmark interest rate for all of the purchasable classes of bond 
    
    */
    function updateBenchmarkInterest(uint benchmarkInterest) external;

    /** updates the array storage for the collateral that is used as underlying denomination across different bond classes 
    its used only for the frotnend to track of the asset liquidity etc.

    */

    function pushClassIdPerTokenAddress(address tokenAddress, uint classId) external;

    /** 
    getter method to find the instantiation timestamp of the bond market.
    @notice this will always be one day before (i.e one nonce) before the actual listing of the first bond class. 
    
    */
    function getBaseTimestamp() external view returns (uint);

    /** Method to return bool (true meaning bondPair classîdIn-ClassIdOut that can be bought). */


    function canPurchase(uint classIdIn, uint classIdOut) external view returns (bool);

    /** returns all the classIds that have underlying token as collateral */

    function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint[] memory);

    /** getting current benchmark interest rate set by the governance */

    function getBenchmarkInterest() external view returns (uint);

}
