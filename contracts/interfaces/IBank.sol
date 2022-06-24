pragma solidity ^0.8.0;


enum PurchaseMethod {Buying, Staking}



interface IBank {

/// @notice creation of some initial bond classes, nonces and their corresponding metadata 
/// @dev this will be only callable by the deployer, and needs to be set based on the initial parameters.
/// @param daiAddress address of the stablecoin ERC20 that are  paired with bonds.

function initializeApp(address daiAddress, address usdtAddress) external; 

/// @notice allows user to buy / stake bonds with given (class , nonce , interestRate )type .
/// @dev insure that iniitalizeApp function is executed in order to initialize the classPairs that are elligible to be purchased 
/// @param _purchaseClassId is the classId of the ERC20 bond(approved by bank) that will be deposited by user..
/// @param _debondClassId is the classId of the corresponding asset bond managed by the debond (DBIT/DGOV) token.
/// @param _purchaseTokenAmount is the amount of tokens that are to be purchased from the  
/// @param _minRate is the min amount  that user has to receive in the swap in the APM in order the function succeed.
/// @param  purchaseMethod is the enum choice defining the type of bonds to be issued (0 for Buying and 1 for Staking).
function buyBond(uint _purchaseClassId, uint _debondClassId, uint _purchaseTokenAmount, uint _minRate, PurchaseMethod purchaseMethod) external;



/// @notice another function allowing  users to stake with  DBIT tokens and then receive the Bonds of DBIT and other ERC20 (defined by purchaseClassId).
/// @dev similar to uniswap interface.
///  @param _purchaseClassId is the classId of the ERC20 bond(approved by bank) that will be deposited by user. 
/// @param _DbitClassId is the classId of the DBIT bond.
/// @param _purchaseTokenAmount is the amount of tokens that are to be purchased from the  
/// @param _minRate is the min amount  that user has to receive in the swap in the APM in order the function succeed.
/// @param  deadline is the time  elapsed (in seconds) to wait during  order to be swapped successfully, else the order is void and amount is returned.
/// @param _to is the destination address of  delegator receiving the bonds.
function stakeForDbitBondWithElse(uint _purchaseClassId, uint _DbitClassId, uint _purchaseTokenAmount, uint _minRate, uint deadline, address _to  ) external;
    


/// @notice staking method for an address allowing DGOV tokens to be staked for getting DGOV and DBIT bonds.
/// @dev similar to uniswap swap-for-to..
///  @param _purchaseClassId is the classId of the DBIT bond(approved by bank) that will be deposited by user.
/// @param _debondClassId is the classId of the DGOV bond (that will be bought by the user)
/// @param _purchaseTokenAmount is the amount of DBIT tokens  that are to be purchased to get the necessary DBIT bond.  
/// @param _minRate is the min amount  that user has to receive in the swap in the APM in order the function succeed.
/// @param  deadline is the time  elapsed (in seconds) to wait during  order to be swapped successfully, else the order is void and amount is returned.


function stakeForDgovBondWithDbit(
 uint _purchaseClassId, //should it be hardcode? or it can change in debond data?
 uint _debondClassId, 
 uint _purchaseTokenAmount,
 uint _minRate,
 uint deadline,
 address _to 
 ) external;




function stakeForDgovBondWithElse(
 uint _purchaseClassId,
 uint _debondClassId, 
 uint _purchaseTokenAmount,
 uint _minRate,
 uint deadline,  
 address _to
 ) external;



function buyforDbitBondWithElse( //else is not eth not dbit   
uint _purchaseClassId,
uint _debondClassId, 
uint _purchaseTokenAmount,
uint _minRate,
uint deadline,  
address _to
) external;



function buyForDgovBondWithDbit(
 uint _purchaseClassId,
 uint _debondClassId, 
 uint _purchaseTokenAmount,
 uint _minRate,
 uint deadline,  
 address _to
 ) external;



function buyForDgovBondWithElse(
 uint _purchaseClassId,
 uint _debondClassId, 
 uint _purchaseTokenAmount,
 uint _minRate, 
 uint deadline,  
 address _to
 ) external




function stakeForDbitBondWithEth(
     //uint _purchaseClassId, // token added  //here it's eth
uint _debondClassId, // token to mint
     //uint _purchaseTokenAmount,
uint _minRate, 
uint deadline, 
address _to 
) external payable;


function stakeForDgovBondWithEth(
uint _debondClassId, // token to mint
PurchaseMethod _purchaseMethod,
uint _minRate, 
uint deadline,
address _to  
) external payable;


function buyforDbitBondWithEth( //else is not eth not dbit   
 uint _purchaseClassId,
 uint _debondClassId, 
 uint _purchaseETHAmount,
 uint _minRate, 
 uint deadline,  
 address _to 
 ) external payable




function buyforDgovBondWithEth( //else is not eth not dbit   
 uint _purchaseClassId,
 uint _debondClassId, 
 uint _purchaseETHAmount,
 uint _minRate, 
 uint deadline,  
 address _to 
 ) external payable


function redeemBonds(uint classId, uint nonceId, uint amount) external;

function interestRate(uint _purchaseTokenClassId, uint _debondTokenClassId, uint _purchaseTokenAmount, PurchaseMethod purchaseMethod) external view returns (uint, uint);


}