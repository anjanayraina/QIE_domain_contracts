//add events
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import './IRootRegistry.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Metadata is OwnableUpgradeable,UUPSUpgradeable {
    mapping(uint256 => mapping(string => address)) private addressDetails;
    string[] public supportedCurrency; 
    mapping(string => bool) public validCurrency;
    address private registryAddress;
    string[] public supportedMetadata; 
    mapping(string => bool) public validMetadata;
    mapping(uint256 => mapping(string => string)) private metadata;
    mapping(uint => uint) public free;
    mapping(uint => bool) public isPaid;
    mapping(address => uint) public phone;
    address private paymentAddress;
    uint public validity;

    modifier onlyRegistry {
        require(msg.sender == registryAddress, "Metadata:Access denied");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function implementationAddress() external view returns (address){
        return _getImplementation();
    }

    function initialize(address registryAddress_, address paymentAddress_, uint validity_) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        registryAddress = registryAddress_;
        paymentAddress = paymentAddress_;
        validity = validity_;
    }

    function validateCurrencies(string[] calldata currencies) external onlyOwner { // @audit it can have duplicate currencies, have a check for that as well 
        for (uint i = 0; i < currencies.length; ++i) { // @audit GO for loop can be optimized 
            if (!validCurrency[currencies[i]]) { // @audit if the currency is valid then 
                supportedCurrency.push(currencies[i]);
                validCurrency[currencies[i]] = true;
            }
        }
    }

    function validateMetadata(string[] calldata keys) external onlyOwner {
        for (uint i = 0; i < keys.length; ++i) {
            if (!validMetadata[keys[i]]) {
                supportedMetadata.push(keys[i]);
                validMetadata[keys[i]] = true;
            }
        }
    }

    function addAddress(string calldata label, string[] calldata currency, address[] calldata currencyAddress) external {
        require(currency.length == currencyAddress.length, "Metadata:Wrong input");
        (uint256 tokenId, address owner) = IRootRegistry(registryAddress).resolver(label);
        require(msg.sender == owner, "Metadata:Access denied");
        for (uint i = 0; i < currency.length; ++i) {
            require(validCurrency[currency[i]], "Metadata:Invalid currency");
            addressDetails[tokenId][currency[i]] = currencyAddress[i];
        }
    }

    function addMetadata(string calldata domain, string[] calldata keys, string[] calldata values) external {
        require(keys.length == values.length, "Metadata:Invalid input");
        (uint256 tokenId, address domainOwner) = IRootRegistry(registryAddress).resolver(domain);
        require(msg.sender == owner() || msg.sender == domainOwner, "Metadata:Access denied");
        for (uint i = 0; i < keys.length; ++i) {
            require(validMetadata[keys[i]], "Metadata:Invalid key");
            metadata[tokenId][keys[i]] = values[i];
        }
    }

    function addPhone(address owner_, uint phone_) external {
        require(msg.sender == owner() || msg.sender == owner_, "Metadata:Access denied");
        phone[owner_] = phone_;
    }

      function resolveCurrency(string calldata domain_ ,string calldata currency_) external view returns(address ){      
      ( uint256 tokenId, ) = IRootRegistry(registryAddress).resolver(domain_);  
      if(!isPaid[tokenId]){
        require(block.timestamp < free[tokenId] + validity,'Metadata:domain expired');
      }
      return addressDetails[tokenId][currency_];
      }

    function resolveMetadata(string calldata domain_, string calldata key_) external view returns(string memory){
        ( uint256 tokenId, ) = IRootRegistry(registryAddress).resolver(domain_);
        if(!isPaid[tokenId]){
            require(block.timestamp < free[tokenId] + validity,'Metadata:domain expired');
        }       
        return metadata[tokenId][key_];
    }
    
    function clearMetadata(uint256 tokenId_) external onlyRegistry {
        string[] memory _supportedCurrency = supportedCurrency;
        uint _clength = _supportedCurrency.length;
        string[] memory _supportedMetadata = supportedMetadata;
        uint _mlength = _supportedMetadata.length;

        for(uint i; i<_clength;++i){
            delete addressDetails[tokenId_][_supportedCurrency[i]];
        }

        for(uint j;j<_mlength;++j){
            delete addressDetails[tokenId_][_supportedMetadata[j]];
        }
    }

    function setDefault(uint256 tokenID_, address currencyAddress_, bool isFree_) onlyRegistry external {
        addressDetails[tokenID_]['qie'] = currencyAddress_;
        if(isFree_){
            free[tokenID_] = block.timestamp;
        }
        else isPaid[tokenID_] = true;
        }

    function paid(uint tokenId_) external {
        require(msg.sender == paymentAddress,'Metadata:access denied');
        isPaid[tokenId_] = true;
    }

    function updateRegistry(address registryAddress_) external onlyOwner{
        registryAddress = registryAddress_;
    }

    function updatePayment(address paymentAddress_) external onlyOwner{
        paymentAddress = paymentAddress_;
    }

    function updateValidity(uint validity_) external onlyOwner{
        validity = validity_;
    }

}

