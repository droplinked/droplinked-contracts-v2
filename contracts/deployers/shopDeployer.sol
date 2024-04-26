// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IDIP1.sol";
import "../tokens/DropERC1155.sol";
import "../base/IDropShop.sol";

/**
 * @title DropShopDeployer
 * @dev Contract for deploying and managing drop shops and NFT contracts.
 */
contract DropShopDeployer is Initializable, OwnableUpgradeable {
    event ShopDeployed(address shop, address nftContract);
    event DroplinkedFeeUpdated(uint256 newFee);
    event HeartBeatUpdated(uint256 newHeartBeat);

    IDropShop[] public shopAddresses;
    address[] public nftContracts;
    mapping(address shopOwner => address[] shops) public shopOwners;
    mapping(address shopOwner => address[] nftContracts) public nftOwners;
    uint256 public droplinkedFee;
    uint256 public heartBeat;
    address public droplinkedWallet;
    uint public shopCount;

    function initialize(uint256 _heartBeat, address _droplinkedWallet, uint256 _droplinkedFee) public initializer {
        __Ownable_init(msg.sender);
        heartBeat = _heartBeat;
        droplinkedWallet = _droplinkedWallet;
        droplinkedFee = _droplinkedFee;
    }

    function setDroplinkedFee(uint256 newFee) external onlyOwner {
        droplinkedFee = newFee;
        emit DroplinkedFeeUpdated(newFee);
    }

    function setHeartBeat(uint256 newHeartBeat) external onlyOwner {
        heartBeat = newHeartBeat;
        emit HeartBeatUpdated(newHeartBeat);
    }

    function deployShop(
        bytes memory bytecode, bytes32 salt
    ) external onlyOwner returns (address shop, address nftContract) {
        address deployedShop;
        IDropShop _shop;
        assembly {
            deployedShop := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(deployedShop)) {
                revert(0, 0)
            }
        }
        _shop = IDropShop(deployedShop);
        DroplinkedToken token = new DroplinkedToken(address(this));
        shopOwners[msg.sender].push(deployedShop);
        nftOwners[msg.sender].push(address(token));
        nftContracts.push(address(token));
        shopAddresses.push(_shop);
        token.setMinter(deployedShop, true);
        ++shopCount;
        emit ShopDeployed(deployedShop, address(token));
        return (deployedShop, address(token));
    }

    function getDroplinkedFee() external view returns (uint256) {
        return droplinkedFee;
    }

    function getHeartBeat() external view returns (uint256) {
        return heartBeat;
    }
}
