// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import './IMetadata.sol';
import './IZone.sol';



 contract RootRegistry is OwnableUpgradeable,UUPSUpgradeable {

    
    event domainMinted(uint indexed tokenId , string label, address owner);
    event uriSet(bytes32 indexed tokenId , string label, string uri);
    event ownerUpdated(string label, address updatedOwner);
    event domainTransferred(uint indexed tokenid_, address to_);
    event domainBurnt(uint indexed tokenId, string label);
    
    
    modifier onlyValidLabel(string memory label) {
    require(bytes(label).length > 1, "Registry:Min char 2");
    require(parentTokenId[label]!=1,"Registry:Domain not available");
    _;
  }

   
    struct Domain {
      string fqn;
      address zoneAddress;
      address owner;
      uint256 mintTime;
      uint256 tokenId;
  }

    struct Order {
      address owner;
      string parent;
      string label ; 
      string zone;
    }


    mapping(uint => bool) public existingDomain;
    mapping(string => address) private zones;
    mapping(uint => Domain) public domainMetadata;
    mapping(string => uint) public parentTokenId;
    mapping(address => string) public userDomain;
    string[] mintedDomainNames;
    address[] mintedDomainOwners;
    address minterAddress;
    address paymentAddress;
    address public metadataAddress;


    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function implementationAddress() external view returns (address){
        return _getImplementation();
    }

    
    function initialize(address minter_, address payment_, string[] memory zone_, address[] memory zoneAddress_) initializer public{
        __Ownable_init();
        __UUPSUpgradeable_init();
        _addZones(zone_, zoneAddress_);
        minterAddress = minter_;
        paymentAddress = payment_;
        }

    
    function addZones(string[] calldata zone_, address[] calldata zoneAddress_) onlyOwner external {
      _addZones(zone_,zoneAddress_);
       } 
    
    
    function mintDomain(Order calldata order, bool isFree)
    external onlyValidLabel(order.label)
    {
      require(msg.sender == paymentAddress || msg.sender == minterAddress,'Registry:Access denied');
      require(zones[order.zone] != address(0),'Registry:Zone not exist');
      require(bytes(userDomain[order.owner]).length == 0,'Registry:User domain minted');

      uint PTokenId = parentTokenId[order.parent];
      uint nameHash = uint(_namehash(order.label,order.parent));
      string memory fqn;
      address zoneAddress = zones[order.parent];
      if(zoneAddress == address(0)){
        require(order.owner == domainMetadata[PTokenId].owner,'Registry:Access denied');
        fqn = string(abi.encodePacked(order.label, ".", domainMetadata[PTokenId].fqn));
      }
      else{
        fqn = string(abi.encodePacked(order.label, ".", order.parent));
      }

      require(!_checkAvailable(zoneAddress,nameHash),'Registry:Domain already exists');
    
      Domain memory thisDomain = Domain(fqn, zoneAddress, order.owner, block.timestamp, nameHash);
      domainMetadata[nameHash] = thisDomain;
      parentTokenId[fqn] = nameHash;
      existingDomain[nameHash] = true;
      userDomain[order.owner] = fqn;

      mintedDomainNames.push(fqn);
      mintedDomainOwners.push(order.owner);

      IZone(zones[order.zone]).mint(order.owner,nameHash);
      IMetadata(metadataAddress).setDefault(nameHash,order.owner,isFree);
    
      emit domainMinted(nameHash,fqn, order.owner);
    }


    function domainTransfer(address to_, uint tokenid_) external {
      require(msg.sender == domainMetadata[tokenid_].zoneAddress, 'Registry:Access denied');
      require(bytes(userDomain[to_]).length == 0,'Registry:User domain minted');

      delete userDomain[domainMetadata[tokenid_].owner];
      domainMetadata[tokenid_].owner = to_;
      userDomain[to_] = domainMetadata[tokenid_].fqn;
      domainMetadata[tokenid_].mintTime = block.timestamp;

      mintedDomainNames.push(domainMetadata[tokenid_].fqn);
      mintedDomainOwners.push(to_);
      
      IMetadata(metadataAddress).clearMetadata(tokenid_);

      emit domainTransferred(tokenid_,to_);
    }


    function domainBurn(string calldata label_, string calldata zone_) external{ 
        uint _tokenId = parentTokenId[label_];
        require(msg.sender == domainMetadata[_tokenId].owner, 'Registry:Access Denied');

        delete userDomain[domainMetadata[_tokenId].owner];
        domainMetadata[_tokenId].owner = address(0);
        domainMetadata[_tokenId].mintTime = block.timestamp;
        parentTokenId[label_] = 1;

        IZone(zones[zone_]).burnDomain(_tokenId);
        IMetadata(metadataAddress).clearMetadata(_tokenId);
        emit domainBurnt(_tokenId, label_);
    }


    function domainList() external view onlyOwner returns(string[] memory, address[] memory){
        return (mintedDomainNames, mintedDomainOwners);
    }

    
    function domainInfo(string calldata label_) external view returns(Domain memory) {
        return(domainMetadata[parentTokenId[label_]]);
    }
   

    function resolver(string calldata label_) external view returns(uint256, address){
      uint _tokenId = parentTokenId[label_];
      return (_tokenId, domainMetadata[_tokenId].owner);
    }
    

    function domainExist(string memory domain_) public view returns(bool){
      uint _tokenId = parentTokenId[domain_];
      return existingDomain[_tokenId];
    }


    function domainNames(uint[] memory tokenId_) public view returns(string[] memory) {
        string[] memory _domainNames = new string[](tokenId_.length);
        for(uint i;i<tokenId_.length;++i){
            _domainNames[i] = domainMetadata[tokenId_[i]].fqn;
        }
        return _domainNames;
    }


    function updateMinter(address minter_) onlyOwner external {
      minterAddress = minter_;
    }


    function updatePayment(address payment_) onlyOwner external {
      paymentAddress = payment_;
    }

    function updateMetadata(address metadata_) onlyOwner external {
      metadataAddress = metadata_;
    }

  function _checkAvailable(address zone_, uint tokenId_) internal view returns(bool){
      if(existingDomain[tokenId_] || IZone(zone_).domainExists(tokenId_)){
        return true;
      }
      else return false;
    }
    
    function _addZones(string[] memory zone, address[] memory zoneAddress_) private {
      require(zone.length == zoneAddress_.length,'Registry:invalid input');
      uint length = zone.length;
      
      for(uint i;i<length;++i){
      uint tokenID = uint(_namehash(zone[i],'0'));
      zones[zone[i]] = zoneAddress_[i];
      parentTokenId[zone[i]] = tokenID;
      existingDomain[tokenID] = true;
      }
    }

    function _namehash(string memory label, string memory parent) private pure returns(bytes32){
        return keccak256(abi.encodePacked(parent, label));
    }
 
 }