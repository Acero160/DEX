const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dex", function () {
    let dexContract;
    let signers = [];
    let daiContract;
    let dotContract;
    let solContract;

    const [DAI, DOT, SOL] = ["DAI", "DOT", "SOL"];

    let trader1;
    let trader2;

    beforeEach(async function () {
        signers = await ethers.getSigners();
        trader1 = signers[1];
        trader2 = signers[2];

       
        const Dex = await ethers.getContractFactory("Dex", { signer: signers[0] });
        dexContract = await Dex.deploy();
        await dexContract.waitForDeployment(); 

      
        const Dai = await ethers.getContractFactory("Dai", { signer: signers[0] });
        daiContract = await Dai.deploy();
        await daiContract.waitForDeployment();

        const Dot = await ethers.getContractFactory("Dot", { signer: signers[0] });
        dotContract = await Dot.deploy();
        await dotContract.waitForDeployment();

        const Sol = await ethers.getContractFactory("Sol", { signer: signers[0] });
        solContract = await Sol.deploy();
        await solContract.waitForDeployment();

        
        console.log("DEX:", await dexContract.getAddress());
        console.log("DAI:", await daiContract.getAddress());
        console.log("DOT:", await dotContract.getAddress());
        console.log("SOL:", await solContract.getAddress());

        
        await dexContract.addToken(DAI, await daiContract.getAddress());
        await dexContract.addToken(DOT, await dotContract.getAddress());
        await dexContract.addToken(SOL, await solContract.getAddress());

        
        await daiContract.connect(signers[0]).transfer(trader1.address, ethers.parseUnits("100", "ether"));
        await daiContract.connect(signers[0]).transfer(trader2.address, ethers.parseUnits("3000", "ether"));

        await dotContract.connect(signers[0]).transfer(trader1.address, ethers.parseUnits("100", "ether"));
        await dotContract.connect(signers[0]).transfer(trader2.address, ethers.parseUnits("100", "ether"));

        await solContract.connect(signers[0]).transfer(trader1.address, ethers.parseUnits("100", "ether"));
        await solContract.connect(signers[0]).transfer(trader2.address, ethers.parseUnits("100", "ether"));

       
        await daiContract.connect(trader1).approve(await dexContract.getAddress(), ethers.parseUnits("10000", "ether"));
        await daiContract.connect(trader2).approve(await dexContract.getAddress(), ethers.parseUnits("10000", "ether"));

        await dotContract.connect(trader1).approve(await dexContract.getAddress(), ethers.parseUnits("10000", "ether"));
        await dotContract.connect(trader2).approve(await dexContract.getAddress(), ethers.parseUnits("10000", "ether"));

        await solContract.connect(trader1).approve(await dexContract.getAddress(), ethers.parseUnits("10000", "ether"));
        await solContract.connect(trader2).approve(await dexContract.getAddress(), ethers.parseUnits("10000", "ether"));
    });

    //Function deposit
    it("You should deposit tokens", async function () {
        let amount = ethers.parseUnits("10", "ether");
        await dexContract.connect(trader1).deposit(amount, DAI);
        let balance = await dexContract.balances(trader1.address, DAI);
        expect(balance).to.equal(amount);
    });

    it("Reject the deposit of an unapproved token.", async function () {
        let amount = ethers.parseUnits("10", "ether");
        await expect(dexContract.connect(trader1).deposit(amount, "Token non exist")).to.be.revertedWith("Token does not exist");
    });

    //Function Withdraw
    it("You should withdraw the tokens deposited in the DEX.", async function () {
        let amount = ethers.parseUnits("10", "ether");
        await dexContract.connect(trader1).deposit(amount, DAI);
        let balance = await dexContract.balances(trader1.address, DAI);
        expect(balance).to.equal(amount);

        await dexContract.connect(trader1).withdraw(amount, DAI);
        balance = await dexContract.balances(trader1.address, DAI);
        expect(balance).to.equal(0);
    });

    it("You can not deposit on unapproved token.", async function () {
        let amount = ethers.parseUnits("10", "ether");
        await expect(dexContract.connect(trader1).withdraw(amount, "Token non exist")).to.be.revertedWith("Token does not exist");
    });


   

    //Function CreateLimitOrder
    it("You should create an order limit", async function () {
        let amount = ethers.parseUnits("10", "ether");
        let price = 1;

        await dexContract.connect(trader1).deposit(amount, DOT);
        await dexContract.connect(trader1).createLimitOrder(DOT, amount, price, 1); 
        
        let buyOrders =  await dexContract.getOrders(DOT, 0);
        let sellOrders =  await dexContract.getOrders(DOT, 1); 
        

        expect(sellOrders).to.have.lengthOf(1);
        expect(buyOrders).to.have.lengthOf(0);

        expect(sellOrders[0].price).to.equal(price);
        expect(sellOrders[0].amount).to.equal(amount);
        expect(sellOrders[0].ticker).to.equal(DOT);
        expect(sellOrders[0].filled).to.equal(0);
        
    });

    //Function CreateMarkerOrder
    it("You should create an order market", async function () {
        let amount1 = ethers.parseUnits("10", "ether");
        let amount2 = ethers.parseUnits("20", "ether");
        let amountTotal = ethers.parseUnits("40", "ether");
        let price1 = 20;
        let price2 = 25;

        await dexContract.connect(trader1).deposit(amountTotal, DOT);
        await dexContract.connect(trader1).createLimitOrder(DOT, amount1, price1, 1); 
        await dexContract.connect(trader1).createLimitOrder(DOT, amount1, price1, 1); 
        await dexContract.connect(trader1).createLimitOrder(DOT, amount2, price2, 1); 

        let amountDai = ethers.parseUnits ("2000", "ether");
        await dexContract.connect(trader2).deposit(amountDai, DAI);
        await dexContract.connect(trader2).createMarketOrder(DOT, amountTotal, 0);
        let dotAmount = ethers.parseUnits("40", "ether");
        trader2DotBalance = await dexContract.balances(trader2.address, DOT);
        
        let sellOrders =  await dexContract.getOrders(DOT, 1); 

        expect(trader2DotBalance).to.equal(dotAmount);
        expect(sellOrders[0].filled).to.equal(amount2);
        expect(sellOrders[0].amount).to.equal(amount2);
    
    });
});
