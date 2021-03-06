pragma solidity =0.5.16;
import "../modules/SafeMath.sol";
import "./CollateralCal.sol";
import "../modules/tuple64.sol";
/**
 * @title Options manager contract for finnexus proposal v2.
 * @dev A Smart-contract to manage Options pool, collatral pool, mine pool, FPTCoin, etc.
 *
 */
contract OptionsManagerV1 is CollateralCal {
    using SafeMath for uint256;

    /**
    * @dev Options manager constructor. set other contract address
    * @param oracleAddr fnx oracle contract address.
    * @param optionsPriceAddr options price contract address
    * @param optionsPoolAddr optoins pool contract address
    * @param FPTCoinAddr FPTCoin contract address
    */
    constructor (address collateraladdr,address oracleAddr,address optionsPriceAddr,address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr) public{
        collateral = collateraladdr;
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);
    }
    function initialize() onlyOwner public {
        
    }
    function update() onlyOwner public {
        
    }
    /**
    * @dev retrieve input price valid range rate, thousandths.
    */ 
    function getPriceRateRange() public view returns(uint256,uint256) {
        return (minPriceRate,maxPriceRate);
    }
    /**
    * @dev set input price valid range rate, thousandths.
    */ 
    function setPriceRateRange(uint256 _minPriceRate,uint256 _maxPriceRate) public onlyOwner{
        minPriceRate = _minPriceRate;
        maxPriceRate = _maxPriceRate;
    }
    /**
    * @dev check user input price is in valid range.
    * @param strikePrice user input strikePrice
    * @param underlyingPrice current underlying price.
    */ 
    function checkStrikePrice(uint256 strikePrice,uint256 underlyingPrice)internal view{
        require(underlyingPrice*maxPriceRate/1000>=strikePrice && underlyingPrice*minPriceRate/1000<=strikePrice,
                "strikePrice is out of price range");
    }
    /**
    * @dev user buy option and create new option.
    * @param settlementAmount amount of settlement user want fo pay.
    * @param strikePrice user input option's strike price
    * @param underlying user input option's underlying id, 1 for BTC,2 for ETH
    * @param expiration user input expiration,time limit from now
    * @param amount user input amount of new option user want to buy.
    * @param optType user input option type
    */ 
    function buyOption(uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
                uint32 expiration,uint256 amount,uint8 optType) nonReentrant notHalted InRange(amount) public payable{
        //_optionsPool.buyOptionCheck(expiration,underlying);
        //emit DebugEvent(222,gasleft());
        uint256 type_ly_expiration = optType+(uint256(underlying)<<64)+(uint256(expiration)<<128);
        uint256 underlyingPrice = oracleUnderlyingPrice(underlying);
        checkStrikePrice(strikePrice,underlyingPrice);
        uint256 optRate = _getOptionsPriceRate(underlyingPrice,strikePrice,amount,optType);
        uint256 settlePrice = (oraclePrice(collateral)>>32)/optRate;
        uint256 optPrice = _optionsPool.createOptions(msg.sender,type_ly_expiration,uint128(strikePrice),uint128(underlyingPrice),uint128(amount),uint128(settlePrice));
        optPrice = (optPrice*optRate)>>32;
        buyOption_sub(settlementAmount,optPrice,strikePrice,amount);
    }
    /**
    * @dev subfunction of buy option.
    * @param settlementAmount amount of settlement user want fo pay.
    * @param optionPrice new option's price
    * @param amount user input amount of new option user want to buy.
    */ 
    function buyOption_sub(uint256 settlementAmount,
            uint256 optionPrice,uint256 settlePrice,uint256 amount)internal{
        settlementAmount = getPayableAmount(settlementAmount);
        uint256 allPay = amount*optionPrice;
        uint256 allPayUSd = allPay/1e8;
        allPay = allPay/settlePrice;
        _collateralPool.buyOptionsPayfor(msg.sender,settlementAmount,allPay);
        //uint256 id =_optionsPool.getOptionInfoLength();
        _FPTCoin.addMinerBalance(msg.sender,allPayUSd);
        emit BuyOption(msg.sender,optionPrice,allPay,amount); 
    }
    /**
    * @dev User sell option.
    * @param optionsId option's ID which was wanted to sell, must owned by user
    * @param amount user input amount of option user want to sell.
    */ 
    function sellOption(uint256 optionsId,uint256 amount) nonReentrant notHalted InRange(amount) public{
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        expiration = expiration.sub(now);
        uint256 currentPrice = oracleUnderlyingPrice(underlying);
        uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        uint256 allPay = optPrice*amount;
        uint256 fullPay = _optionsPool.getBurnedFullPay(optionsId,amount);
        _collateralPool.addNetWorthBalance(int256(fullPay));
        _collateralPool.transferPaybackAndFee(msg.sender,allPay,1);
        emit SellOption(msg.sender,optionsId,amount,allPay);
    }
    /**
    * @dev User exercise option.
    * @param optionsId option's ID which was wanted to exercise, must owned by user
    * @param amount user input amount of option user want to exercise.
    */ 
    function exerciseOption(uint256 optionsId,uint256 amount) nonReentrant notHalted InRange(amount) public{
        uint256 allPay = _optionsPool.getExerciseWorth(optionsId,amount);
        require(allPay > 0,"This option cannot exercise");
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        expiration = expiration.sub(now);
        uint256 currentPrice = oracleUnderlyingPrice(underlying);
        uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        uint256 fullPay = _optionsPool.getBurnedFullPay(optionsId,amount);
        _collateralPool.addNetWorthBalance(int256(fullPay));
        _collateralPool.transferPaybackAndFee(msg.sender,allPay,2);
        emit ExerciseOption(msg.sender,optionsId,amount,allPay);
    }
    function getOptionsPrice(uint256 underlyingPrice, uint256 strikePrice, uint256 expiration,
                    uint32 underlying,uint256 amount,uint8 optType) public view returns(uint256){  
        uint256 optRate = _getOptionsPriceRate(underlyingPrice,strikePrice,amount,optType);
        uint256 optPrice = _optionsPrice.getOptionsPrice(underlyingPrice,strikePrice,expiration,underlying,optType);
        return (optPrice*optRate)>>32;
    }
    function _getOptionsPriceRate(uint256 underlyingPrice, uint256 strikePrice,uint256 amount,uint8 optType) internal view returns(uint256){
        uint256 totalCollateral = getTotalCollateral();
        uint256 lockedWorth = _FPTCoin.getTotalLockedWorth();
        require(totalCollateral>=lockedWorth,"collateral is insufficient!");
        totalCollateral = totalCollateral - lockedWorth;
        uint256 buyOccupied = ((optType == 0) == (strikePrice>underlyingPrice)) ? strikePrice*amount:underlyingPrice*amount;
        (uint256 callCollateral,uint256 putCollateral) = _optionsPool.getAllOccupiedCollateral();
        uint256 totalOccupied = (callCollateral + putCollateral + buyOccupied)*collateralRate/1000;
        buyOccupied = ((optType == 0 ? callCollateral : putCollateral) + buyOccupied)*collateralRate/1000;
        require(totalCollateral>=totalOccupied,"collateral is insufficient!");
        return calOptionsPriceRatio(buyOccupied,totalOccupied,totalCollateral);
    }
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) internal pure returns (uint256){
        //r1 + 0.5
        if (selfOccupied*2<=totalOccupied){
            return 4294967296;
        }
        uint256 r1 = (selfOccupied<<32)/totalOccupied+2147483648;
        uint256 r2 = totalOccupied/totalCollateral;
        //r1*r2*1.5
        r1 = (r1*r2*3/2)>>32;
        return ((r1*r1*r1)>>64)+4294967296;
    //        return SmallNumbers.pow(r1,r2);
    }
}
