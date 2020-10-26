pragma solidity =0.5.16;

import "../modules/SafeInt256.sol";
import "./TransactionFee.sol";
/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralPool is TransactionFee{
    using SafeMath for uint256;
    using SafeInt256 for int256;
    constructor(address collateraladdr,address optionsPool)public{
        collateral = collateraladdr;
        _optionsPool = IOptionsPool(optionsPool);
    }
    /**
     * @dev Transfer colleteral from manager contract to this contract.
     *  Only manager contract can invoke this function.
     */
    function () external payable onlyManager{

    }

    function initialize() onlyOwner public {
        TransactionFee.initialize();
    }
    function update() onlyOwner public{
    }
    /**
     * @dev An interface for add transaction fee.
     *  Only manager contract can invoke this function.
     * @param amount total transaction amount.
     * @param feeType transaction fee type. see TransactionFee contract
     */
    function addTransactionFee(uint256 amount,uint256 feeType)public onlyManager returns (uint256) {
        uint256  fee = FeeRates[feeType]*amount;
        _addTransactionFee(fee);
        return fee;
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     * @param user input retrieved account 
     */
    function getUserPayingUsd(address user)public view returns (uint256){
        return userCollateralPaying[user];
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     * @param user input retrieved account 
     */
    function getUserInputCollateral(address user)public view returns (uint256){
        return userInputCollateral[user];
    }

    /**
     * @dev Retrieve collateral balance data.
     */
    function getCollateralBalance()public view returns (uint256){
        return collateralBalance;
    }
    /**
     * @dev Opterator user paying data, priced in USD. Only manager contract can modify database.
     * @param user input user account which need add paying amount.
     * @param amount the input paying amount.
     */
    function addUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].add(amount);
    }
    /**
     * @dev Opterator user input collateral data. Only manager contract can modify database.
     * @param user input user account which need add input collateral.
     * @param amount the input collateral amount.
     */
    function addUserInputCollateral(address user,uint256 amount)public onlyManager{
        userInputCollateral[user] = userInputCollateral[user].add(amount);
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     * @param newworth collateral net worth list.
     */
    function _addNetWorthBalance(int256 newworth)internal{
        netWorthBalance = netWorthBalance.add(newworth);
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     * @param newworth collateral net worth increase amount.
     */
    function addNetWorthBalance(int256 newworth)public onlyManager{
        netWorthBalance = netWorthBalance.add(newworth);
    }
    /**
     * @dev Opterator collateral balance data. Only manager contract can modify database.
     * @param amount collateral colleteral increase amount.
     */
    function addCollateralBalance(uint256 amount)public onlyManager{
        collateralBalance = collateralBalance.add(amount);
    }
    /**
     * @dev Substract user paying data,priced in USD. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's decrease amount.
     */
    function subUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = userCollateralPaying[user].sub(amount);
    }
    /**
     * @dev Substract user's collateral balance. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's decrease amount.
     */
    function subUserInputCollateral(address user,uint256 amount)public onlyManager{
        userInputCollateral[user] = userInputCollateral[user].sub(amount);
    }
    /**
     * @dev Substract net worth balance. Only manager contract can modify database.
     * @param amount the decrease amount.
     */
    function subNetWorthBalance(int256 amount)public onlyManager{
        netWorthBalance = netWorthBalance.sub(amount);
    }
    /**
     * @dev Substract collateral balance. Only manager contract can modify database.
     * @param amount the decrease amount.
     */
    function subCollateralBalance(uint256 amount)public onlyManager{
        collateralBalance = collateralBalance.sub(amount);
    }
    /**
     * @dev set user paying data,priced in USD. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's new amount.
     */
    function setUserPayingUsd(address user,uint256 amount)public onlyManager{
        userCollateralPaying[user] = amount;
    }
    /**
     * @dev set user's collateral balance. Only manager contract can modify database.
     * @param user user's account.
     * @param amount user's new amount.
     */
    function setUserInputCollateral(address user,uint256 amount)public onlyManager{
        userInputCollateral[user] = amount;
    }
    /**
     * @dev set net worth balance. Only manager contract can modify database.
     * @param amount the new amount.
     */
    function setNetWorthBalance(int256 amount)public onlyManager{
        netWorthBalance = amount;
    }
    /**
     * @dev set collateral balance. Only manager contract can modify database.
     * @param amount the new amount.
     */
    function setCollateralBalance(uint256 amount)public onlyManager{
        collateralBalance = amount;
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param payback the payback amount
     * @param feeType the transaction fee type. see transactionFee contract
     */
    function transferPaybackAndFee(address payable recieptor,uint256 payback,
            uint256 feeType)public onlyManager{
        _transferPaybackAndFee(recieptor,payback,feeType);
        netWorthBalance = netWorthBalance.sub(int256(payback));
    }
    /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     * @param recieptor the recieptor account.
     * @param allPay the payback amount
     */
    function buyOptionsPayfor(address payable recieptor,uint256 settlementAmount,uint256 allPay)public onlyManager{
        uint256 fee = addTransactionFee(allPay,0);
        require(settlementAmount>=allPay+fee,"settlement asset is insufficient!");
        settlementAmount = settlementAmount-(allPay+fee);
        if (settlementAmount > 0){
            _transferPayback(recieptor,settlementAmount);
        }
    }

    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance()public view returns(int256){
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth();
        return netWorthBalance.add(latestWorth);
    }
    function getNetWorthBalance()public view returns(uint256){
        int256 latestWorth = _optionsPool.getNetWrothLatestWorth();
        int256 netWorth = netWorthBalance.add(latestWorth);
        if (netWorth>0){
            return uint256(netWorth);
        }
        return 0;
    }
        /**
     * @dev  The foundation operator want to add some coin to netbalance, which can increase the FPTCoin net worth.
     * @param amount the amount of the settlement coin which the foundation operator want to transfer in this contract address.
     */
    function addNetBalance(uint256 amount) public payable {
        amount = getPayableAmount(amount);
        netWorthBalance = netWorthBalance.add(int256(amount));
    }
        /**
     * @dev the auxiliary function for getting user's transer
     */
    function getPayableAmount(uint256 amount) internal returns (uint256) {
        if (collateral == address(0)){
            amount = msg.value;
        }else if (amount > 0){
            IERC20 oToken = IERC20(collateral);
            uint256 preBalance = oToken.balanceOf(address(this));
            oToken.transferFrom(msg.sender, address(this), amount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==amount,"settlement token transfer error!");
        }
        return amount;
    }
        /**
     * @dev Calculate the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     */
    function calSharedPayment() public onlyOperatorIndex(0) {
        (uint256 firstOption,int256 latestShared) = _optionsPool.getNetWrothCalInfo();
        uint256 lastOption = _optionsPool.getOptionInfoLength();
        (int256 newNetworth,uint256 sharedBalance,uint256 newFirst) =
                     _optionsPool.calRangeSharedPayment(lastOption,firstOption,lastOption);
        int256 fallBalance = _optionsPool.calculatePhaseOptionsFall(lastOption,newFirst,lastOption);
        fallBalance = int256(sharedBalance).sub(latestShared).add(fallBalance);
        setSharedPayment(newNetworth,fallBalance,newFirst);
    }
    /**
     * @dev Set the calculation results of the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     * @param newNetworth Current expired options' net worth 
     * @param sharedBalance All unexpired options' shared balance distributed by time.
     * @param firstOption The new first unexpired option's index.
     */
    function setSharedPayment(int256 newNetworth,int256 sharedBalance,uint256 firstOption) public onlyOperatorIndex(0){
        _optionsPool.setSharedState(firstOption,sharedBalance);
        _addNetWorthBalance(newNetworth);
    }
}