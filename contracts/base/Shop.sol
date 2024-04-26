// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { chainLink } from "../test/chainLink.sol";
import {IDIP1, ShopInfo, Product, AffiliateRequest, NFTType, ProductType, PaymentMethodType, PaymentInfo, PaymentMethodType, Issuer} from "../interfaces/IDIP1.sol";
import {BenficiaryManager, Beneficiary} from "./BeneficiaryManager.sol";
import { console } from "hardhat/console.sol";

interface Deployer {
    function getDroplinkedFee() external view returns (uint256);
    function getHeartBeat() external view returns (uint256);
    function droplinkedWallet() external view returns (address);
}

interface DroplinkedToken1155 {
    function mint(
        string calldata _uri,
        uint amount,
        address receiver,
        uint256 royalty,
        bool accepted
    ) external returns (uint);
    function issuers(uint256 tokenId) external view returns (Issuer memory);
}

contract DropShop is
    IDIP1,
    BenficiaryManager,
    Ownable,
    IERC721Receiver,
    IERC1155Receiver
{
    bool private receivedProduct;
    ShopInfo public _shopInfo;
    mapping(uint256 productId => Product product) public products;
    mapping(uint256 productId => mapping(address requester => bool))
        public isRequestSubmited;
    mapping(uint256 requestId => AffiliateRequest affiliateRequest)
        public affiliateRequests;
    uint256 public productCount;
    uint256 public affiliateRequestCount;
    Deployer public deployer;
    chainLink public priceFeed = new chainLink();
    // AggregatorV3Interface internal immutable priceFeed =
        // AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);


    modifier notRequested(uint256 productId, address requester) {
        if (isRequestSubmited[productId][requester])
            revert AlreadyRequested(requester, productId);
        _;
    }

    modifier requestExists(uint256 requestId) {
        if (affiliateRequests[requestId].publisher == address(0))
            revert RequestDoesntExist(requestId);
        _;
    }

    modifier isConfirmed(uint256 requestId) {
        if (affiliateRequests[requestId].isConfirmed == false)
            revert RequestNotConfirmed(requestId);
        _;
    }

    modifier notConfirmed(uint256 requestId) {
        if (affiliateRequests[requestId].isConfirmed == true)
            revert RequestAlreadyConfirmed(requestId);
        _;
    }

    modifier productExists(uint256 productId) {
        if (products[productId].nftAddress == address(0))
            revert ProductDoesntExist(productId);
        _;
    }

    modifier productDoesntExists(Product memory __product) {
        uint256 __productId = getProductId(__product);
        if (products[__productId].nftAddress != address(0))
            revert ProductExists(__productId);
        _;
    }

    constructor(
        string memory _shopName,
        string memory _shopAddress,
        address _shopOwner,
        string memory _shopLogo,
        string memory _shopDescription,
        address _deployer
    ) Ownable(_shopOwner) {
        _shopInfo.shopName = _shopName;
        _shopInfo.shopAddress = _shopAddress;
        _shopInfo.shopOwner = _shopOwner;
        _shopInfo.shopLogo = _shopLogo;
        _shopInfo.shopDescription = _shopDescription;
        deployer = Deployer(_deployer);
    }

    function constructProduct(
        uint256 _tokenId,
        address _nftAddress,
        uint256 _affiliatePercentage,
        uint256 _price,
        address _currencyAddress,
        NFTType _nftType,
        ProductType _productType,
        PaymentMethodType _paymentType,
        Beneficiary[] memory _beneficiaries
    ) private returns (Product memory) {
        uint[] memory _beneficiaryHashes = new uint[](_beneficiaries.length);
        for (uint i = 0; i < _beneficiaries.length; i++) {
            _beneficiaryHashes[i] = addBeneficiary(_beneficiaries[i]);
        }
        PaymentInfo memory paymentInfo = PaymentInfo(
            _price,
            _currencyAddress,
            _beneficiaryHashes,
            _paymentType
        );
        Product memory result = Product(
            _tokenId,
            _nftAddress,
            _nftType,
            _productType,
            paymentInfo,
            _affiliatePercentage
        );
        return result;
    }

    function getProductId(
        Product memory product
    ) public pure returns (uint256) {
        return
            uint256(keccak256(abi.encode(product.nftAddress, product.tokenId)));
    }

    function getProductIdV2(
        address nftAddress, uint256 tokenId
    ) public pure returns (uint256) {
        return
            uint256(keccak256(abi.encode(nftAddress, tokenId)));
    }

    function getShopName() external view returns (string memory) {
        return _shopInfo.shopName;
    }

    function getShopAddress() external view returns (string memory) {
        return _shopInfo.shopAddress;
    }

    function getShopOwner() external view returns (address) {
        return _shopInfo.shopOwner;
    }

    function getShopLogo() external view returns (string memory) {
        return _shopInfo.shopLogo;
    }

    function getShopDescription() external view returns (string memory) {
        return _shopInfo.shopDescription;
    }

    function getProduct(
        uint256 productId
    ) external view returns (Product memory) {
        return products[productId];
    }

    function getProductViaAffiliateId(
        uint256 affiliateId) external view returns (Product memory) {
        return products[affiliateRequests[affiliateId].productId];
    }

    function getProductCount() external view returns (uint256) {
        return productCount;
    }

    function getPaymentInfo(
        uint256 productId
    ) external view returns (PaymentInfo memory) {
        return products[productId].paymentInfo;
    }

    function mintAndRegister(
        address _nftAddress,
        string memory _uri,
        uint256 _amount,
        bool _accepted,
        uint256 _affiliatePercentage,
        uint256 _price,
        address _currencyAddress,
        uint256 _royalty,
        NFTType _nftType,
        ProductType _productType,
        PaymentMethodType _paymentType,
        Beneficiary[] memory _beneficiaries
    ) public onlyOwner returns (uint256 productId) {
        uint _tokenId = DroplinkedToken1155(_nftAddress).mint(
            _uri,
            _amount,
            msg.sender,
            _royalty,
            _accepted
        );

        // register the product
        return
            registerProduct(
                _tokenId,
                _nftAddress,
                _affiliatePercentage,
                _price,
                _currencyAddress,
                _nftType,
                _productType,
                _paymentType,
                _beneficiaries
            );
    }

    function registerProduct(
        uint256 _tokenId,
        address _nftAddress,
        uint256 _affiliatePercentage,
        uint256 _price,
        address _currencyAddress,
        NFTType _nftType,
        ProductType _productType,
        PaymentMethodType _paymentType,
        Beneficiary[] memory _beneficiaries
    ) public onlyOwner returns (uint256) {
        uint256 amount = 0;
        Product memory __product = constructProduct(
            _tokenId,
            _nftAddress,
            _affiliatePercentage,
            _price,
            _currencyAddress,
            _nftType,
            _productType,
            _paymentType,
            _beneficiaries
        );
        uint256 _productId = getProductId(__product);
        if (products[_productId].nftAddress != address(0)) {
            // Product exists, we just want to add more to it
            if (_nftType == NFTType.ERC721) {
                receivedProduct = false;
                amount = 1;
                IERC721(__product.nftAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _tokenId
                );
                if (!receivedProduct) revert("NFT not received");
            } else if (_nftType == NFTType.ERC1155) {
                receivedProduct = false;
                amount = IERC1155(__product.nftAddress).balanceOf(
                    msg.sender,
                    _tokenId
                );
                IERC1155(__product.nftAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _tokenId,
                    IERC1155(__product.nftAddress).balanceOf(
                        msg.sender,
                        _tokenId
                    ),
                    ""
                );
                if (!receivedProduct) revert("NFT not received");
            }
            emit ProductRegistered(_productId, amount, msg.sender);
            return _productId;
        }

        products[_productId] = __product;
        productCount++;
        if (_nftType == NFTType.ERC721) {
            amount = 1;
            receivedProduct = false;
            IERC721(__product.nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            if (!receivedProduct) revert("NFT not received");
        } else if (_nftType == NFTType.ERC1155) {
            receivedProduct = false;
            amount = IERC1155(__product.nftAddress).balanceOf(
                msg.sender,
                _tokenId
            );
            IERC1155(__product.nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                IERC1155(__product.nftAddress).balanceOf(msg.sender, _tokenId),
                ""
            );
            if (!receivedProduct) revert("NFT not received");
        }
        emit ProductRegistered(_productId, amount, msg.sender);
        return _productId;
    }

    function unregisterProduct(
        uint256 productId
    ) external productExists(productId) onlyOwner {
        Product memory product = products[productId];
        IERC721(product.nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            product.tokenId,
            ""
        );
        delete products[productId];
        emit ProductUnregistered(productId, msg.sender);
    }

    function requestAffiliate(
        uint256 productId
    )
        external
        productExists(productId)
        notRequested(productId, msg.sender)
        returns (uint256)
    {
        uint256 requestId = affiliateRequestCount;
        affiliateRequests[requestId] = AffiliateRequest(
            msg.sender,
            productId,
            false
        );
        isRequestSubmited[productId][msg.sender] = true;
        affiliateRequestCount += 1;
        emit AffiliateRequested(requestId, productId, msg.sender);
        return requestId;
    }

    function approveRequest(
        uint256 requestId
    )
        external
        productExists(affiliateRequests[requestId].productId)
        requestExists(requestId)
        notConfirmed(requestId)
        onlyOwner
    {
        affiliateRequests[requestId].isConfirmed = true;
        emit AffiliateRequestApproved(requestId, msg.sender);
    }

    function disapproveRequest(
        uint256 requestId
    ) external requestExists(requestId) isConfirmed(requestId) onlyOwner {
        affiliateRequests[requestId].isConfirmed = false;
        AffiliateRequest memory aftemp = affiliateRequests[requestId];
        isRequestSubmited[aftemp.productId][aftemp.publisher] = false;
        emit AffiliateRequestDisapproved(requestId, msg.sender);
    }

    function getAffiliate(
        uint256 requestId
    ) external view returns (AffiliateRequest memory) {
        return affiliateRequests[requestId];
    }

    function getAffiliateRequestCount() external view returns (uint256) {
        return affiliateRequestCount;
    }

    // TODO : complete the purchase logic--------------------------------------------------------------------

    function getLatestPrice(uint80 roundId) internal view returns (uint, uint) {
        (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
            roundId
        );
        return (uint(price), timestamp);
    }

    function paymentHelper(
        address from,
        address to,
        uint256 amount,
        Product memory product
    ) private {
        if (product.paymentInfo.paymentType == PaymentMethodType.USD || product.paymentInfo.paymentType == PaymentMethodType.NATIVE_TOKEN) {
            console.log(">amount: %s", amount);
            payable(to).transfer(amount);
            console.log(">Transfered to: %s", to);
        } else if (product.paymentInfo.paymentType == PaymentMethodType.TOKEN) {
            console.log(">amount: %s", amount);
            console.log(">spending from: %s", from);
            IERC20(product.paymentInfo.currencyAddress).transferFrom(from, to, amount);
            console.log(">Transfered to: %s", to);
        }
    }

    function toNativePrice(uint value, uint ratio) private pure returns (uint) {
        return (1e24 * value) / ratio;
    }

    function applyPercentage(
        uint value,
        uint percentage
    ) private pure returns (uint) {
        return (value * percentage) / 1e4;
    }

    function _payBeneficiaries(
        uint[] memory beneficiaries,
        uint _productETHPrice,
        uint amount,
        uint __producerShare,
        uint ratio,
        Product memory product
    ) private returns (uint) {
        for (uint j = 0; j < beneficiaries.length; j++) {
            Beneficiary memory _beneficiary = getBeneficiary(beneficiaries[j]);
            uint __beneficiaryShare = 0;
            if (_beneficiary.isPercentage) {
                __beneficiaryShare = applyPercentage(
                    _productETHPrice,
                    _beneficiary.value
                );
            } else {
                // value based beneficiary, convert to eth and transfer
                if (product.paymentInfo.paymentType == PaymentMethodType.USD) {
                    __beneficiaryShare = toNativePrice(_beneficiary.value, ratio);
                }
                else {
                    __beneficiaryShare = _beneficiary.value * amount;
                }
            }
            paymentHelper(
                msg.sender,
                _beneficiary.wallet,
                __beneficiaryShare,
                product
            );
            __producerShare -= __beneficiaryShare;
        }
        return __producerShare;
    }

    function purchaseProductFor(address receiver, uint256 id, bool isAffiliate, uint256 amount, uint80 roundId) public payable {
        console.log("provided: %s", msg.value);
        console.log("receiver: %s", receiver);
        console.log("id: %s", id);
        console.log("isAffiliate: %s", isAffiliate);
        console.log("amount: %s", amount);
        console.log("roundId: %s", roundId);
        address publisher = address(0);
        Product memory product;
        if (isAffiliate){
            product = products[affiliateRequests[id].productId];
            publisher = affiliateRequests[id].publisher;
        } else {
            product = products[id];
        }
        if (product.nftType == NFTType.ERC1155) {
            if (amount == 0) revert("Invalid amount");
            console.log("nftType: %s", "ERC1155");
            console.log("Product's nftAddress: %s", product.nftAddress);
            if (IERC1155(product.nftAddress).balanceOf(address(this), product.tokenId) < amount) revert NotEnoughTokens(product.tokenId, address(this));
            console.log("Transferring");
            IERC1155(product.nftAddress).safeTransferFrom(address(this), receiver, product.tokenId, amount, "");
            console.log("Transfer Done");
        } else {
            if (amount != 1) revert("Invalid amount");
            if (IERC721(product.nftAddress).ownerOf(product.tokenId) != address(this)) revert ShopDoesNotOwnToken(product.tokenId, product.nftAddress);
            IERC721(product.nftAddress).safeTransferFrom(address(this), receiver, product.tokenId, "");
        }
        console.log("Beginning...");
        uint256 finalPrice = product.paymentInfo.price;
        uint256 ratio = 0;
        uint256 fee = deployer.getDroplinkedFee();
        if (product.paymentInfo.paymentType == PaymentMethodType.USD) {
            uint256 timestamp;
            (ratio, timestamp) = getLatestPrice(roundId);
            if (ratio == 0) revert("Chainlink Contract not found");
            if (block.timestamp > timestamp && block.timestamp - timestamp > 2 * uint(deployer.getHeartBeat())) revert oldPrice();
            finalPrice = toNativePrice(product.paymentInfo.price, ratio);
        }
        finalPrice = finalPrice * amount;
        console.log("finalPrice: %s", finalPrice);
        console.log("ratio: %s", ratio);
        console.log("fee: %s", fee);
        console.log("publisher: %s", publisher);
        Issuer memory issuer = DroplinkedToken1155(product.nftAddress).issuers(product.tokenId);
        console.log("issuer: %s", issuer.issuer);
        console.log("royalty: %s", issuer.royalty);
        uint __royaltyShare = applyPercentage(finalPrice, issuer.royalty);
        console.log("royalty share: %s", __royaltyShare);
        uint __publisherShare = isAffiliate? applyPercentage(finalPrice, product.affiliatePercentage): 0;
        uint __producerShare = finalPrice;
        uint __droplinkedShare = applyPercentage(finalPrice, fee);
        console.log("droplinked share: %s", __droplinkedShare);
        console.log("Droplinked Wallet: %s", deployer.droplinkedWallet());
        paymentHelper(msg.sender, deployer.droplinkedWallet(), __droplinkedShare, product);
        console.log("Droplinked share paid");
        paymentHelper(msg.sender, issuer.issuer, __royaltyShare, product);
        console.log("Issuer share paid");
        if (isAffiliate){
            paymentHelper(msg.sender, publisher, __publisherShare, product);
            console.log("Publisher share paid");
        }
        __producerShare -= (__royaltyShare + __droplinkedShare + __publisherShare);
        uint[] memory beneficiaryHashes = product.paymentInfo.beneficiaries;
        console.log("Paying Beneficiaries");
        __producerShare = _payBeneficiaries(beneficiaryHashes, finalPrice, amount, __producerShare, ratio, product);
        console.log("beneficiary shares paid");
        console.log("producer share: %s", __producerShare);
        paymentHelper(msg.sender, owner(), __producerShare, product);
        console.log("Producer share paid");
    }

    function purchaseProduct(
        uint256 id,
        bool isAffiliate,
        uint256 amount,
        uint80 roundId
    ) public payable {
        purchaseProductFor(msg.sender, id, isAffiliate, amount, roundId);
    }
    // ------------------------------------------------------------------------------------------------------

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        receivedProduct = true;
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        receivedProduct = true;
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        revert("Shop does not support erc1155 batch transfer");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
