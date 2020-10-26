let month = 30*60*60*24;
let collateral0 = "0x0000000000000000000000000000000000000000";
const BN = require("bn.js");
let {migration ,createAndAddErc20,AddCollateral0} = require("./testFunction.js");
contract('OptionsManagerV2', function (accounts){
    it('OptionsManagerV2 add collateral', async function (){
        let contracts = await migration(accounts,collateral0);
        await contracts.options.addExpiration(month);      
        let mineInfo = await contracts.mine.getMineInfo(collateral0);
        console.log (mineInfo);
        for (var i=0;i<10;i++){
            for (var j=0;j<5;j++){
                contracts.manager.addCollateral(1000000000000000,{value : 1000000000000000});
                contracts.manager.addCollateral(1000000000000000,{value : 1000000000000000});
                contracts.manager.addCollateral(1000000000000000,{value : 1000000000000000});
                contracts.manager.addCollateral(1000000000000000,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,8250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,9257*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,9251*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,11250*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,9253*1e8,1,month,10000000000,0,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,9260*1e8,1,month,10000000000,0,{value : 1000000000000000});

                contracts.manager.buyOption(1000000000000000,11050*1e8,1,month,10000000000,1,{value : 1000000000000000});
                contracts.manager.buyOption(1000000000000000,9056*1e8,1,month,10000000000,1,{value : 1000000000000000});
        //        console.log(tx);
                await contracts.manager.buyOption(200000000000000,9258*1e8,1,month,10000000000,1,{value : 200000000000000});
        //        console.log(tx);
            }
            await calculateNetWroth(contracts);
            return;
        }
     });
    it('OptionsManagerV2 buy options Price test', async function (){
        let fnx = await createAndAddErc20();
        let contracts = await migration(accounts,fnx.address);
        await contracts.options.addExpiration(month);      
        let mineInfo = await contracts.mine.getMineInfo(fnx.address);
        console.log (mineInfo);
        await fnx.approve(contracts.manager.address,new BN("15000000000000000"));
        contracts.manager.addCollateral(1000000000000000);
        contracts.manager.addCollateral(1000000000000000);
        contracts.manager.addCollateral(1000000000000000);
        contracts.manager.addCollateral(1000000000000000);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,0);

        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,1);
        contracts.manager.buyOption(1000000000000000,9150*1e8,1,month,10000000000,1);
//        console.log(tx);
        await contracts.manager.buyOption(200000000000000,9150*1e8,1,month,10000000000,1);
//        console.log(tx);

    await calculateNetWroth(contracts);

     });
});
async function calculateNetWroth(contracts){
    optionsLen = await contracts.options.getOptionCalRangeAll();
    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10));
//    console.log(optionsLen[0].toString(10),optionsLen[1].toString(10),optionsLen[2].toString(10),optionsLen[4].toString(10));
    let result =  await contracts.options.calculatePhaseOccupiedCollateral(optionsLen[4],optionsLen[0],optionsLen[4]);
    console.log(result[0].toString(10),result[1].toString(10));
    let tx = await contracts.options.setOccupiedCollateral();
//    result =  await options.calRangeSharedPayment(optionsLen[4],optionsLen[2],optionsLen[4],whiteList);
//    console.log(result[0][0].toString(10),result[0][1].toString(10));

//                return;q
    tx = await contracts.collateral.calSharedPayment();
    console.log(tx);
}