pragma solidity =0.5.16;

import "../modules/SafeMath.sol";
import "../ERC20/IERC20.sol";
import "./CollateralData.sol";
    /**
     * @dev Implementation of a transaction fee manager.
     */
contract TransactionFee is CollateralData {
    using SafeMath for uint256;
    constructor() internal{
        initialize();
    }
    function initialize() onlyOwner public{
        FeeRates.push(0);
        FeeRates.push(50);
        FeeRates.push(0);
        FeeRates.push(0);
        FeeRates.push(0);
    }
    function getFeeRate(uint256 feeType)public view returns (uint32){
        return FeeRates[feeType];
    }
    function setTransactionFee(uint256 feeType,uint32 thousandth)public onlyOwner{
        FeeRates[feeType] = thousandth;
    }

    function getFeeBalance()public view returns(uint256){
        return feeBalance;
    }

    function redeem()public onlyOwner{
        uint256 fee = feeBalance;
        require (fee > 0, "It's empty balance");
        feeBalance = 0;
        _transferPayback(msg.sender,fee);
    }
    function _addTransactionFee(uint256 amount) internal {
        if (amount > 0){
            feeBalance+=amount;
            emit AddFee(amount);
        }
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param payback amount of settlement will payback 
      */
    function _transferPaybackAndFee(address payable recieptor,uint256 payback,uint256 feeType)internal{
        if (payback == 0){
            return;
        }
        uint256 fee = FeeRates[feeType]*payback;
        _transferPayback(recieptor,payback-fee);
        _addTransactionFee(fee);
    }
    /**
      * @dev  transfer settlement payback amount;
      * @param recieptor payback recieptor
      * @param payback amount of settlement will payback 
      */
    function _transferPayback(address payable recieptor,uint256 payback)internal{
        if (payback == 0){
            return;
        }
        if (collateral == address(0)){
            recieptor.transfer(payback);
        }else{
            IERC20 collateralToken = IERC20(collateral);
            uint256 preBalance = collateralToken.balanceOf(address(this));
            collateralToken.transfer(recieptor,payback);
            uint256 afterBalance = collateralToken.balanceOf(address(this));
            require(preBalance - afterBalance == payback,"settlement token transfer error!");
        }
        emit TransferPayback(recieptor,payback);
    }
}