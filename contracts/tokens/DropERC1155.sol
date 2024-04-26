// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../structs/structs.sol";

// TODO move the heartbeat from here to the shop contract!!!

contract DroplinkedToken is ERC1155, Ownable{
    event MintEvent(uint tokenId, address recipient, uint amount, string uri);
    event ManageWalletUpdated(address newManagedWallet);
    event FeeUpdated(uint newFee);

    address operatorContract;
    uint public totalSupply;
    uint public fee;
    string public name = "Droplinked";
    string public symbol = "DROP";
    uint public tokenCnt;
    address public managedWallet = 0x8c906310C5F64fe338e27Bd9fEf845B286d0fc1e;
    mapping(address => bool) public minterAddresses; 
    mapping(uint => string) public uris;
    mapping(bytes32 => uint) public tokenIdByHash;
    mapping(uint => uint) public tokenCnts;
    mapping(uint256 => Issuer) public issuers;

    constructor(address _droplinkedOperator) ERC1155("") Ownable(tx.origin){
        fee = 100;
        operatorContract = _droplinkedOperator;
        minterAddresses[operatorContract] = true;
    }

    modifier onlyOperator(){
        require(msg.sender == operatorContract, "Only the operator can call this contract");
        _;
    }

    modifier onlyMinter() {
        require(minterAddresses[msg.sender], "Only Minters can call Mint Function");
        _;
    }

    function changeOperator(address _newOperatorContract) external onlyOperator() {
        operatorContract = _newOperatorContract;
    }

    function setMinter(address _minter, bool _state) external onlyOperator() {
        minterAddresses[_minter] = _state;
    }

    function getOwnerAmount(uint tokenId, address _owner) external view returns (uint){
        return balanceOf(_owner, tokenId);
    }

    function getTokenCnt() external view returns (uint){
        return tokenCnt;
    }

    function getTokenIdByHash(bytes32 metadataHash) external view returns (uint){
        return tokenIdByHash[metadataHash];
    }

    function getTokenAmount(uint tokenId) external view returns (uint){
        return tokenCnts[tokenId];
    }
    
    function getTotalSupply() external view returns (uint){
        return totalSupply;
    }

    function uri(uint tokenId) public view virtual override returns (string memory) {
        return uris[tokenId];
    }
    
    function getManagedWallet() external view returns (address){
        return managedWallet;
    }

    function setManagedWallet(address _newManagedWallet) external onlyOwner {
        managedWallet = _newManagedWallet;
        emit ManageWalletUpdated(_newManagedWallet);
    }

    function setFee(uint _fee) external onlyOperator {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function getFee() external view returns (uint){
        return fee;
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public virtual override {
        if(msg.sender != operatorContract){
            require(
                from == _msgSender() || isApprovedForAll(from, _msgSender()),
                "ERC1155: caller is not token owner or approved"
            );
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    function getIssuer(uint256 tokenId) external view returns(Issuer memory) {
        return issuers[tokenId];
    }

    function mint(
        string calldata _uri,
        uint amount,
        address receiver,
        uint256 royalty,
        bool accepted
    ) external onlyMinter() returns (uint){ 
        bytes32 metadata_hash = keccak256(abi.encode(_uri));
        uint tokenId = tokenIdByHash[metadata_hash];
        if (tokenId == 0) {
            tokenId = tokenCnt + 1;
            tokenCnt++;
            tokenIdByHash[metadata_hash] = tokenId;
            issuers[tokenId].issuer = receiver;
            issuers[tokenId].royalty = royalty;
        }
        totalSupply += amount;
        tokenCnts[tokenId] += amount;
        _mint(receiver, tokenId, amount, "");
        if (minterAddresses[msg.sender]) {
            _setApprovalForAll(receiver, msg.sender, true);
        }
        if(msg.sender == operatorContract){
            _setApprovalForAll(receiver, operatorContract, true);
            if (accepted) _setApprovalForAll(receiver, managedWallet, true);
        }
        uris[tokenId] = _uri;
        emit URI(_uri, tokenId);
        emit MintEvent(tokenId, tx.origin, amount, _uri);
        return tokenId;
    }

    function droplinkedSafeBatchTransferFrom(address from, address[] memory to, uint[] memory ids, uint[] memory amounts) external {
        for (uint i = 0; i < to.length; i++) {
            safeTransferFrom(from, to[i], ids[i], amounts[i], "");
        }
    }
}