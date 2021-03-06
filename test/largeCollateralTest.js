const BN = require("bn.js");
let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 add large collateral', async function (){
        let contracts = await migration(accounts);
        await AddCollateral0(contracts);
        await createAndAddErc20(contracts);
        await web3.eth.sendTransaction({from:accounts[0],to:contracts.mine.address,value:9e18});
        await contracts.FNX.transfer(contracts.mine.address,new BN("100000000000000000000",10));
//        console.log(tx);
//        return;
        await contracts.manager.addWhiteList(contracts.FNX.address);
        let amount = new BN(1);
        amount = amount.ushln(99);
        await contracts.FNX.approve(contracts.manager.address,amount);
        await contracts.manager.addCollateral(contracts.FNX.address,amount);
        await logBalance(contracts.FNX,contracts.collateral.address);
        let result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("1-----------------------------------",result.toString(10));

        minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.FNX.address);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],collateral0);
        console.log(44444444444444,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],contracts.FNX.address);
        console.log(44444444444444,minebalance.toString(10));

//        contracts.FNX.approve(contracts.manager.address,1000000000000000);
//        tx = await contracts.manager.buyOption(contracts.FNX.address,1000000000000000,20000000000,1,month,10000000000,0);
//        console.log(tx)
/*       
        tx = await contracts.manager.buyOption(collateral0,1,20000000000,1,month,1,0,{value : 1});
//        console.log(tx);
        tx = await contracts.manager.buyOption(collateral0,1,20000000000,1,month,1,0,{value : 1});
//        console.log(tx);
        tx = await contracts.manager.buyOption(collateral0,1,10000000000,1,month,1,0,{value : 1});
//        console.log(tx);
*/
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("2-----------------------------------",result.toString(10));
        /*
        result = await contracts.options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
//        tx = await contracts.manager.sellOption(1,10000000000);
//        console.log(tx);
//        tx = await contracts.manager.exerciseOption(3,10000000000);
        result = await contracts.options.getOptionsById(1);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(2);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
        result = await contracts.options.getOptionsById(3);
        console.log(result[0].toString(10),result[1],result[2].toString(10),result[3].toString(10),result[4].toString(10),result[5].toString(10),result[6].toString(10));
//        console.log(tx);
*/
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("3-----------------------------------",result.toString(10));
        await calculateNetWroth(contracts.options,contracts.collateral,contracts.FNX);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        
        console.log("4-----------------------------------",result.toString(10));
        await logBalance(contracts.FNX,contracts.collateral.address);
        await contracts.manager.redeemCollateral(amount,collateral0);
        await logBalance(contracts.FNX,contracts.collateral.address);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();
        console.log("5-----------------------------------",result.toString(10));
        await contracts.manager.redeemCollateral(1000000001,contracts.FNX.address);
        await logBalance(contracts.FNX,contracts.collateral.address);
        result = await contracts.options.getTotalOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTotalCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getOccupiedCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getLeftCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getAvailableCollateral();
        console.log(result.toString(10));
        result = await contracts.manager.getTokenNetworth();

        console.log("5-----------------------------------",result.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        await contracts.mine.redeemMinerCoin(collateral0,minebalance);
        minebalance = await contracts.mine.getMinerBalance(accounts[0],collateral0);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.FNX.address);
        console.log(33333333333333,minebalance.toString(10));
        await contracts.mine.redeemMinerCoin(contracts.FNX.address,minebalance);
        minebalance = await contracts.mine.getMinerBalance(accounts[0],contracts.FNX.address);
        console.log(33333333333333,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],collateral0);
        await contracts.mine.redeemMinerCoin(collateral0,minebalance,{from:accounts[1]});
        minebalance = await contracts.mine.getMinerBalance(accounts[1],collateral0);        
        console.log(44444444444444,minebalance.toString(10));
        minebalance = await contracts.mine.getMinerBalance(accounts[1],contracts.FNX.address);
        await contracts.mine.redeemMinerCoin(contracts.FNX.address,minebalance,{from:accounts[1]});
        minebalance = await contracts.mine.getMinerBalance(accounts[1],contracts.FNX.address);    
        console.log(44444444444444,minebalance.toString(10));
    });
});
async function logBalance(fnx,addr){
        let colBalance = await web3.eth.getBalance(addr);
        console.log("eth : ",addr,colBalance);
        let fnxBalance = await fnx.balanceOf(addr);
        console.log("fnx : ",addr,fnxBalance.toString(10));
}
async function calculateNetWroth(options,collateral,fnx){
        let whiteList = [collateral0,fnx.address];
        optionsLen = await options.getOptionCalRangeAll(whiteList);
        console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));
    
        let result =  await options.calculatePhaseOccupiedCollateral(optionsLen[4],optionsLen[0],optionsLen[4]);
        console.log(result[0].toString(10),result[1].toString(10));
        let tx = await options.setOccupiedCollateral();
        result =  await options.calRangeSharedPayment(optionsLen[4],optionsLen[2],optionsLen[4],whiteList);
        console.log(result[0][0].toString(10),result[0][1].toString(10));
    
    //                return;
        tx = await collateral.calSharedPayment(whiteList);
    //    console.log(tx);
    }