// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IZone {
    
    function mint(address account, uint256 id) external;
    function transferDomain(address from, address to, uint256 token_id) external;
    function burnDomain(uint256 token_id) external;
    function baseURI() external view returns (string memory);
    function setURI(string memory uri_) external ;
    function domainExists(uint256 tokenId) external view returns (bool);
    function domainURI(uint256 tokenId) external view returns (string memory);
    function domainOwner(uint256 tokenId) external returns (address);
    function transferDomainByAuction(address from , address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;

}