const chai = require("chai");
const { ethers } = require("hardhat");
const chaiAsPromised  = require('chai-as-promised');
const { utils, BigNumber } = require("ethers");
const BN = require('bn.js');

chai.use(chaiAsPromised);
chai.use(require('chai-bn')(BN));
const expect = chai.expect;

describe("NTDaoNft", function () {

  let NTDaoNftContract;
  let nft;
  let owner;
  let addr1;
  let addr2;
  let addr3;

  beforeEach(async function () {
    NTDaoNftContract = await ethers.getContractFactory("NTDaoNft");
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    nft = await NTDaoNftContract.deploy(); 
    await nft.deployed();
    
  });

  describe("update minting fee", async () => {
    it("updateMintingFee() should allow to update MINTING_FEE", async function () {
      await nft.updateMintingFee(ethers.utils.parseEther("0.1"));
      expect(await nft.MINTING_FEE()).to.equal(ethers.utils.parseEther("0.1"));
    });
  
    it("updateMintingFee() should NOT allow to update MINTING_FEE unless the caller is the owner", async function () {
      await expect(nft.connect(addr1).updateMintingFee(ethers.utils.parseEther("0.1")))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });  
  });

  describe("change state", async () => {
    it("setStateToSetup() should change the State to Setup", async function () {
      expect(await nft.setStateToSetup()).to.emit(nft, "StateChanged").withArgs(0);
      expect(await nft.state()).to.equal(0);
    });

    it("setStateToSetup() should NOT change the State to Setup unless the caller is the owner", async function () {
      await expect(nft.connect(addr3).setStateToSetup()).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("setStateToPublicMint() should change the State to PublicMint", async function () {
      expect(await nft.setStateToPublicMint()).to.emit(nft, "StateChanged").withArgs(1);
      expect(await nft.state()).to.equal(1);
    });

    it("setStateToPublicMint() should NOT change the State to PublicMint unless the caller is the owner", 
      async function () {
        await expect(nft.connect(addr1).setStateToPublicMint())
          .to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("setStateToRefund() should change the State to Finished", async function () {
      expect(await nft.setStateToRefund()).to.emit(nft, "StateChanged").withArgs(2);
      expect(await nft.state()).to.equal(2);
    });  

    it("setStateToRefund() should NOT change the State to Finished unless the caller is the owner", 
      async function () {
        await expect(nft.connect(addr1).setStateToRefund()).to.be.revertedWith("Ownable: caller is not the owner");
    });  

    it("setStateToFinished() should change the State to Finished", async function () {
      expect(await nft.setStateToFinished()).to.emit(nft, "StateChanged").withArgs(3);
      expect(await nft.state()).to.equal(3);
    });  

    it("setStateToFinished() should NOT change the State to Finished unless the caller is the owner", 
      async function () {
        await expect(nft.connect(addr1).setStateToFinished())
          .to.be.revertedWith("Ownable: caller is not the owner");
    });

  });

  describe("set permanent", async () => {
    it("changeToPermenent() should change the state to permanent by the owner", 
      async () => {
        expect(await nft.isPermanent()).to.equal(false);
        await nft.changeToPermanent();
        expect(await nft.isPermanent()).to.equal(true);
    });

    it("changeToPermenent() should NOT allow to change the state unless the caller is the owner", 
      async function () {
        await expect(nft.connect(addr2).changeToPermanent()).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("updateGene() should NOT allow update gene after the state is permanent", async () => {
      const randomAddr = "0xd27e9361b525E9fb69257226Ce4195266FF41E64";
      nft.changeToPermanent();
      await expect(nft.updateGene(randomAddr)).to.be.revertedWith("NTDAO-NFT: Gene contract is fixed");
    });
  });

  describe("minting", async () => {
    
    beforeEach(async () => {
      await nft.setStateToPublicMint();
    });

    it("publicMint() should allow public minting", async function () {
      let options = {value: (await nft.MINTING_FEE()).mul(5)};
      await nft.connect(addr1).publicMint(5, options);
      expect(await nft.tokensOf(addr1.address)).to.have.lengthOf(5);
    });   

    it("publicMint() should allow minting only in the state, PublicMint", async function () {

      let options = {value: (await nft.MINTING_FEE()).mul(5)};
      await nft.setStateToSetup();
      await expect(nft.connect(addr1).publicMint(5, options))
        .to.be.revertedWith("NTDAO-NFT: State is not in PublicMint");
  
      await nft.setStateToRefund();
      await expect(nft.connect(addr1).publicMint(5, options))
        .to.be.revertedWith("NTDAO-NFT: State is not in PublicMint");
  
      await nft.setStateToFinished();
      await expect(nft.connect(addr1).publicMint(5, options))
        .to.be.revertedWith("NTDAO-NFT: State is not in PublicMint");
  
      await nft.setStateToPublicMint();
      await nft.connect(addr1).publicMint(5, options);
      expect(await nft.tokensOf(addr1.address)).to.have.lengthOf(5);
    });

    it("should not allow minting exceeding MAX_PUBLIC_MULTI", async () => {
      const maxNumMint = await nft.MAX_PUBLIC_MULTI();
      await expect(nft.connect(addr1).publicMint(maxNumMint + 1)).
        to.be.revertedWith("NTDAO-NFT: Minting count exceeds more than allowed");
    });

    it("should not allow minting if minting fee not match", async () => {
      // one less
      let options = {value: (await nft.MINTING_FEE()).mul(2).sub(1)};

      await expect(nft.connect(addr2).publicMint(2, options)).
        to.be.revertedWith("NTDAO-NFT: Minting fee amounts does not match.");

      // one more
      options = {value: (await nft.MINTING_FEE()).mul(2).add(1)};

      await expect(nft.connect(addr2).publicMint(2, options)).
        to.be.revertedWith("NTDAO-NFT: Minting fee amounts does not match.");
  
    });

    it("getBalance() should return current contract's balance", async function () {
      expect(await nft.getBalance()).to.equal(0);
    });    
  });

  describe("withdraw", async () => {
    beforeEach(async () => {
      // send eth to the contract
      await addr1.sendTransaction({to: nft.address, value: utils.parseEther("70")});
      await addr2.sendTransaction({to: nft.address, value: utils.parseEther("80")});
    });

    it("withdraw() should NOT allow withdraw unless the caller is the owner", async () => {
      await expect(nft.connect(addr1).withdraw(addr1.address, utils.parseEther("50"))).
        to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("withdraw() should allow the owner to withdraw some balance", async () => {
      // init balance contract has
      const contInitBalance = await nft.getBalance();
      expect(contInitBalance).to.be.equal(utils.parseEther("150"));

      // init balance addr1 has
      const initBalance = utils.formatEther(await addr1.getBalance());

      expect(await nft.withdraw(addr1.address, utils.parseEther("50"))).
        to.emit(nft, "BalanceWithdraw").withArgs(addr1.address, utils.parseEther("50"));

      // balance after withdraw (contract)
      const contAfterBalance = await nft.getBalance();
      expect(contAfterBalance).to.be.equal(utils.parseEther("100"));

      // balance after withdraw (addr1)
      const afterBalance = utils.formatEther(await addr1.getBalance());

      // should received withdrawn token
      expect(parseFloat(afterBalance) - parseFloat(initBalance))
        .to.be.closeTo(parseFloat("50"), 1e-1);
    });

    it("withdraw() should NOT allow withdraw exceeding the balance", async () => {
      await expect(nft.withdraw(addr1.address, utils.parseEther("151"))).to.be.reverted;
    });
  });

  describe("transfer", async () => {
    it("transferBatch() should allow to transfer multiple tokens", async function () {

      await nft.setStateToPublicMint();
      let options = {value: (await nft.MINTING_FEE()).mul(10)};
      await nft.connect(addr1).publicMint(10, options);
      let tokens = await nft.tokensOf(addr1.address)
      expect(tokens).to.have.lengthOf(10);
      await nft.connect(addr1).transferBatch(tokens, addr2.address);
      expect(await nft.tokensOf(addr2.address)).to.have.lengthOf(10);
    });
  });

  describe("refund", () => {

    let tokenIds;

    beforeEach(async () => {
      // mint nfts
      let options = {value: (await nft.MINTING_FEE()).mul(2)};
      await nft.setStateToPublicMint();
      await nft.connect(addr1).publicMint(2, options);
      tokenIds = await nft.tokensOf(addr1.address);
      expect(await await nft.refundState(tokenIds[0])).to.be.equal(false);
      expect(await await nft.refundState(tokenIds[1])).to.be.equal(false);
    });

    it("refund() should to now allow refund the state is Setup", async () => {
      nft.setStateToSetup();
      await expect(nft.connect(addr1).refund(tokenIds)).
        to.be.revertedWith("NTDAO-NFT: State is not in Refund");
    });
  
  
    it("refund() should not refund if the state is PublicMint", async () => {
      await expect(nft.connect(addr1).refund(tokenIds)).
        to.be.revertedWith("NTDAO-NFT: State is not in Refund");
    });
  
    it("refund() should to now allow refund the state is Finished", async () => {
      nft.setStateToFinished();
      await expect(nft.connect(addr1).refund(tokenIds)).
        to.be.revertedWith("NTDAO-NFT: State is not in Refund");
    });
  
    it("refund() should refund the minting fee based on each token's share", async function () {
      // init balance addr1 has
      const initBalance = utils.formatEther(await addr1.getBalance());
      
      // refund
      await nft.setStateToRefund();
      await nft.connect(addr1).refund(tokenIds);
      expect(await await nft.refundState(tokenIds[0])).to.be.equal(true);
      expect(await await nft.refundState(tokenIds[1])).to.be.equal(true);

      // balance after refund
      const afterBalance = utils.formatEther(await addr1.getBalance());

      // should received all the fund
      expect(parseFloat(afterBalance) - parseFloat(initBalance))
        .to.be.closeTo(parseFloat(utils.formatEther((await nft.MINTING_FEE()).mul(2))), 1e-3);
    });
  })
});


