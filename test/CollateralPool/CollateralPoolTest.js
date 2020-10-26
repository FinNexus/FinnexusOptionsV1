const CollateralPool = artifacts.require("CollateralPool");
const CollateralProxy = artifacts.require("CollateralProxy");
let OptionsPool = artifacts.require("OptionsPool");
let OptionsProxy = artifacts.require("OptionsProxy");
const ImpliedVolatility = artifacts.require("ImpliedVolatility");
const FNXOracle = artifacts.require("TestFNXOracle");
const OptionsPrice = artifacts.require("OptionsPrice");

let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
contract('CollateralPool', function (accounts){

    it('CollateralPool set functions', async function (){
        let ivInstance = await ImpliedVolatility.new();
        let oracleInstance = await FNXOracle.new();
        let price = await OptionsPrice.new(ivInstance.address);
        let optPool = await OptionsPool.new(oracleInstance.address,price.address,ivInstance.address);
        let options = await OptionsProxy.new(optPool.address,oracleInstance.address,price.address,ivInstance.address);
        let collateral = await CollateralPool.new(options.address);
        let pool = await CollateralProxy.new(collateral.address,options.address);
        for (var i=0;i<5;i++){
            let result = await pool.getFeeRate(i);
            if (i == 1){
                assert.equal(result,50,"getFeeRate Error");
            }else{
                assert.equal(result.toNumber(),0,"getFeeRate Error");
            }
        }
        for (var i=0;i<5;i++){
            await pool.setTransactionFee(i,i+1);
            let result = await pool.getFeeRate(i);
            assert.equal(result,i+1,"getFeeRate Error");
        }
        let result = await pool.getFeeBalance();
        assert.equal(result,0,"getFeeBalance Error");

        result = await pool.getUserPayingUsd(accounts[0]);
        assert.equal(result,0,"getUserPayingUsd Error");
        result = await pool.getUserInputCollateral(accounts[0]);
        assert.equal(result,0,"getUserInputCollateral Error");
        result = await pool.getNetWorthBalance();
        assert.equal(result,0,"getNetWorthBalance Error");
        result = await pool.getCollateralBalance();
        assert.equal(result,0,"getCollateralBalance Error");
    });

});