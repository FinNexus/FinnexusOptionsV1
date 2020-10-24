pragma solidity =0.5.16;
import "../modules/Ownable.sol";
interface IOptionsPool {
//    function getOptionBalances(address user) external view returns(uint256[]);

    function createOptions(address from,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice)  external;
    function setSharedState(uint256 newFirstOption,int256 latestNetWorth) external;
    function getCallTotalOccupiedCollateral() external view returns (uint256);
    function getPutTotalOccupiedCollateral() external view returns (uint256);
    function getTotalOccupiedCollateral() external view returns (uint256);
    function buyOptionCheck(uint256 expiration,uint32 underlying)external view;
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end) external view returns(int256);
    function getOptionInfoLength()external view returns (uint256);
    function getNetWrothCalInfo()external view returns(uint256,int256);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end)external view returns(int256,uint256,uint256);
    function getNetWrothLatestWorth()external view returns(int256);
    function getBurnedFullPay(uint256 optionID,uint256 amount) external view returns(uint256);

}
contract ImportOptionsPool is Ownable{
    IOptionsPool internal _optionsPool;
    function getOptionsPoolAddress() public view returns(address){
        return address(_optionsPool);
    }
    function setOptionsPoolAddress(address optionsPool)public onlyOwner{
        _optionsPool = IOptionsPool(optionsPool);
    }
}