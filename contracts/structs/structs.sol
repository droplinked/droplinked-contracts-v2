// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum PaymentMethodType {
    NATIVE_TOKEN,
    USD,
    TOKEN
}

enum NFTType {
    ERC1155,
    ERC721
}

struct Beneficiary {
    bool isPercentage;
    uint256 value;
    address wallet;
}

struct PaymentInfo {
    uint256 price;
    address currencyAddress;
    uint256[] beneficiaries;
    PaymentMethodType paymentType;
}

struct Product {
    uint256 tokenId;
    address nftAddress;
    NFTType nftType;
    ProductType productType;
    PaymentInfo paymentInfo;
    uint256 affiliatePercentage;
}

struct AffiliateRequest {
    address publisher;
    uint256 productId;
    bool isConfirmed;
}

struct ShopInfo {
    string shopName;
    string shopAddress;
    string shopLogo;
    string shopDescription;
    address shopOwner;
}

enum ProductType {
    DIGITAL,
    POD,
    PHYSICAL
}

struct Coupon {
    bool isPercentage;
    uint value;
    uint secretHash;
    address couponProducer;
}

struct CouponProof {
    uint256[2] _pA;
    uint256[2][2] _pB;
    uint256[2] _pC;
    uint256[3] _pubSignals;
    bool provided;
}

struct Issuer {
    address issuer;
    uint royalty;
}

struct PurchaseData {
    uint id;
    uint amount;
    bool isAffiliate;
    address shopAddress;
}
