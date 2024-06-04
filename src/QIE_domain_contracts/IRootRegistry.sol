// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import './Order.sol';

interface IRootRegistry {

   /* struct Order {
      address owner;
      string parent;
      string label ; 
      string zone;
    }*/

    struct Domain {
      string fqn;
      address zoneAddress;
      address owner;
      uint256 mintTime;
      uint256 tokenId;
  }
    
    function addZones(string memory zone, address tldAddress) external;
    function transferDomain(string memory label , address to, string memory zone) external;
    function burnDomain(string memory label, string memory zone) external;
    function domainList() external view returns(string[] memory, address[] memory);
    function updateOwner(string memory label, string memory zone) external;
    function modifyMinter(address minter_) external;
    function resolver(string memory label) external view returns(uint256, address);
    function transferDomain(address to_, uint tokenId_) external;
    function existingDomain(bytes32 tokenId_) external returns(bool);
    function mintDomain(Order.order memory order, bool isFree) external;
    function domainExist(string calldata domain_) external view returns(bool);
    function domainTransfer(address to_, uint tokenid_) external;
    function domainMetadata(uint tokenId) external returns(Domain memory);
     
}

