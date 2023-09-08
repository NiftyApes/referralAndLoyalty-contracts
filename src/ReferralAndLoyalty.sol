// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract ReferralAndLoyalty is EIP712 {
    using Address for address payable;

    /******* STRUCTS ******/

    struct Listing {
        address nftContractAddress;
        uint256 nftId;
        uint256 price;
        uint256 referralFee;
        uint256 expiration;
    }

    struct ReferralCode {
        bytes listingSignature;
    }

    /******* EVENTS ******/

    event ListingSignatureUsed(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        Listing Listing,
        bytes signature
    );

    event SaleExecuted(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        Listing Listing,
        bytes listingSignature,
        address referralRecipient
    );

    /******* ERRORS ******/

    error SignatureNotAvailable(bytes signature);

    error InvalidSigner(address signer, address expected);

    error InvalidReferralCode(bytes given, bytes expected);

    error ReferrerNotCollector();

    error InsufficientMsgValue(
        uint256 msgValueSent,
        uint256 minMsgValueExpected
    );

    error NotNftOwner(
        address nftContractAddress,
        uint256 nftId,
        address account
    );

    error ListingExpired();

    /******* STATE VARIABLES ******/

    bytes32 private constant _LISTING_TYPEHASH =
        keccak256(
            "Listing(address nftContractAddress,uint256 nftId,uint256 price,uint256 referralFee,uint256 expiration)"
        );

    bytes32 private constant _REFERRAL_CODE_TYPEHASH =
        keccak256("referralCode(bytes listingSignature)");

    mapping(bytes => bool) private _cancelledOrFinalized;

    /******* FUNCTIONS ******/

    constructor() EIP712("referralAndLoyalty", "0.0.1") {}

    function getListingHash(
        Listing memory listing
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _LISTING_TYPEHASH,
                        listing.nftContractAddress,
                        listing.nftId,
                        listing.price,
                        listing.referralFee,
                        listing.expiration
                    )
                )
            );
    }

    function getReferralCodeHash(
        ReferralCode memory referralCode
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _REFERRAL_CODE_TYPEHASH,
                        referralCode.listingSignature
                    )
                )
            );
    }

    function getListingSigner(
        Listing memory listing,
        bytes memory listingSignature
    ) public view returns (address) {
        return ECDSA.recover(getListingHash(listing), listingSignature);
    }

    function getReferralCodeSigner(
        ReferralCode memory referralCode,
        bytes memory referralCodeSignature
    ) public view returns (address) {
        return
            ECDSA.recover(
                getReferralCodeHash(referralCode),
                referralCodeSignature
            );
    }

    function buy(
        Listing memory listing,
        bytes calldata listingSignature,
        ReferralCode calldata referralCode,
        bytes calldata referralCodeSignature
    ) external payable {
        address seller = getListingSigner(listing, listingSignature);

        _requireAvailableSignature(listingSignature);
        _require721Owner(listing.nftContractAddress, listing.nftId, seller);
        _requireOfferNotExpired(listing);
        _requireSufficientMsgValue(msg.value, listing.price);

        address referralAddress;
        uint256 referralFee;

        // if referralCodeSignature is provided
        if (referralCodeSignature.length != 0) {
            address referralSigner = getReferralCodeSigner(
                referralCode,
                referralCodeSignature
            );

            _requireCorrectListing(
                referralCode.listingSignature,
                listingSignature
            );
            _requireReferrerIsCollector(
                listing.nftContractAddress,
                referralSigner
            );

            referralAddress = referralSigner;
            referralFee = listing.referralFee;
        }

        // if msg.value is too high, return excess value
        if (msg.value > listing.price) {
            payable(msg.sender).sendValue(msg.value - listing.price);
        }

        // payout seller
        payable(seller).sendValue(listing.price - referralFee);

        // payout referral
        if (referralAddress != address(0)) {
            payable(referralAddress).sendValue(referralFee);
        }

        _transferNft(
            listing.nftContractAddress,
            listing.nftId,
            seller,
            msg.sender
        );

        _markSignatureUsed(listing, listingSignature);

        emit SaleExecuted(
            listing.nftContractAddress,
            listing.nftId,
            listing,
            listingSignature,
            referralAddress
        );
    }

    function withdrawListingSignature(
        Listing memory listing,
        bytes memory signature
    ) external {
        _requireAvailableSignature(signature);
        address signer = getListingSigner(listing, signature);
        _requireSigner(signer, msg.sender);
        _markSignatureUsed(listing, signature);
    }

    function _transferNft(
        address nftContractAddress,
        uint256 nftId,
        address from,
        address to
    ) internal {
        IERC721(nftContractAddress).safeTransferFrom(from, to, nftId);
    }

    function _markSignatureUsed(
        Listing memory listing,
        bytes memory signature
    ) internal {
        _cancelledOrFinalized[signature] = true;

        emit ListingSignatureUsed(
            listing.nftContractAddress,
            listing.nftId,
            listing,
            signature
        );
    }

    function _requireAvailableSignature(bytes memory signature) private view {
        if (_cancelledOrFinalized[signature]) {
            revert SignatureNotAvailable(signature);
        }
    }

    function _require721Owner(
        address nftContractAddress,
        uint256 nftId,
        address nftOwner
    ) internal view {
        if (IERC721(nftContractAddress).ownerOf(nftId) != nftOwner) {
            revert NotNftOwner(nftContractAddress, nftId, nftOwner);
        }
    }

    function _requireOfferNotExpired(Listing memory listing) internal view {
        if (listing.expiration <= block.timestamp) {
            revert ListingExpired();
        }
    }

    function _requireSufficientMsgValue(
        uint256 msgValue,
        uint256 price
    ) private pure {
        if (msgValue < price) {
            revert InsufficientMsgValue(msgValue, price);
        }
    }

    function _requireCorrectListing(
        bytes memory given,
        bytes memory expected
    ) private pure {
        if (keccak256(given) != keccak256(expected)) {
            revert InvalidReferralCode(given, expected);
        }
    }

    function _requireReferrerIsCollector(
        address nftContractAddress,
        address referrer
    ) private view {
        if (IERC721(nftContractAddress).balanceOf(referrer) == 0) {
            revert ReferrerNotCollector();
        }
    }

    function _requireSigner(address signer, address expected) internal pure {
        if (signer != expected) {
            revert InvalidSigner(signer, expected);
        }
    }
}
