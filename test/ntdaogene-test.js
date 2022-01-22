const chai = require("chai");
const { ethers } = require("hardhat");
const chaiAsPromised  = require('chai-as-promised');
chai.use(chaiAsPromised);
const expect = chai.expect;

describe("NTDaoGene", function () {
  let GeneContract;
  let gene;
  let owner;
  let addr1;
  let nftAddr;

  beforeEach(async function () {
    GeneContract = await ethers.getContractFactory("NTDaoGene");
    [owner, addr1, nftAddr] = await ethers.getSigners();

    gene = await GeneContract.deploy(nftAddr.address); //should be NFT address
    await gene.deployed();
    
  });

  it("Should provide the correct nft address", async function () {

    expect(await gene.getNftAddr()).to.equal(nftAddr.address);

  });  

  it("Should match the updated nft address", async function () {

    await gene.setNftAddr(addr1.address);
    expect(await gene.getNftAddr()).to.equal(addr1.address);

  });  

  it("getSeed() should return seed", async function () {

    expect((await gene.getSeed(1)).isZero()).to.equal(false);
    expect((await gene.getSeed(1000)).isZero()).to.equal(false);

  });  

  it("getSeed() should work only with NftAddr or Owner address", async function () {

    await expect(gene.connect(addr1).getSeed(1)).to.eventually.be.rejectedWith(Error);
    await expect(gene.connect(nftAddr).getSeed(1)).to.eventually.be.not.rejectedWith(Error);
    await expect(gene.connect(owner).getSeed(1)).to.eventually.be.not.rejectedWith(Error);

  });  

  it("getBaseGenes() should work only with NftAddr or Owner address", async function () {

    await expect(gene.connect(addr1).getBaseGenes(1)).to.eventually.be.rejectedWith(Error);
    expect(await gene.connect(nftAddr).getBaseGenes(1)).to.be.an('array');
    expect(await gene.connect(owner).getBaseGenes(1000)).to.be.an('array');

  });  

  it("getBaseGeneNames() should work only with NftAddr or Owner address", async function () {

    await expect(gene.connect(addr1).getBaseGeneNames(1)).to.eventually.be.rejectedWith(Error);
    expect(await gene.connect(nftAddr).getBaseGeneNames(1)).to.be.an('array');
    expect(await gene.connect(owner).getBaseGeneNames(1000)).to.be.an('array');

  });  

});

