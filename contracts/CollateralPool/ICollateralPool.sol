pragma solidity =0.5.16;
import "../modules/Ownable.sol";
interface ICollateralPool {
    function getUserPayingUsd(address user)external view returns (uint256);
    function getUserInputCollateral(address user,address collateral)external view returns (uint256);
    //function getNetWorthBalance(address collateral)external view returns (int256);
    function getCollateralBalance(address collateral)external view returns (uint256);

    //add
    function addUserPayingUsd(address user,uint256 amount)external;
    function addUserInputCollateral(address user,uint256 amount)external;
    function addNetWorthBalance(int256 amount)external;
    function addCollateralBalance(uint256 amount)external;
    //sub
    function subUserPayingUsd(address user,uint256 amount)external;
    function subUserInputCollateral(address user,uint256 amount)external;
    function subNetWorthBalance(int256 amount)external;
    function subCollateralBalance(uint256 amount)external;
        //set
    function setUserPayingUsd(address user,uint256 amount)external;
    function setUserInputCollateral(address user,uint256 amount)external;
    function setNetWorthBalance(int256 amount)external;
    function setCollateralBalance(uint256 amount)external;
    function transferPaybackAndFee(address recieptor,uint256 payback,uint256 feeType)external;

    function transferPayback(address recieptor,uint256 payback)external;
    function addTransactionFee(uint256 amount,uint256 feeType)external returns (uint256);

    function getRealBalance()external view returns(int256);
    function getNetWorthBalance()external view returns(uint256);
}
contract ImportCollateralPool is Ownable{
    ICollateralPool internal _collateralPool;
    function getCollateralPoolAddress() public view returns(address){
        return address(_collateralPool);
    }
    function setCollateralPoolAddress(address collateralPool)public onlyOwner{
        _collateralPool = ICollateralPool(collateralPool);
    }
}