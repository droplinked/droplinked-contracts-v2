// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../structs/structs.sol";

interface IDIP1 {
    error AlreadyRequested(address requester, uint256 productId);
    error RequestDoesntExist(uint256 requestId);
    error RequestNotConfirmed(uint256 requestId);
    error RequestAlreadyConfirmed(uint256 requestId);
    error ProductDoesntExist(uint256 productId);
    error ProductExists(uint256 productId);
    error oldPrice();
    error AffiliatePOD();
    error NotEnoughTokens(uint256 tokenId, address producer);
    error ShopDoesNotOwnToken(uint256 tokenId, address nftAddress);

    event ProductRegistered(
        uint256 indexed productId,
        uint256 amount,
        address indexed owner
    );
    event ProductUnregistered(uint256 indexed productId, address indexed owner);
    event AffiliateRequested(
        uint256 indexed requestId,
        uint256 indexed productId,
        address requester
    );
    event AffiliateRequestApproved(
        uint256 indexed requestId,
        address indexed approver
    );
    event AffiliateRequestDisapproved(
        uint256 indexed requestId,
        address indexed disapprover
    );
    event ProductPurchased(
        uint256 indexed productId,
        address indexed buyer,
        uint256 amount
    );
    event AffiliatePurchase(
        uint256 indexed requestId,
        address indexed buyer,
        uint256 amount
    );

    function getShopName() external view returns (string memory);
    function getShopAddress() external view returns (string memory);
    function getShopOwner() external view returns (address);
    function getShopLogo() external view returns (string memory);
    function getShopDescription() external view returns (string memory);
    function mintAndRegister(
        address _nftAddress,
        string memory _uri,
        uint256 amount,
        bool accepted,
        uint256 _affiliatePercentage,
        uint256 _price,
        address _currencyAddress,
        uint256 _royalty,
        NFTType _nftType,
        ProductType _productType,
        PaymentMethodType _paymentType,
        Beneficiary[] memory _beneficiaries
    ) external returns (uint256 productId);
    function getProduct(
        uint256 productId
    ) external view returns (Product memory);
    function getProductCount() external view returns (uint256);
    function getProductId(
        Product memory product
    ) external pure returns (uint256);
    function getPaymentInfo(
        uint256 productId
    ) external view returns (PaymentInfo memory);
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
    ) external returns (uint256);
    function unregisterProduct(uint256 productId) external;
    function requestAffiliate(uint256 productId) external returns (uint256);
    function approveRequest(uint256 requestId) external;
    function disapproveRequest(uint256 requestId) external;
    function getAffiliate(
        uint256 requestId
    ) external view returns (AffiliateRequest memory);
    function getAffiliateRequestCount() external view returns (uint256);
    function purchaseProductFor(
        address receiver,
        uint256 id,
        bool isAffiliate,
        uint256 amount,
        uint80 roundId
    ) external payable;
    function purchaseProduct(
        uint256 id,
        bool isAffiliate,
        uint256 amount,
        uint80 roundId
    ) external payable;
}
