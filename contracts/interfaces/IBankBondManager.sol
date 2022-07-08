pragma solidity ^0.8.0;

import "erc3475/IERC3475.sol";

interface IBankBondManager {
    enum InterestRateType {FixedRate, FloatingRate}

    function setBankData(address _bankData) external;
    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external;
    function setBenchmarkInterest(uint _benchmarkInterest) external;
    function createClassMetadatas(uint256[] memory metadataIds, IERC3475.Metadata[] memory metadatas) external;
    function createClass(uint256 classId, string memory symbol, address tokenAddress, InterestRateType interestRateType, uint256 period) external;

    function issueBonds(address to, uint256[] memory classIds, uint256[] memory amounts) external;



    function getProgress(uint256 classId, uint256 nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining);
    function getETA(uint256 classId, uint256 nonceId) external view returns (uint256);
    function classValues(uint256 classId) public view returns (address _tokenAddress, InterestRateType _interestRateType, uint256 _periodTimestamp);
    function getClasses() external view returns (uint[] memory);
}



