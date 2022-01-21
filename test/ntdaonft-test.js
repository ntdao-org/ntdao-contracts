const chai = require("chai");
const { ethers } = require("hardhat");
const chaiAsPromised  = require('chai-as-promised');
chai.use(chaiAsPromised);
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

    nft = await NTDaoNftContract.deploy("https://ipfs-gateway.atomrigs.io/ntdao/"); 
    await nft.deployed();
    
  });

  it("updateMintingFee() should allow to update MINTING_FEE", async function () {
    await nft.updateMintingFee(ethers.utils.parseEther("0.1"));
    expect(await nft.MINTING_FEE()).to.equal(ethers.utils.parseEther("0.1"));
  });

  it("updateMintingFee() should NOT allow to update MINTING_FEE unless the caller is the owner", async function () {
    await expect(nft.connect(addr1).updateMintingFee(ethers.utils.parseEther("0.1")))
    .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("updateBaseImgUrl() should NOT allow to update baseImgUrl unless the caller is the owner", async function () {
    const baseImgUrl = "https://ipfs.io/ipfs/";
    await expect(nft.connect(addr1).updateBaseImgUrl(baseImgUrl))
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("updateBaseImgUrl() should NOT allow to update baseImgUrl once isPermanent is set", async function () {
    await nft.changeToPermanent();
    const baseImgUrl = "https://ipfs.io/ipfs/"
    await expect(nft.updateBaseImgUrl(baseImgUrl))
      .to.be.revertedWith("NTDAO-NFT: All images are on ipfs");
  })

  it("changeToPermenent() should NOT allow to change the state unless the caller is the owner", 
    async function () {
      await expect(nft.connect(addr2).changeToPermanent()).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("setStateToSetup() should change the State to Setup", async function () {
    await nft.setStateToSetup();
    expect(await nft.state()).to.equal(0);
  });

  it("setStateToSetup() should NOT change the State to Setup unless the caller is the owner", async function () {
    await expect(nft.connect(addr3).setStateToSetup()).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("setStateToSetup() should NOT change the State to Setup unless caller is the owner", async function () {
    await nft.setStateToSetup();
    expect(await nft.state()).to.equal(0);
  });

  it("setStateToPublicMint() should change the State to PublicMint", async function () {
    await nft.setStateToPublicMint();
    expect(await nft.state()).to.equal(1);
  });

  it("setStateToPublicMint() should NOT change the State to PublicMint unless the caller is the owner", 
    async function () {
      await expect(nft.connect(addr1).setStateToPublicMint())
        .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("setStateToFinished() should change the State to Finished", async function () {
    await nft.setStateToFinished();
    expect(await nft.state()).to.equal(3);
  });  

  it("setStateToFinished() should NOT change the State to Finished unless the caller is the owner", 
    async function () {
      await expect(nft.connect(addr1).setStateToFinished())
        .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("setStateToRefund() should change the State to Finished", async function () {
    await nft.setStateToRefund();
    expect(await nft.state()).to.equal(2);
  });  


  it("getBalance() should return current contract's balance", async function () {
    expect(await nft.getBalance()).to.equal(0);
  });    

  it("publicMint() should allow public minting", async function () {

    await nft.setStateToPublicMint();
    let options = {value: (await nft.MINTING_FEE()).mul(5)};
    await nft.connect(addr1).publicMint(5, options);
    expect(await nft.tokensOf(addr1.address)).to.have.lengthOf(5);
  });   

  it("transferBatch() should allow to transfer multiple tokens", async function () {

    await nft.setStateToPublicMint();
    let options = {value: (await nft.MINTING_FEE()).mul(10)};
    await nft.connect(addr1).publicMint(10, options);
    let tokens = await nft.tokensOf(addr1.address)
    expect(tokens).to.have.lengthOf(10);
    await nft.connect(addr1).transferBatch(tokens, addr2.address);
    expect(await nft.tokensOf(addr2.address)).to.have.lengthOf(10);
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

  it("refund() should refund the minting fee based on each token's share", async function () {
    let options = {value: (await nft.MINTING_FEE()).mul(2)};
    await nft.setStateToPublicMint();
    await nft.connect(addr1).publicMint(2, options);
    let tokenIds = await nft.tokensOf(addr1.address);
    await nft.setStateToRefund();
    await nft.connect(addr1).refund(tokenIds);
    expect(await nft.refunds(tokenIds[0])).to.be.equal(true);
  });


});


