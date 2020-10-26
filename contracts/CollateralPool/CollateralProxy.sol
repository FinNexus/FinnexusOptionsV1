pragma solidity =0.5.16;
import "./CollateralData.sol";
import "../Proxy/baseProxy.sol";
/**
 * @title  Erc20Delegator Contract

 */
contract CollateralProxy is CollateralData,baseProxy{
        /**
     * @dev constructor function , setting contract address.
     *  oracleAddr FNX oracle contract address
     *  optionsPriceAddr options price contract address
     *  ivAddress implied volatility contract address
     */  

    constructor(address implementation_,address collateraladdr,address optionsPool)
        baseProxy(implementation_) public  {
        collateral = collateraladdr;
        _optionsPool = IOptionsPool(optionsPool);
    }
        /**
     * @dev Transfer colleteral from manager contract to this contract.
     *  Only manager contract can invoke this function.
     */
    function () external payable onlyManager{

    }
    function getFeeRate(uint256 /*feeType*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev set the rate of trasaction fee.
     *  feeType the transaction fee type
     *  numerator the numerator of transaction fee .
     *  denominator thedenominator of transaction fee.
     * transaction fee = numerator/denominator;
     */   
    function setTransactionFee(uint256 /*feeType*/,uint32 /*thousandth*/)public{
        delegateAndReturn();
    }

    function getFeeBalance()public view returns(uint256){
        delegateToViewAndReturn();
    }
    function redeem(address /*currency*/)public{
        delegateAndReturn();
    }
    function redeemAll()public{
        delegateAndReturn();
    }
        /**
     * @dev An interface for add transaction fee.
     *  Only manager contract can invoke this function.
     *  collateral collateral address, also is the coin for fee.
     *  amount total transaction amount.
     *  feeType transaction fee type. see TransactionFee contract
     */
    function addTransactionFee(uint256 /*amount*/,uint256 /*feeType*/)public returns (uint256) {
        delegateAndReturn();
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     *  user input retrieved account 
     */
    function getUserPayingUsd(address /*user*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     *  user input retrieved account 
     *  collateral input retrieved collateral coin address 
     */
    function getUserInputCollateral(address /*user*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve collateral balance data.
     *  collateral input retrieved collateral coin address 
     */
    function getCollateralBalance()public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Opterator user paying data, priced in USD. Only manager contract can modify database.
     *  user input user account which need add paying amount.
     *  amount the input paying amount.
     */
    function addUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator user input collateral data. Only manager contract can modify database.
     *  user input user account which need add input collateral.
     *  collateral the collateral address.
     *  amount the input collateral amount.
     */
    function addUserInputCollateral(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     *  collateral available colleteral address.
     *  amount collateral net worth increase amount.
     */
    function addNetWorthBalance(int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator collateral balance data. Only manager contract can modify database.
     *  collateral available colleteral address.
     *  amount collateral colleteral increase amount.
     */
    function addCollateralBalance(uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract user paying data,priced in USD. Only manager contract can modify database.
     *  user user's account.
     *  amount user's decrease amount.
     */
    function subUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract user's collateral balance. Only manager contract can modify database.
     *  user user's account.
     *  collateral collateral address.
     *  amount user's decrease amount.
     */
    function subUserInputCollateral(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract net worth balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the decrease amount.
     */
    function subNetWorthBalance(int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract collateral balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the decrease amount.
     */
    function subCollateralBalance(uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set user paying data,priced in USD. Only manager contract can modify database.
     *  user user's account.
     *  amount user's new amount.
     */
    function setUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set user's collateral balance. Only manager contract can modify database.
     *  user user's account.
     *  collateral collateral address.
     *  amount user's new amount.
     */
    function setUserInputCollateral(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set net worth balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the new amount.
     */
    function setNetWorthBalance(int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set collateral balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the new amount.
     */
    function setCollateralBalance(uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee. Only manager contract can invoke this function.
     *  recieptor the recieptor account.
     *  settlement the settlement coin address.
     *  payback the payback amount
     *  feeType the transaction fee type. see transactionFee contract
     */
    function transferPaybackAndFee(address payable /*recieptor*/,uint256 /*payback*/,
            uint256 /*feeType*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     *  recieptor the recieptor account.
     *  settlement the settlement coin address.
     *  payback the payback amount
     */
    function buyOptionsPayfor(address payable /*recieptor*/,uint256 /*settlementAmount*/,uint256 /*allPay*/)public{
        delegateAndReturn();
    }

    function getRealBalance()public view returns(int256){
        delegateToViewAndReturn();
    }
    function getNetWorthBalance()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev  The foundation operator want to add some coin to netbalance, which can increase the FPTCoin net worth.
     *  settlement the settlement coin address which the foundation operator want to transfer in this contract address.
     *  amount the amount of the settlement coin which the foundation operator want to transfer in this contract address.
     */
    function addNetBalance(address /*settlement*/,uint256 /*amount*/) public payable{
        delegateAndReturn();
    }
    /**
     * @dev Calculate the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     */
    function calSharedPayment() public{
        delegateAndReturn();
    }
    /**
     * @dev Set the calculation results of the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     *  newNetworth Current expired options' net worth 
     *  sharedBalances All unexpired options' shared balance distributed by time.
     *  firstOption The new first unexpired option's index.
     */
    function setSharedPayment(address[] memory /*_whiteList*/,int256[] memory /*newNetworth*/,
            int256[] memory /*sharedBalances*/,uint256 /*firstOption*/) public{
        delegateAndReturn();
    }

}
