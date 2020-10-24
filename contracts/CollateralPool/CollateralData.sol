pragma solidity =0.5.16;
import "../modules/Managerable.sol";
import "../modules/AddressWhiteList.sol";
import "../OptionsPool/IOptionsPool.sol";
import "../modules/Operator.sol";
/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralData is Managerable,Operator,ImportOptionsPool{
        // The total fees accumulated in the contract
    address internal collateral;
    uint256	internal feeBalance;
    uint32[] internal FeeRates;
     /**
     * @dev Returns the rate of trasaction fee.
     */   
    uint32 constant internal buyFee = 0;
    uint32 constant internal sellFee = 1;
    uint32 constant internal exerciseFee = 2;
    uint32 constant internal addColFee = 3;
    uint32 constant internal redeemColFee = 4;
    event RedeemFee(address indexed recieptor,uint256 payback);
    event AddFee(uint256 payback);
    event TransferPayback(address indexed recieptor,uint256 payback);

    //token net worth balance
    int256 internal netWorthBalance;
    //total user deposited collateral balance
    // map from collateral address to amount
    uint256 internal collateralBalance;
    //user total paying for collateral, priced in usd;
    mapping (address => uint256) internal userCollateralPaying;
    //user original deposited collateral.
    //map account -> collateral -> amount
    mapping (address => uint256) internal userInputCollateral;
}