const hre = require("hardhat");
const ethers = hre.ethers;

let signingKey = new ethers.utils.SigningKey("0x63eeb773af53b643eb56f5742e3f6bcafed1fa5538af07e02ccbd95726a4e554");
let signingKeyAddr = ethers.utils.computeAddress(signingKey.publicKey);
let signer = {address: signingKeyAddr, key: signingKey};
let NFTContract;
let nft;
let GeneContract;
let gene;

let owner;
let addr1;
let addr2;
let addr3;

(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    GeneContract = await ethers.getContractFactory("NTDaoGene");
    NFTContract = await ethers.getContractFactory("NTDaoNft");

    nft = await NFTContract.deploy(); 
    await nft.deployed();

    gene = await GeneContract.deploy(nft.address); 
    await gene.deployed();

    await nft.updateGene(gene.address);
})();
