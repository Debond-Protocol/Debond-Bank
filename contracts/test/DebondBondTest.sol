pragma solidity ^0.8.0;

import "debond-erc3475/contracts/DebondBond.sol";


contract DebondBondTest is DebondBond {

    constructor(address governanceAddress, address DBIT, address USDC, address USDT, address DAI) DebondBond(governanceAddress) {
        _createClass(0, "D/BIT", IDebondBond.InterestRateType.FixedRate, DBIT, 0);
        _createClass(1, "USDC", IDebondBond.InterestRateType.FixedRate, USDC, 0);
        _createClass(2, "USDT", IDebondBond.InterestRateType.FixedRate, USDT, 0);
        _createClass(3, "DAI", IDebondBond.InterestRateType.FixedRate, DAI, 0);

        _createClass(4, "D/BIT", IDebondBond.InterestRateType.FloatingRate, DBIT, 0);
        _createClass(5, "USDC", IDebondBond.InterestRateType.FloatingRate, USDC, 0);
        _createClass(6, "USDT", IDebondBond.InterestRateType.FloatingRate, USDT, 0);
        _createClass(7, "DAI", IDebondBond.InterestRateType.FloatingRate, DAI, 0);
    }
}
