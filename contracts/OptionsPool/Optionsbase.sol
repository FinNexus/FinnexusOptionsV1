pragma solidity =0.5.16;
import "./OptionsData.sol";
import "../modules/tuple64.sol";
/**
 * @title Options data contract.
 * @dev A Smart-contract to store options info.
 *
 */
contract OptionsBase is OptionsData {
    using whiteListUint32 for uint32[];
    constructor () public{
        initialize();
    }
    function initialize() onlyOwner public {
        expirationList =  [1 days,2 days,3 days, 7 days, 10 days, 15 days,20 days, 30 days/*,90 days*/];
        underlyingAssets = [1,2];
    }
    /**
     * @dev retrieve user's options' id. 
     * @param user user's account.
     */     
    function getUserOptionsID(address user)public view returns(uint64[] memory){
        return optionsBalances[user];
    }
    /**
     * @dev retrieve user's `size` number of options' id. 
     * @param user user's account.
     * @param from user's option list begin positon.
     * @param size retrieve size.
     */ 
    function getUserOptionsID(address user,uint256 from,uint256 size)public view returns(uint64[] memory){
        require(from <optionsBalances[user].length,"input from is overflow");
        require(size>0,"input size is zero");
        uint64[] memory userIdAry = new uint64[](size);
        if (from+size>optionsBalances[user].length){
            size = optionsBalances[user].length-from;
        }
        for (uint256 i= 0;i<size;i++){
            userIdAry[i] = optionsBalances[user][from+i];
        }
        return userIdAry;
    }
    /**
     * @dev retrieve all option list length. 
     */ 
    function getOptionInfoLength()public view returns (uint256){
        return allOptions.length;
    }
    /**
     * @dev retrieve `size` number of options' information. 
     * @param from all option list begin positon.
     * @param size retrieve size.
     */     
    function getOptionInfoList(uint256 from,uint256 size)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 allLen = allOptions.length;
        require(from <allLen,"input from is overflow");
        require(size>0,"input size is zero");
        if (from+size>allLen){
            size = allLen - from;
        }
        address[] memory ownerArr = new address[](size);
        uint256[] memory typeAndUnderArr = new uint256[](size);
        uint256[] memory expArr = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            uint256 index = from+i; 
            OptionsInfo storage info = allOptions[index];
            ownerArr[i] = info.owner;
            typeAndUnderArr[i] = (info.underlying << 16) + info.optType;
            expArr[i] = info.expiration;
            priceArr[i] = info.strikePrice;
            amountArr[i] = info.amount;
        }
        return (ownerArr,typeAndUnderArr,expArr,priceArr,amountArr);
    }
    /**
     * @dev retrieve given `ids` options' information. 
     * @param ids retrieved options' id.
     */   
    function getOptionInfoListFromID(uint256[] memory ids)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 size = ids.length;
        require(size > 0, "input ids array is empty");
        uint256 allLen = allOptions.length;
        address[] memory ownerArr = new address[](size);
        uint256[] memory typeAndUnderArr = new uint256[](size);
        uint256[] memory expArr = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            uint256 index = ids[i]-1; 
            require(index < allLen, "input ids array is empty");
            OptionsInfo storage info = allOptions[index];
            ownerArr[i] = info.owner;
            typeAndUnderArr[i] = (info.underlying << 16) + info.optType;
            expArr[i] = info.expiration;
            priceArr[i] = info.strikePrice;
            amountArr[i] = info.amount;
        }
        return (ownerArr,typeAndUnderArr,expArr,priceArr,amountArr);
    }
    /**
     * @dev retrieve given `optionsId` option's burned limit timestamp. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsLimitTimeById(uint256 optionsId)public view returns(uint256){
        require(optionsId>0 && optionsId <= allOptions.length,"option id is not exist");
        return getItemTimeLimitation(optionsId);
    }
    /**
     * @dev retrieve given `optionsId` option's information. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsById(uint256 optionsId)public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        return (optionsId,info.owner,info.optType,info.underlying,info.expiration,info.strikePrice,info.amount);
    }
    /**
     * @dev An auxiliary function, get underlying prices. 
     */
    function getUnderlyingPrices()internal view returns(uint256[] memory){
        uint256 underlyingLen = underlyingAssets.length;
        uint256[] memory prices = new uint256[](underlyingLen);
        for (uint256 i = 0;i<underlyingLen;i++){
            prices[i] = oracleUnderlyingPrice(underlyingAssets[i]);
        }
        return prices;
    }
    /**
     * @dev create new option, store option info.
     * @param from option's owner
     * @param type_ly_expiration the tuple64 of option type, underlying,expiration
     * @param strikePrice option's strike price and underlying price
     * @param underlyingPrice option's paid price and price rate
     * @param amount option's amount
     */
    function _createOptions(address from,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) internal returns(uint256){
        uint64 expiration = uint64(type_ly_expiration>>128);
        uint256 iv = _volatility.calculateIv(uint32(type_ly_expiration>>64),uint8(type_ly_expiration),expiration,
            underlyingPrice,strikePrice);
        uint256 optPrice = _optionsPrice.getOptionsPrice_iv(underlyingPrice,strikePrice,expiration,iv,uint8(type_ly_expiration));
        
        allOptions.push(OptionsInfo(from,
            uint8(type_ly_expiration),
            uint32(type_ly_expiration>>64),
            uint64(expiration+now),
            uint64(iv),
            amount,
            strikePrice,
            underlyingPrice,
            uint128(optPrice),
            settlePrice));
        uint64 optionID = uint64(allOptions.length);
        optionsBalances[from].push(optionID);
        setItemTimeLimitation(uint256(optionID));
        emit CreateOption(from,optionID,uint8(type_ly_expiration),uint32(type_ly_expiration>>64),expiration+now,
            strikePrice,amount);
        return optPrice;
    }
    /**
     * @dev burn an exist option whose id is `id`.
     * @param from option's owner
     * @param amount option's amount
     */
    function _burnOptions(address from,uint256 optionID,OptionsInfo memory info,uint256 amount)internal{
//        OptionsInfo storage info = _getOptionsById(id);
        require(info.expiration>now,"option is expired");
        require(info.owner == from,"caller is not the options owner");
        require(info.amount >= amount,"option amount is insufficient");
        allOptions[optionID-1].amount -= uint128(amount);
        emit BurnOption(from,optionID,amount);
    }
    /**
     * @dev calculate option's exercise worth.
     * @param optionsId option's id
     * @param amount option's amount
     */
    function getExerciseWorth(uint256 optionsId,uint256 amount)public view returns(uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        require(info.expiration>now,"option is expired");
        require(info.amount >= amount,"option amount is insufficient");
        uint256 underlyingPrice = oracleUnderlyingPrice(info.underlying);
        uint256 tokenPayback = _getOptionsPayback(info.optType,info.strikePrice,underlyingPrice);
        if (tokenPayback == 0 ){
            return 0;
        } 
        return tokenPayback*amount;
    }
    /**
     * @dev An auxiliary function, calculate option's exercise payback.
     * @param optType option's type
     * @param strikePrice option's strikePrice
     * @param underlyingPrice underlying's price
     */
    function _getOptionsPayback(uint8 optType,uint256 strikePrice,uint256 underlyingPrice)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return 0;
        } else {
            return (optType == 0) ? underlyingPrice - strikePrice : strikePrice - underlyingPrice;
        }
    }
    /**
     * @dev retrieve option by id, check option's id.
     * @param id option's id
     */
    function _getOptionsById(uint256 id)internal view returns(OptionsInfo storage){
        require(id>0 && id <= allOptions.length,"option id is not exist");
        return allOptions[id-1];
    }

    /**
     * @dev check option's underlying and expiration.
     * @param expiration option's expiration
     * @param underlying option's underlying
     */
    function buyOptionCheck(uint32 expiration,uint32 underlying)public view{
        require(underlyingAssets.isEligibleUint32(underlying) , "underlying is unsupported asset");
        require(expirationList.isEligibleUint32(expiration),"expiration value is not supported");
    }
    /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     * @param expiration new eligible expiration.
     */
    function addExpiration(uint32 expiration)public onlyOwner{
        expirationList.addWhiteListUint32(expiration);
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     * @param removeExpiration revoked expiration.
     */
    function removeExpirationList(uint32 removeExpiration)public onlyOwner returns(bool) {
        return expirationList.removeWhiteListUint32(removeExpiration);
    }
    /**
     * @dev Implementation of getting the eligible expirationList.
     */
    function getExpirationList()public view returns (uint32[] memory){
        return expirationList;
    }

    /**
     * @dev An auxiliary function, retrieve first available option's positon.
     * @param begin  the start of option's positon
     * @param latestBegin  the latest begin option positon.
     * @param end  the end of option's positon
     */
    function getFirstOption(uint256 begin,uint256 latestBegin,uint256 end) internal view returns(uint256,uint256){
        uint256 newFirstOption = latestBegin;
        if (begin > newFirstOption){
            //if in other phase, begin != new begin
            return (begin,newFirstOption);
        }
        begin = newFirstOption;
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            if(info.expiration<now || info.amount == 0){
                continue;
            }
            break;
        }
        //if in first phase, begin = new begin
        return (begin,begin);
    }
    /**
     * @dev calculate option's occupied collateral.
     * @param option  option's information
     * @param underlyingPrice  underlying current price.
     */
    function calOptionsCollateral(OptionsInfo memory option,uint256 underlyingPrice)internal view returns(uint256){
        uint256 amount = option.amount;
        if (option.expiration<=now || amount == 0){
            return 0;
        }
        uint256 totalOccupied = _getOptionsWorth(option.optType,option.strikePrice,underlyingPrice)*amount;
        require(totalOccupied<=1e40,"Option collateral occupied calculate error");
        return totalOccupied;
    }
    /**
     * @dev calculate one option's occupied collateral.
     * @param optType  option's type
     * @param strikePrice  option's strikePrice
     * @param underlyingPrice  underlying current price.
     */
    function _getOptionsWorth(uint8 optType,uint256 strikePrice,uint256 underlyingPrice)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return strikePrice;
        } else {
            return underlyingPrice;
        }
    }
    /**
     * @dev calculate `amount` number of Option's full price when option is burned.
     * @param optionID  option's optionID
     * @param amount  option's amount
     */
    function getBurnedFullPay(uint256 optionID,uint256 amount) Smaller(amount) public view returns(uint256){
        OptionsInfo storage info = allOptions[optionID-1];
        return info.optionsPrice*amount/info.settlePrice;
    }
}