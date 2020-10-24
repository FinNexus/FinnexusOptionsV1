pragma solidity =0.5.16;
import "./OptionsOccupiedCal.sol";
/**
 * @title Options net worth calculation contract for finnexus proposal v2.
 * @dev A Smart-contract for net worth calculation.
 *
 */
contract OptionsNetWorthCal is OptionsOccupiedCal {
    /**
     * @dev retrieve all information for net worth calculation. 
     */ 
    function getNetWrothCalInfo()public view returns(uint256,int256){
        return ( netWorthFirstOption,optionsLatestNetWorth);
    }
    /**
     * @dev retrieve latest options net worth which paid in settlement coin. 
     */ 
    function getNetWrothLatestWorth()public view returns(int256){
        return optionsLatestNetWorth;
    }
    /**
     * @dev set latest options net worth balance, only manager contract can modify database.
     * @param newFirstOption new first valid option position.
     * @param latestNetWorth latest options net worth.
     */ 
    function setSharedState(uint256 newFirstOption,int256  latestNetWorth ) public onlyOperatorIndex(0){
        require(newFirstOption <= allOptions.length, "newFirstOption calculate Error");
        if (newFirstOption >  netWorthFirstOption){
             netWorthFirstOption = newFirstOption;
        }
        optionsLatestNetWorth  += latestNetWorth;
    }
    /**
     * @dev calculate options time shared value,from begin to end in the alloptionsList.
     * @param lastOption the last option position.
     * @param begin the begin options position.
     * @param end the end options position.
     */
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end)
            public view returns(int256,uint256,uint256){
        if (begin>=lastOption || end <  netWorthFirstOption){
            return(0,0,0);
        }
        if (end>lastOption) {
            end = lastOption;
        }
        (uint256 sharedBalance,uint256 _firstOption) = _calculateSharedPayment(begin,end);
        if (begin < _firstOption){
            int256 newNetworth = calculateExpiredPayment(begin,_firstOption);
            return (newNetworth,sharedBalance,_firstOption);
        }
        
        return (0,sharedBalance,_firstOption);
    }
    /**
     * @dev subfunction, calculate options time shared value,from begin to end in the alloptionsList.
     * @param begin the begin options position.
     * @param end the end options position.
     */
    function _calculateSharedPayment(uint256 begin,uint256 end)
            internal view returns(uint256,uint256){
        uint256 newFirstOption;
        uint256 totalSharedPayment = 0;
        (begin,newFirstOption) = getFirstOption(begin, netWorthFirstOption,end); 
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 timeValue = _calculateCurrentPrice(info.underlyingPrice,info.strikePrice,info.expiration,
                info.amount,info.optType);
            if (timeValue<info.optionsPrice){
                timeValue = info.optionsPrice - timeValue;
                timeValue = timeValue*info.amount/info.settlePrice;
                require(timeValue<=1e40,"option time shared value calculate error");
                totalSharedPayment += timeValue;
            }
        }
        return (totalSharedPayment,newFirstOption);
    }
    /**
     * @dev subfunction, calculate expired options shared value,from begin to end in the alloptionsList.
     * @param begin the begin options position.
     * @param end the end options position.
     */
    function calculateExpiredPayment(uint256 begin,uint256 end)internal view returns(int256){
        int256 totalExpiredPayment = 0;
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 amount = info.amount;
            if (amount>0){
                uint256 timeValue = info.optionsPrice*amount/info.settlePrice;
                require(timeValue<=1e40,"option time shared value calculate error");
                totalExpiredPayment += int256(timeValue);
            }
        }
        return totalExpiredPayment;
    }
    /**
     * @dev calculate options payback fall value,from begin to end in the alloptionsList.
     * @param lastOption the last option position.
     * @param begin the begin options position.
     * @param end the end options position.
     */
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end) public view returns(int256){
        if (begin>=lastOption || end <  netWorthFirstOption){
            return 0;
        }
        if (end>lastOption) {
            end = lastOption;
        }
        if (begin <=  netWorthFirstOption) {
            begin =  netWorthFirstOption;
        }
        uint256[] memory prices = getUnderlyingPrices();
        int256 OptionsFallBalance = _calRangeOptionsFall(begin,end,prices);
            OptionsFallBalance = OptionsFallBalance/(int256(oraclePrice(collateral)));
        return OptionsFallBalance;
    }
    /**
     * @dev subfunction, calculate options payback fall value,from begin to lastOption in the alloptionsList.
     * @param begin the begin option position.
     * @param lastOption the last option position.
     * @param prices eligible underlying price list.
     */
    function _calRangeOptionsFall(uint256 begin,uint256 lastOption,uint256[] memory prices)
                 internal view returns(int256 ){
        int256 OptionsFallBalance = 0;
        for (;begin<lastOption;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 amount = info.amount;
            if(info.expiration<now || amount == 0){
                continue;
            }
            uint256 index = _getEligibleUnderlyingIndex(info.underlying);
            int256 curValue = _calCurtimeCallateralFall(info,amount,prices[index]);
                OptionsFallBalance -= curValue;
        }
        return OptionsFallBalance;
    }
    /**
     * @dev subfunction, calculate option payback fall value.
     * @param info the option information.
     * @param amount the option amount to calculate.
     * @param curPrice current underlying price.
     */
    function _calCurtimeCallateralFall(OptionsInfo memory info,uint256 amount,uint256 curPrice) internal view returns(int256){
        if (info.expiration<=now || amount == 0){
            return 0;
        }
        uint256 newFall = _getOptionsPayback(info.optType,info.strikePrice,curPrice)*amount;
        uint256 OriginFall = _getOptionsPayback(info.optType,info.strikePrice,info.underlyingPrice)*amount;
        int256 curValue = int256(newFall) - int256(OriginFall);
        require(curValue>=-1e40 && curValue<=1e40,"options fall calculate error");
        return curValue;
    }
    /**
     * @dev set burn option net worth change.
     * @param info the option information.
     * @param amount the option amount to calculate.
     * @param underlyingPrice underlying price when option is created.
     * @param currentPrice current underlying price.
     */
    function _burnOptionsNetworth(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice,uint256 currentPrice) internal {
        int256 curValue = _calCurtimeCallateralFall(info,amount,underlyingPrice);
        uint256 timeWorth = info.optionsPrice>currentPrice ? info.optionsPrice-currentPrice : 0;
        timeWorth = timeWorth*amount/info.settlePrice;
        curValue = curValue / int256(oraclePrice(collateral));
        int256 value = curValue - int256(timeWorth);
        optionsLatestNetWorth += value;
    }
    /**
     * @dev An anxiliary function, calculate time shared current option price.
     * @param curprice underlying price when option is created.
     * @param strikePrice the option strikePrice.
     * @param expiration option time expiration time left, equal option.expiration - now.
     * @param ivNumerator Implied valotility numerator when option is created.
     */
    function _calculateCurrentPrice(uint256 curprice,uint256 strikePrice,uint256 expiration,uint256 ivNumerator,uint8 optType)internal view returns (uint256){
        if (expiration > now){
            return _optionsPrice.getOptionsPrice_iv(curprice,strikePrice,expiration-now,ivNumerator,
                optType);
        }
        return 0;
    }
}