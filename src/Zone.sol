// SPDX-License-Identifier: MIT

/* 
The mint function requries the caller to be a regisrty address 
only the owner of the token or the owner of the contract can call for auctioning the token (domain auction function )
only the regirty contracts can burn the domaian 
*/
pragma solidity ^0.8.3;

import './ERC721Enumerable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import './IZone.sol';


 contract Zone is ERC721Enumerable{

    using Strings for uint256;

    event UpdatedURI(string uri);
    event ownerModified(address owner);
    event Auction(string domain, bool val);

    string public uri;
    mapping(uint => bool) public onAuction;
    address gateway;
    
    modifier onlyRegistry{
        require(registry[msg.sender]=true,'Zone:Access Denied!'); // @audit High the = is not a comparisn operator that is used in the check , this will make the check ffail 
        // and make some other random address in the registery 
        _;
    }


    constructor(string memory name_, string memory symbol_, string memory uri_) ERC721(name_, symbol_){
        uri = uri_;
        _owner = msg.sender;
    }



    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }


    function setURI(string memory uri_) external onlyOwner {
        uri = uri_;

        emit UpdatedURI(uri_);
    }


    function mint(address to, uint256 tokenId) external onlyRegistry {
        registryAddress[tokenId] = msg.sender; 
        _safeMint(to, tokenId);
    }



    function domainExists(uint256 tokenId_) external view  returns (bool){
        return _exists(tokenId_);
    }

    function domainExistsByName(string memory label, string memory parent) external view returns (bool){ // @audit GO use calldata instead of memory 
        uint _tokenId = _namehash(label,parent);
        return _exists(_tokenId);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function domainOwner(uint256 tokenId) external view  returns (address){
        return (ownerOf(tokenId));
    }

    function domainOwnerByName(string memory label, string memory parent) external view  returns (address){
        uint _tokenId = _namehash(label,parent);
        return (ownerOf(_tokenId));
    }

    function transferDomain(address  from, address  to, uint256 tokenId) external {
        require(!onAuction[tokenId],'Zone:on auction');
        safeTransferFrom(from , to , tokenId);
    }

    function transferDomainByName(address  from, address  to, string memory label, string memory parent) external {
        uint _tokenId = _namehash(label,parent);
        //@audit msg.sender  == paymentAddress check is not added in this 
        require(!onAuction[_tokenId],'Zone:on auction');
        safeTransferFrom(from , to , _tokenId);
    }

    function transferDomainByAuction(address from , address to, uint256 tokenId) external {
        // @audit onAuction is true is not checked in this function , this can lead to tranferring of unauctioned tokens 
        require(msg.sender == paymentAddress,'Zone:access denied');
        onAuction[tokenId] = false;
        safeTransferFrom(from , to , tokenId);
    }
    

    function burnDomain(uint256 tokenId) external onlyRegistry {
        require(!onAuction[tokenId],'Zone:on auction');
        _burn(tokenId);
    }

    function domainAuction(string memory label_, string memory parent_, bool val_) external{
      uint _tokenId = _namehash(label_,parent_);
      // @audit can cache msg.sender for decreasing the gas cost 
      require(msg.sender == ownerOf(_tokenId) || msg.sender == _owner, 'Zone:Access Denied');
      onAuction[_tokenId] = val_;
      emit Auction(label_,val_);
    }

    function modifyOwner(address newOwner) external onlyOwner{
        _owner = newOwner; // @audit no null address check for the newOwner address 
        emit ownerModified(newOwner);
    }

    function _namehash(string memory label, string memory parent) private pure returns(uint){
        return uint(keccak256(abi.encodePacked(parent, label)));
    }

    }