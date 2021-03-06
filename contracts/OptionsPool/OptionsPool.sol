pragma solidity =0.5.16;
import "./OptionsNetWorthCal.sol";
/**
 * @title Options pool contract.
 * @dev store options' information and nessesary options' calculation.
 *
 */
contract OptionsPool is OptionsNetWorthCal {
    /**
     * @dev constructor function , setting contract address.
     * @param oracleAddr FNX oracle contract address
     * @param optionsPriceAddr options price contract address
     * @param ivAddress implied volatility contract address
     */  
    constructor (address collateraladdr,address oracleAddr,address optionsPriceAddr,address ivAddress)public{
        collateral = collateraladdr;
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _volatility = IVolatility(ivAddress);
    }
    function update() onlyOwner public {

    }
    /**
     * @dev retrieve all information for collateral occupied and net worth calculation.
     */ 
    function getOptionCalRangeAll()public view returns(uint256,int256,int256,uint256,int256,uint256,uint256){
        (uint256 occupiedFirst,int256 callOccupiedlatest,int256 putOccupiedlatest) = getOccupiedCalInfo();
        (uint256 netFirst,int256 netLatest) = getNetWrothCalInfo();
        return (occupiedFirst,callOccupiedlatest,putOccupiedlatest,netFirst,netLatest,allOptions.length,block.number);
    }
    /**
     * @dev create new option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param type_ly_expiration tuple64 for option type,underlying,expiration.
     * @param strikePrice user's input new option's strike price.
     * @param underlyingPrice current new option's price, calculated by options price contract.
     * @param amount user's input new option's amount.
     */ 
    function createOptions(address from,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) onlyManager public returns(uint256){
        uint256 price = _createOptions(from,type_ly_expiration,strikePrice,underlyingPrice,amount,settlePrice);
        _addOptionsCollateral(allOptions.length);
        return price;
//        _addNewOptionsNetworth(info);
    }
    /**
     * @dev burn option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param id user's input option's id.
     * @param amount user's input burned option's amount.
     * @param optionPrice current new option's price, calculated by options price contract.
     */ 
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)public onlyManager Smaller(amount) OutLimitation(id){
        OptionsInfo memory info = _getOptionsById(id);
        _burnOptions(from,id,info,amount);
        uint256 currentPrice = oracleUnderlyingPrice(info.underlying);
        _burnOptionsCollateral(info,amount,currentPrice);
        _burnOptionsNetworth(info,amount,currentPrice,optionPrice);
    }
}