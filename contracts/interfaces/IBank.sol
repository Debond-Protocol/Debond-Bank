pragma solidity ^0.8.0;


enum PurchaseMethod {Buying, Staking}



interface IBank {


/// @notice creation of some initial bond classes, nonces and their corresponding metadata 
/// @dev this will be only callable by the deployer, and needs to be set based on the initial parameters.
/// @param daiAddress address of the stablecoin ERC20 that are  paired with bonds.

function initializeApp(address daiAddress, address usdtAddress) external; 

/// @notice allows user to buy / stake bonds with given (class , nonce , interestRate )type to have tuple bonds.
/// @dev insure that iniitalizeApp function is executed in order to initialize the classPairs that are elligible to be purchased 
/// @param _purchaseClassId is the classId of the ERC20 
/// @return Documents the return variables of a contract’s function state variable
/// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)


function buyBond(uint _purchaseClassId, uint _debondClassId, uint _purchaseTokenAmount, uint _bondMinAmount, PurchaseMethod purchaseMethod,  uint24 fee) external;

function redeemBonds(uint classId, uint nonceId, uint amount) external;

function interestRate(uint _purchaseTokenClassId, uint _debondTokenClassId, uint _purchaseTokenAmount, PurchaseMethod purchaseMethod) external view returns (uint, uint);


}