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
        "Common",           //0
        "Rare",             //1
        "Super Rare",       //2
        "Treasure",         //3
        "National Treasure" //4
    ];

    string[] private elements = [
        "Water",   //0
        "Wood",    //1
        "Fire",    //2
        "Earth",   //3
        "Metal"    //4
    ];

    string[] private branches = [
        "Rat",     //0
        "Ox",      //1
        "Tiger",   //2
        "Rabbit",  //3
        "Dragon",  //4        
        "Snake",   //5
        "Horse"    //6
        "Goat",    //7
        "Monkey",  //8
        "Rooster", //9
        "Dog",     //10
        "Pig"      //11        
    ];

    string[] private divisions = [
        "Geumgang",  //0
        "Seorak",    //1
        "Jiri",      //2
        "Halla",     //3
        "Baekdu"     //4
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
        uint[] memory genes = new uint[](4);
        uint seed = getSeed(_tokenId);
        genes[0] = getClassIdx(seed);
        genes[1] = getElementIdx(seed);
        genes[2] = getBranchIdx(seed);
        genes[3] = getDivisionIdx(seed);
        return genes;
    }

    function getBaseGeneNames(uint _tokenId) public view onlyNftOrOwner returns (string[] memory) {

        uint[] memory genes = getBaseGenes(_tokenId);
        string[] memory geneNames = new string[](4);
        geneNames[0] = classes[genes[0]];
        geneNames[1] = elements[genes[1]];
        geneNames[2] = branches[genes[2]];
        geneNames[3] = divisions[genes[3]];
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

    function getDivisionIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/10000000) % 100;
        if (v < 50) {
            return uint(0);
        } else if (v < 85) {
            return uint(1);
        } else if (v < 97) {
            return uint(2);
        } else if (v < 99) {
            return uint(3);
        } else {
            return uint(4);
        }
    }

    function getDescription() external pure returns (string memory) {
        string memory desc = "The National Treasure DAO (NTDAO) is a project designed to protect the cultural heritage of Korea as a shared property of citizens and spread its meaning to the public. The name DAO (Decentralized Autonomous Organization) was given, because this project is not for the benefit of a particular company or individual, but to express the voluntary participation of many citizens and communities to achieve the goal of the organization through decentralized decision-making. The process of carrying out this project itself is also the goal of contemplating, sharing, and working together on the true meaning of cultural heritage protection.";
        return desc;
    }

    function getAttrs(uint _tokenId) external view returns (string memory) {
        string[] memory genes  = getBaseGeneNames(_tokenId);
        string[9] memory parts;

        parts[0] = '[{"trait_type": "class", "value": "';
        parts[1] = genes[0];
        parts[2] = '"}, {"trait_type": "element", "value": "';
        parts[3] = genes[1];
        parts[4] = '"}, {"trait_type": "branch", "value": "';        
        parts[5] = genes[2];
        parts[6] = '"}, {"trait_type": "division", "value": "';        
        parts[7] = genes[3];
        parts[8] = '"}, {"trait_type": "generation", "value": "generation-0"}]';        

        string memory attrs = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        return attrs;
    }

    function getImg(uint _tokenId) external view returns (string memory) {
        string[] memory genes  = getBaseGeneNames(_tokenId);
        string[12] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 600 600">';
        parts[1] = '<style> .base {font-family: fantasy; fill: #3D2818; font-size:150%; letter-spacing: 0em;}</style>';
        parts[2] = '<image width="600" height="600" href="https://raw.githubusercontent.com/ntdao-org/ntdao-org.github.io/main/asset/NTD_NFT_bg_en.jpg"/>';
        parts[3] = '<text x="20%" y="420" dominant-baseline="middle" text-anchor="middle" class="base">';
        parts[4] = genes[0];
        parts[5] = '</text><text x="60%" y="420" dominant-baseline="middle" text-anchor="middle" class="base">';
        parts[6] = genes[1];
        parts[7] = '</text><text x="40%" y="470" dominant-baseline="middle" text-anchor="middle" class="base">';
        parts[8] = genes[2];
        parts[9] = '</text><text x="80%" y="470" dominant-baseline="middle" text-anchor="middle" class="base">';        
        parts[10] = genes[3];
        parts[11] = '</text></svg>';
        string memory attrs = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        attrs = string(abi.encodePacked(attrs, parts[9], parts[10], parts[11]));

        string memory img = string(abi.encodePacked('data:image/svg+xml;base64,',Base64.encode(bytes(attrs))));
        return img;
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}