// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IMetadata {

    function addAddress(string memory label,string[] calldata currency, address[] calldata addresses) external;
    function addressInfo(string memory label ,string[] calldata currency) external returns  (address[] memory );
    function clearMetadata(uint256 tokenId) external;
    function setDefault(uint256 tokenID_, address currencyAddress_, bool isFalse) external;
    function paid(uint tokenId_) external;

}