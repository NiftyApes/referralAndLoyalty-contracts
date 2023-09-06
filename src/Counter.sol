// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712Upgradeable.sol";

contract referralAndLoyalty {
    struct Listing {
        uint256 price;
        uint256 referralFee;
        uint256 expiration;
    }

    function getListingHash(
        Listing memory listing
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _LISTING_TYPEHASH,
                        listing.price,
                        listing.referralFee,
                        listing.expiration
                    )
                )
            );
    }

    function getReferralCodeHash(
        Listing memory listing
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _REFERRALCODE_TYPEHASH,
                        listing.price,
                        listing.referralFee,
                        listing.expiration
                    )
                )
            );
    }

    function createListing() public {}

    function createReferralCode() public {}

    function buy() public {}

    function buyWithReferralCode() public {}
}
