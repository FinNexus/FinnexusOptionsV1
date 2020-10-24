pragma solidity =0.5.16;
import "../modules/SafeMath.sol";
import "../modules/SafeInt256.sol";
import "./ManagerData.sol";
/**
 * @title collateral calculate module
 * @dev A smart-contract which has operations of collateral and methods of calculate collateral occupation.
 *
 */
contract CollateralCal is ManagerData {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    /**
     * @dev Retrieve user's current total worth, priced in USD.
     * @param account input retrieve account
     */
    function getUserTotalWorth(address account)public view returns (uint256){
        return getTokenNetworth().mul(_FPTCoin.balanceOf(account)).add(_FPTCoin.lockedWorthOf(account));
    }
    /**
     * @dev Retrieve FPTCoin's net worth, priced in USD.
     */
    function getTokenNetworth() public view returns (uint256){
        uint256 _totalSupply = _FPTCoin.totalSupply();
        if (_totalSupply == 0){
            return 1e8;
        }
        uint256 netWorth = getUnlockedCollateral()/_totalSupply;
        return netWorth>100 ? netWorth : 100;
    }
    /**
     * @dev Deposit collateral in this pool from user.
     * @param amount the amount of collateral to deposit.
     */
    function addCollateral(uint256 amount) nonReentrant notHalted  public payable {
        amount = getPayableAmount(amount);
        uint256 fee = _collateralPool.addTransactionFee(amount,3);
        amount = amount-fee;
        uint256 price = oraclePrice(collateral);
        uint256 userPaying = price*amount;
        require(checkAllowance(msg.sender,(_collateralPool.getUserPayingUsd(msg.sender)+userPaying)/1e8),
            "Allowances : user's allowance is unsufficient!");
        uint256 mintAmount = userPaying/getTokenNetworth();
        _collateralPool.addCollateralBalance(amount);
        _collateralPool.addUserInputCollateral(msg.sender,amount);
         _collateralPool.addNetWorthBalance(int256(amount));
        emit AddCollateral(msg.sender,amount,mintAmount);
        _FPTCoin.mint(msg.sender,mintAmount);
    }
    /**
     * @dev redeem collateral from this pool, user can input the prioritized collateral,he will get this coin,
     * if this coin is unsufficient, he will get others collateral which in whitelist.
     * @param tokenAmount the amount of FPTCoin want to redeem.
     */
    function redeemCollateral(uint256 tokenAmount,address collateral) nonReentrant notHalted InRange(tokenAmount) public {
        require(checkAddressPermission(collateral,allowRedeemCollateral) , "settlement is unsupported token");
        uint256 lockedAmount = _FPTCoin.lockedBalanceOf(msg.sender);
        require(_FPTCoin.balanceOf(msg.sender)+lockedAmount>=tokenAmount,"SCoin balance is insufficient!");
        uint256 leftCollateral = getLeftCollateral();
        (uint256 burnAmount,uint256 redeemWorth) = _FPTCoin.redeemLockedCollateral(msg.sender,tokenAmount,leftCollateral);
//        tokenAmount -= burnAmount;
        if (tokenAmount > burnAmount){
            leftCollateral -= redeemWorth;
            
            if (lockedAmount > 0){
                tokenAmount = tokenAmount > lockedAmount ? tokenAmount - lockedAmount : 0;
            }
            (uint256 newRedeem,uint256 newWorth) = _redeemCollateral(tokenAmount,leftCollateral);
            if(newRedeem>0){
                burnAmount = newRedeem;
                redeemWorth += newWorth;
            }
        }else{
            burnAmount = 0;
        }
        _redeemCollateralWorth(redeemWorth);
        if (burnAmount>0){
            _FPTCoin.burn(msg.sender, burnAmount);
        }
    }
    /**
     * @dev The subfunction of redeem collateral.
     * @param leftAmount the left amount of FPTCoin want to redeem.
     * @param leftCollateral The left collateral which can be redeemed, priced in USD.
     */
    function _redeemCollateral(uint256 leftAmount,uint256 leftCollateral)internal returns (uint256,uint256){
        uint256 tokenNetWorth = getTokenNetworth();
        uint256 leftWorth = leftAmount*tokenNetWorth;        
        if (leftWorth > leftCollateral){
            uint256 newRedeem = leftCollateral/tokenNetWorth;
            uint256 newWorth = newRedeem*tokenNetWorth;
            uint256 locked = leftAmount - newRedeem;
            _FPTCoin.addlockBalance(msg.sender,locked,locked*tokenNetWorth);
            return (newRedeem,newWorth);
        }
        return (leftAmount,leftWorth);
    }

    /**
     * @dev The subfunction of redeem collateral. Calculate all redeem count and tranfer.
     * @param redeemWorth user redeem worth, priced in USD.
     */
    function _redeemCollateralWorth(uint256 redeemWorth) internal {
        if (redeemWorth == 0){
            return;
        }
        emit RedeemCollateral(msg.sender,redeemWorth);
        uint256 price =oraclePrice(collateral);
        _collateralPool.transferPaybackAndFee(msg.sender,redeemWorth/price,4);
    }

    /**
     * @dev Retrieve the occupied collateral worth, multiplied by minimum collateral rate, priced in USD. 
     */
    function getOccupiedCollateral() public view returns(uint256){
        uint256 totalOccupied = _optionsPool.getTotalOccupiedCollateral();
        return calculateCollateral(totalOccupied);
    }
    /**
     * @dev Retrieve the available collateral worth, the worth of collateral which can used for buy options, priced in USD. 
     */
    function getAvailableCollateral()public view returns(uint256){
        return safeSubCollateral(getUnlockedCollateral(),getOccupiedCollateral());
    }
    /**
     * @dev Retrieve the left collateral worth, the worth of collateral which can used for redeem collateral, priced in USD. 
     */
    function getLeftCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),getOccupiedCollateral());
    }
    /**
     * @dev Retrieve the unlocked collateral worth, the worth of collateral which currently used for options, priced in USD. 
     */
    function getUnlockedCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),_FPTCoin.getTotalLockedWorth());
    }
    /**
     * @dev The auxiliary function for collateral worth subtraction. 
     */
    function safeSubCollateral(uint256 allCollateral,uint256 subCollateral)internal pure returns(uint256){
        return allCollateral > subCollateral ? allCollateral - subCollateral : 0;
    }
    /**
     * @dev The auxiliary function for calculate option occupied. 
     * @param strikePrice option's strike price
     * @param underlyingPrice option's underlying price
     * @param amount option's amount
     * @param optType option's type, 0 for call, 1 for put.
     */
    function calOptionsOccupied(uint256 strikePrice,uint256 underlyingPrice,uint256 amount,uint8 optType)public view returns(uint256){
        uint256 totalOccupied = 0;
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            totalOccupied = strikePrice*amount;
        } else {
            totalOccupied = underlyingPrice*amount;
        }
        return calculateCollateral(totalOccupied);
    }
    /**
     * @dev Retrieve the total collateral worth, priced in USD. 
     */
    function getTotalCollateral()public view returns(uint256){
        int256 netWorth = _collateralPool.getRealBalance();
        if (netWorth > 0){
            int256 price = int256(oraclePrice(collateral));
            return uint256(price.mul(netWorth));
        }else{
            return 0;
        }

    }
    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance()public view returns(int256){
        return _collateralPool.getRealBalance();
    }
    function getNetWorthBalance()public view returns(uint256){
        return _collateralPool.getNetWorthBalance();
    }
    /**
     * @dev the auxiliary function for getting user's transer
     */
    function getPayableAmount(uint256 settlementAmount) internal returns (uint256) {
        if (collateral == address(0)){
            settlementAmount = msg.value;
            address payable poolAddr = address(uint160(address(_collateralPool)));
            poolAddr.transfer(settlementAmount);
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(collateral);
            uint256 preBalance = oToken.balanceOf(address(this));
            oToken.transferFrom(msg.sender, address(this), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
            oToken.transfer(address(_collateralPool),settlementAmount);
        }
        require(isInputAmountInRange(settlementAmount),"input amount is out of input amount range");
        return settlementAmount;
    }

    /**
     * @dev the auxiliary function for collateral calculation
     */
    function calculateCollateral(uint256 amount)internal view returns (uint256){
        return collateralRate*amount/1000;
    }
}