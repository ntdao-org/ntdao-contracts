// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/**
 * @title Natioanl Treasure DAO(NTDAO) NFT Contract
 * @author Atomrigs Lab 
 */

interface INFTGene {
    function getSeed(uint _tokenId) external view returns (uint);
    function getBaseGenes(uint _tokenId) external view returns (uint[] memory);
    function getBaseGeneNames(uint _tokenId) external view returns (string[] memory);
    function getImgIdx(uint _tokenId) external view returns (string memory);
    function getDescription() external view returns (string memory);
    function getAttrs(uint _tokenId) external view returns (string memory);
    function getImg(uint _tokenId) external view returns (string memory);
}

contract NTDaoNft is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum State {
        Setup,
        PublicMint,
        Refund,
        Finished
    }

    State public state;
    address private _geneAddr;
    bool public isPermanent;
    uint8 public constant MAX_PUBLIC_MULTI = 20;
    uint16 public constant MAX_PUBLIC_ID = 20000;
    uint public MINTING_FEE = 300 * 10**18; //in wei
    uint public notRefundCount;

    mapping(uint => bool) public refunds; //token_id => bool

    event Received(address caller, uint amount, string message);
    event BalanceWithdraw(address recipient, uint amount);
    event StateChanged(State _state);
    event Refunded(address indexed to, uint indexed tokenId, uint amount);

    constructor() ERC721("National Treasure DAO NFT", "NTDAO-NFT") Ownable() {
        state = State.Setup;
    }

    fallback() external payable {
        emit Received(_msgSender(), msg.value, "Fallback was called");
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value, "Fallback was called");
    }    


    function updateMintingFee(uint _feeAmount) external onlyOwner { //in wei unit
        MINTING_FEE = _feeAmount;
    }    

    function updateGene(address geneContract_) external onlyOwner {
        require(!isPermanent, "NTDAO-NFT: Gene contract is fixed");
        _geneAddr = geneContract_;
    }

    function changeToPermanent() external onlyOwner {
        isPermanent = true;
    }

    function setStateToSetup() public onlyOwner {
        state = State.Setup;
    }
    
    function setStateToPublicMint() public onlyOwner {
        state = State.PublicMint;
    }

    function setStateToRefund() public onlyOwner {
        state = State.Refund;
    }
    
    function setStateToFinished() public onlyOwner {
        state = State.Finished;
    }

    function safeMint(address _to, uint _tokenId) private returns (bool) {
        _safeMint(_to, _tokenId);
        return true;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    } 

    function withdraw(address payable _to, uint _amount) external onlyOwner { 
        require(_amount <= address(this).balance);
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send coin");
        emit BalanceWithdraw(_to, _amount);
    }    

    function publicMint(uint _count) external payable nonReentrant {

        require(state == State.PublicMint, "NTDAO-NFT: State is not in PublicMint");
        require(_count <= MAX_PUBLIC_MULTI, "NTDAO-NFT: Minting count exceeds more than allowed");
        require(_tokenIds.current() + _count <= MAX_PUBLIC_ID, "NTDAO-NFT: Can not mint more than MAX_PUBLIC_ID");
        require(MINTING_FEE * _count == msg.value, "NTDAO-NFT: Minting fee amounts does not match."); 

        for(uint i=0; i<_count; i++) {
            _tokenIds.increment();
            notRefundCount += 1;
            require(safeMint(_msgSender(), _tokenIds.current()), "NTDAO-NFT: minting failed");
        }
    }

    function refund(uint[] calldata tokenIds_) external nonReentrant {
        require(state == State.Refund, "NTDAO-NFT: State is not in Refund");
        address _to = payable(_msgSender());
        uint refundAmount = address(this).balance / notRefundCount;
        for(uint i=0; i<tokenIds_.length; i++) {
            require(refunds[tokenIds_[i]] == false, "NTDAO-NFT: The tokendId is already refunded");
            require(ownerOf(tokenIds_[i]) == _to, "NTDAO-NFT: The token owner is different");
            refunds[tokenIds_[i]] = true;
            notRefundCount -= 1;
            (bool success, ) = _to.call{value: refundAmount}("");
            require(success, "NTDAO-NFT: Failed to send coin");
            emit Refunded(_to, tokenIds_[i], refundAmount);         
        }
    }

    function transferBatch(uint[] calldata tokenIds_, address _to) external nonReentrant {
        for(uint i=0; i<tokenIds_.length; i++) {
            safeTransferFrom(_msgSender(), _to, tokenIds_[i]);
        }
    }

    function getSeed(uint _tokenId) public view returns (uint) {
        require(_exists(_tokenId), "NTDAO-NFT: TokenId not minted yet");
        INFTGene gene = INFTGene(_geneAddr);
        return gene.getSeed(_tokenId);
    }

    function getBaseGenes(uint _tokenId) public view returns (uint[] memory) {
        require(_exists(_tokenId), "NTDAO-NFT: TokenId not minted yet");
        INFTGene gene = INFTGene(_geneAddr);
        return gene.getBaseGenes(_tokenId);        
    }

    function getBaseGeneNames(uint _tokenId) public view returns (string[] memory) {
        require(_exists(_tokenId), "NTDAO-NFT: TokenId not minted yet");
        INFTGene gene = INFTGene(_geneAddr);
        return gene.getBaseGeneNames(_tokenId);        
    }

    function tokensOf(address _account) public view returns (uint[] memory) {
        uint[] memory tokenIds = new uint[] (balanceOf(_account));
        for (uint i; i<balanceOf(_account); i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_account, i);
        }
        return tokenIds;
    }

    function getAttrs(uint _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NTDAO-NFT: TokenId not minted yet");
        INFTGene gene = INFTGene(_geneAddr);
        return gene.getAttrs(_tokenId);
    }

    function getDescription() internal view returns (string memory) {
        INFTGene gene = INFTGene(_geneAddr);
        return gene.getDescription();
    }

    function getImg(uint _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NTDAO-NFT: TokenId not minted yet");
        INFTGene gene = INFTGene(_geneAddr);
        return gene.getImg(_tokenId);
    }
   
    function tokenURI(uint _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "NTDAO-NFT: TokenId not minted yet");
        string memory attrs = getAttrs(_tokenId);
        string memory img = getImg(_tokenId); 
        string memory description = getDescription();
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "National Treasure DAO NFT #', toString(_tokenId), '", "attributes": ', attrs,', "description": "', description, '", "image": "', img, '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function getMintingState() external view returns (uint8) {
        if (state == State.Setup) {
            return 0;
        } else if (state == State.PublicMint && _tokenIds.current() < MAX_PUBLIC_ID ) {
            return 1;
        } else if (state == State.Refund) {
            return 2;
        } else {
            return 3;
        }
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