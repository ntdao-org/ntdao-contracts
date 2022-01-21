const chai = require("chai");
const { ethers } = require("hardhat");
const chaiAsPromised  = require('chai-as-promised');
chai.use(chaiAsPromised);
const expect = chai.expect;


describe("Combined Contract Test", function () {

  let NTDaoNftContract;
  let nft;
  let GeneContract;
  let gene;

  let owner;
  let addr1;
  let addr2;
  let addr3;
  let baseImgUrl = "https://ipfs-gateway.atomrigs.io/ntdao/";

  beforeEach(async function () {

    NTDaoNftContract = await ethers.getContractFactory("NTDaoNft");
    GeneContract = await ethers.getContractFactory("NTDaoNft");

    nft = await NTDaoNftContract.deploy(baseImgUrl);
    await nft.deployed();

    gene = await GeneContract.deploy(nft.address);
    await gene.deployed();

    await nft.updateGene(gene.address);

    [owner, addr1, addr2, addr3] = await ethers.getSigners();    
    
  });

  it("publicMint() should receive ETH", async function () {

    await nft.setStateToPublicMint();
    let options = {value: (await nft.MINTING_FEE()).mul(2)};
    await nft.connect(addr2).publicMint(2,options);
    expect(await nft.getBalance()).to.equal(options.value);
    
  });    

  it("withdraw() should send ETH to the receiver contract", async function () {

    await nft.setStateToPublicMint();
    let options = {value: (await nft.MINTING_FEE()).mul(2)};
    await nft.connect(addr2).publicMint(2,options);
    expect(await nft.getBalance()).to.equal(options.value);

    await nft.connect(owner).withdraw(owner.address, await nft.getBalance());
    console.log(await nft.getBalance());
    expect(await nft.getBalance()).to.equal(0);
  });  

});

