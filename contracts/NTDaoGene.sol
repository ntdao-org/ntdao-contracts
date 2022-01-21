// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title National Treasure DAO Gene Contract
 * @author Atomrigs Lab 
 */

contract NTDaoGene is Ownable {

    address public _nftAddr;

    string[] private classes = [
        "common",   //0
        "uncommon", //1
        "rare",     //2
        "epic",     //3
        "legendary"//4
    ];

    string[] private elements = [
        "water",   //0
        "wood",    //1
        "fire",    //2
        "earth",   //3
        "metal"   //4
    ];

    string[] private branches = [
        "rat",     //0
        "ox",      //1
        "tiger",   //2
        "rabbit",  //3
        "dragon",  //4        
        "snake",   //5
        "horse"    //6
        "goat",    //7
        "monkey",  //8
        "rooster",  //9
        "dog",      //10
        "pig"      //11        
    ];

    modifier onlyNftOrOwner() {
        require(_msgSender() == _nftAddr || _msgSender() == owner(), "TankGene: caller is not the NFT tank contract address");
        _;
    }

    constructor(address nftAddr_) {
        _nftAddr = nftAddr_;
    }    

    function getNftAddr() external view returns (address) {
        return _nftAddr;
    }

    function setNftAddr(address nftAddr_) external onlyOwner {
        _nftAddr = nftAddr_;
    }

    function getSeed(uint _tokenId) public view onlyNftOrOwner returns (uint) {
        return uint256(keccak256(abi.encodePacked(_tokenId, uint(2022))));
    }

    function getBaseGenes(uint _tokenId) public view onlyNftOrOwner returns (uint[] memory) {
        uint[] memory genes = new uint[](3);
        uint seed = getSeed(_tokenId);
        genes[0] = getClassIdx(seed);
        genes[1] = getElementIdx(seed);
        genes[2] = getBranchIdx(seed);
        return genes;
    }

    function getBaseGeneNames(uint _tokenId) public view onlyNftOrOwner returns (string[] memory) {

        uint[] memory genes = getBaseGenes(_tokenId);
        string[] memory geneNames = new string[](3);
        geneNames[0] = classes[genes[0]];
        geneNames[1] = elements[genes[1]];
        geneNames[2] = branches[genes[2]];
        return geneNames;
    }    

    function getImgIdx(uint _tokenId) public view onlyNftOrOwner returns (string memory) {

        uint[] memory genes = getBaseGenes(_tokenId);
        string memory class = toString(genes[0] + uint(1));
        string memory element = toString(genes[1] + uint(1));

        string memory branch;
        if(genes[1] <= 8) {
            branch = string(abi.encodePacked("0", toString(genes[1] + uint(1))));
        } else {
            branch = toString(genes[1] + uint(1));
        }
        return string(abi.encodePacked(class, element, branch));
    }

    function getClassIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/10) % 100;
        if (v < 50) {
            return uint(0);
        } else if (v < 80) {
            return uint(1);
        } else if (v < 94) {
            return uint(2);
        } else if (v < 99) {
            return uint(3);
        } else {
            return uint(4);
        }
    }      

    function getElementIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/1000) % 100;
        if (v < 50) {
            return uint(0);
        } else if (v < 75) {
            return uint(1);
        } else if (v < 85) {
            return uint(2);
        } else if (v < 95) {
            return uint(3);
        } else {
            return uint(4);
        }
    }

    function getBranchIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/100000) % 100;
        if (v < 20) {
            return uint(0);
        } else if (v < 35) {
            return uint(1);
        } else if (v < 47) {
            return uint(2);
        } else if (v < 57) {
            return uint(3);
        } else if (v < 66) {
            return uint(4);
        } else if (v < 74) {
            return uint(5);
        } else if (v < 82) {
            return uint(6);
        } else if (v < 90) {
            return uint(7);
        } else if (v < 94) {
            return uint(8);
        } else if (v < 97) {
            return uint(9);
        } else if (v < 99) {
            return uint(10);
        } else {
            return uint(11);
        }
    }

    function getDescription() external pure returns (string memory) {
        string memory desc = "The National Treasure DAO (NTDAO) is a project designed to protect the cultural heritage of Korea as a shared property of citizens and spread its meaning to the public. The name DAO (Decentralized Autonomous Organization) was given, because this project is not for the benefit of a particular company or individual, but to express the voluntary participation of many citizens and communities to achieve the goal of the organization through decentralized decision-making. The process of carrying out this project itself is also the goal of contemplating, sharing, and working together on the true meaning of cultural heritage protection.";
        return desc;
    }

    function getAttrs(uint _tokenId) external view returns (string memory) {
        string[] memory genes  = getBaseGeneNames(_tokenId);
        string[7] memory parts;

        parts[0] = '[{"trait_type": "class", "value": "';
        parts[1] = genes[0];
        parts[2] = '"}, {"trait_type": "element", "value": "';
        parts[3] = genes[1];
        parts[4] = '"}, {"trait_type": "branch", "value": "';        
        parts[5] = genes[2];
        parts[6] = '"}]';

        string memory attrs = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        return attrs;
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }    
}