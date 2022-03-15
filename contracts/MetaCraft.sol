// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Compile with optimizer on, otherwise exceeds size limit.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetaCraft is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    /**
     * @dev Mint Related
     * */

    string public ipfsGateway = "https://ipfs.metacraft.com/ipfs/";
    bool public mintEnabled = false;
    uint256 public totalMinted = 0;
    uint256 public mintSupplyCount;
    uint256 private ownerMintReserveCount;
    uint256 private ownerMintCount;
    uint256 private maxMintPerAddress;
    mapping(address => uint16) private addressMintCount;

    /**
     * @dev World Data
     */

    struct LandData {
        uint8[] features;
    }

    mapping(uint256 => int32) private tokenSeeds;
    mapping(uint256 => string) public tokenMetadataIPFSHashes;
    mapping(string => uint256) private ipfsHashTokenIds;
    mapping(uint256 => LandData) private tokenLandData;

    /**
     * @dev Contract Methods
     */

    constructor(
        uint256 _mintSupplyCount,
        uint256 _ownerMintReserveCount,
        uint256 _maxMintPerAddress
    ) ERC721("MetaCraft", "MetaCraft") {
        mintSupplyCount = _mintSupplyCount;
        ownerMintReserveCount = _ownerMintReserveCount;
        maxMintPerAddress = _maxMintPerAddress;
    }

    /************
     * Metadata *
     ************/

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(ipfsGateway, tokenMetadataIPFSHashes[_tokenId])
            );
    }

    function emergencySetIPFSGateway(string memory _ipfsGateway)
        external
        onlyOwner
    {
        ipfsGateway = _ipfsGateway;
    }

    function updateMetadataIPFSHash(
        uint256 _tokenId,
        string calldata _tokenMetadataIPFSHash
    ) external tokenExists(_tokenId) {
        require(
            _msgSender() == ownerOf(_tokenId),
            "You are not the owner of this token."
        );
        require(
            ipfsHashTokenIds[_tokenMetadataIPFSHash] == 0,
            "This IPFS hash has already been assigned."
        );

        tokenMetadataIPFSHashes[_tokenId] = _tokenMetadataIPFSHash;
        ipfsHashTokenIds[_tokenMetadataIPFSHash] = _tokenId;
    }

    function getSeed(uint256 _tokenId)
        external
        view
        tokenExists(_tokenId)
        returns (int32)
    {
        require(
            _msgSender() == ownerOf(_tokenId),
            "You are not the owner of this token."
        );

        return tokenSeeds[_tokenId];
    }

    modifier tokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), "This token does not exist.");
        _;
    }

    /********
     * Mint *
     ********/

    struct MintData {
        uint256 _tokenId;
        int32 _seed;
        LandData _LandData;
        string _tokenMetadataIPFSHash;
    }

    function mintWorld(
        MintData calldata _mintData,
        bytes calldata _signature // prevent alteration of intended mint data
    ) external nonReentrant {
        require(
            verifyOwnerSignature(keccak256(abi.encode(_mintData)), _signature),
            "Invalid Signature"
        );

        require(
            _mintData._tokenId > 0 && _mintData._tokenId <= mintSupplyCount,
            "Invalid token id."
        );
        require(mintEnabled, "Minting unavailable");
        require(totalMinted < mintSupplyCount, "All tokens minted");

        require(bytes(_mintData._tokenMetadataIPFSHash).length > 0, "No ipfs");

        if (_msgSender() != owner()) {
            require(
                addressMintCount[_msgSender()] < maxMintPerAddress,
                "You cannot mint more."
            );

            require(
                totalMinted + (ownerMintReserveCount - ownerMintCount) <
                    mintSupplyCount,
                "Available tokens minted"
            );
        } else {
            require(ownerMintCount < ownerMintReserveCount, "Owner mint limit");
        }

        tokenLandData[_mintData._tokenId] = _mintData._LandData;

        tokenMetadataIPFSHashes[_mintData._tokenId] = _mintData
            ._tokenMetadataIPFSHash;
        ipfsHashTokenIds[_mintData._tokenMetadataIPFSHash] = _mintData._tokenId;
        tokenSeeds[_mintData._tokenId] = _mintData._seed;

        addressMintCount[_msgSender()]++;
        totalMinted++;

        if (_msgSender() == owner()) {
            ownerMintCount++;
        }

        _safeMint(_msgSender(), _mintData._tokenId);
    }

    function setMintEnabled(bool _enabled) external onlyOwner {
        mintEnabled = _enabled;
    }

    /************
     * Security *
     ************/

    function verifyOwnerSignature(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return hash.toEthSignedMessageHash().recover(signature) == owner();
    }
}
