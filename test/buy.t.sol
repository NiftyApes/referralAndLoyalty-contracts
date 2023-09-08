// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./common/BaseTest.sol";
import "./common/Console.sol";

import "./utils/ReferralAndLoyaltyDeployment.sol";
import "../src/ReferralAndLoyalty.sol";

contract TestBuy is
    Test,
    BaseTest,
    ReferralAndLoyaltyDeployment,
    ReferralAndLoyalty
{
    address nftContractAddress = address(boredApeYachtClub);
    uint256 nftId = 8661;
    uint256 SIGNER_PRIVATE_KEY_1 =
        0x60b919c82f0b4791a5b7c6a7275970ace1748759ebdaa4076d7eeed9dbcff3c3;
    address SIGNER_1 = 0x503408564C50b43208529faEf9bdf9794c015d52;

    function setUp() public override {
        super.setUp();
    }

    function test_buy_with_referralCode(
        uint256 price,
        uint256 referralFee
    ) public {
        vm.assume(price < defaultInitialEthBalance);
        vm.assume(price > referralFee);

        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: price,
            referralFee: referralFee,
            expiration: block.timestamp + 1
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory listingSignature = sign(seller1_private_key, listingHash);

        ReferralCode memory referralCode = ReferralCode(listingSignature);

        bytes32 referralCodeHash = referralAndLoyalty.getReferralCodeHash(
            referralCode
        );

        bytes memory referralCodeSignature = sign(
            buyer1_private_key,
            referralCodeHash
        );

        vm.startPrank(seller1);
        boredApeYachtClub.approve(address(referralAndLoyalty), nftId);
        vm.stopPrank();

        uint256 sellerBalanceBefore = address(seller1).balance;
        uint256 buyer1BalanceBefore = address(buyer1).balance;

        vm.startPrank(buyer2);
        referralAndLoyalty.buy{value: listing.price}(
            listing,
            listingSignature,
            referralCode,
            referralCodeSignature
        );
        vm.stopPrank();

        // buyer is the owner of the nft after the sale
        assertEq(boredApeYachtClub.ownerOf(nftId), buyer2);

        uint256 sellerBalanceAfter = address(seller1).balance;
        uint256 buyer1BalanceAfter = address(buyer1).balance;

        // seller paid out correctly
        assertEq(
            sellerBalanceAfter,
            (sellerBalanceBefore + listing.price - listing.referralFee)
        );
        // referrer paid out correctly
        assertEq(
            buyer1BalanceAfter,
            (buyer1BalanceBefore + listing.referralFee)
        );
    }

    function test_buy_without_referralCode(
        uint256 price,
        uint256 referralFee
    ) public {
        vm.assume(price < defaultInitialEthBalance);
        vm.assume(price > referralFee);

        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: price,
            referralFee: referralFee,
            expiration: block.timestamp + 1
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory listingSignature = sign(seller1_private_key, listingHash);

        ReferralCode memory referralCode = ReferralCode("");

        vm.startPrank(seller1);
        boredApeYachtClub.approve(address(referralAndLoyalty), nftId);
        vm.stopPrank();

        uint256 sellerBalanceBefore = address(seller1).balance;

        vm.startPrank(buyer1);
        referralAndLoyalty.buy{value: listing.price}(
            listing,
            listingSignature,
            referralCode,
            ""
        );
        vm.stopPrank();

        // buyer is the owner of the nft after the sale
        assertEq(boredApeYachtClub.ownerOf(nftId), buyer1);

        uint256 sellerBalanceAfter = address(seller1).balance;

        // seller paid out correctly
        assertEq(sellerBalanceAfter, (sellerBalanceBefore + listing.price));
    }

    function test_buy_with_referralCode_FAIL_referrer_not_collector(
        uint256 price,
        uint256 referralFee
    ) public {
        vm.assume(price < defaultInitialEthBalance);
        vm.assume(price > referralFee);

        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: price,
            referralFee: referralFee,
            expiration: block.timestamp + 1
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory listingSignature = sign(seller1_private_key, listingHash);

        ReferralCode memory referralCode = ReferralCode(listingSignature);

        bytes32 referralCodeHash = referralAndLoyalty.getReferralCodeHash(
            referralCode
        );

        bytes memory referralCodeSignature = sign(
            SIGNER_PRIVATE_KEY_1,
            referralCodeHash
        );

        vm.startPrank(seller1);
        boredApeYachtClub.approve(address(referralAndLoyalty), nftId);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(ReferrerNotCollector.selector));

        vm.startPrank(buyer2);
        referralAndLoyalty.buy{value: listing.price}(
            listing,
            listingSignature,
            referralCode,
            referralCodeSignature
        );
        vm.stopPrank();
    }

    function test_buy_FAIL_insufficient_msgvalue(
        uint256 price,
        uint256 referralFee
    ) public {
        vm.assume(price > referralFee);

        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: price,
            referralFee: referralFee,
            expiration: block.timestamp + 1
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory signature = sign(seller1_private_key, listingHash);

        ReferralCode memory referralCode = ReferralCode("");

        vm.startPrank(seller1);
        boredApeYachtClub.approve(address(referralAndLoyalty), nftId);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientMsgValue.selector,
                0,
                listing.price
            )
        );

        vm.startPrank(buyer1);
        referralAndLoyalty.buy(listing, signature, referralCode, "");
        vm.stopPrank();
    }

    function test_buy_FAIL_expired_listing(
        uint256 price,
        uint256 referralFee
    ) public {
        vm.assume(price > referralFee);

        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: price,
            referralFee: referralFee,
            expiration: block.timestamp
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory signature = sign(seller1_private_key, listingHash);

        ReferralCode memory referralCode = ReferralCode("");

        vm.startPrank(seller1);
        boredApeYachtClub.approve(address(referralAndLoyalty), nftId);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(ListingExpired.selector));

        vm.startPrank(buyer1);
        referralAndLoyalty.buy(listing, signature, referralCode, "");
        vm.stopPrank();
    }

    function test_buy_FAIL_seller_notNFTOwner(
        uint256 price,
        uint256 referralFee
    ) public {
        vm.assume(price > referralFee);

        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: price,
            referralFee: referralFee,
            expiration: block.timestamp + 1
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory signature = sign(SIGNER_PRIVATE_KEY_1, listingHash);

        ReferralCode memory referralCode = ReferralCode("");

        vm.startPrank(seller1);
        boredApeYachtClub.approve(address(referralAndLoyalty), nftId);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                NotNftOwner.selector,
                listing.nftContractAddress,
                listing.nftId,
                SIGNER_1
            )
        );

        vm.startPrank(buyer1);
        referralAndLoyalty.buy(listing, signature, referralCode, "");
        vm.stopPrank();
    }

    function test_buy_FAIL_invalidReferralCode() public {
        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: 1,
            referralFee: 0,
            expiration: block.timestamp + 1
        });

        Listing memory listing2 = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: 1,
            referralFee: 0,
            expiration: block.timestamp + 2
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory listingSignature = sign(seller1_private_key, listingHash);

        bytes32 listingHash2 = referralAndLoyalty.getListingHash(listing2);

        bytes memory listingSignature2 = sign(
            seller1_private_key,
            listingHash2
        );

        ReferralCode memory referralCode = ReferralCode(listingSignature2);

        bytes32 referralCodeHash = referralAndLoyalty.getReferralCodeHash(
            referralCode
        );

        bytes memory referralCodeSignature = sign(
            buyer1_private_key,
            referralCodeHash
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidReferralCode.selector,
                listingSignature2,
                listingSignature
            )
        );

        vm.startPrank(buyer2);
        referralAndLoyalty.buy{value: listing.price}(
            listing,
            listingSignature,
            referralCode,
            referralCodeSignature
        );
        vm.stopPrank();
    }

    function test_buy_FAIL_signatureNotAvailable() public {
        Listing memory listing = Listing({
            nftContractAddress: nftContractAddress,
            nftId: nftId,
            price: 1,
            referralFee: 0,
            expiration: block.timestamp + 1
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory listingSignature = sign(seller1_private_key, listingHash);

        ReferralCode memory referralCode = ReferralCode(listingSignature);

        bytes32 referralCodeHash = referralAndLoyalty.getReferralCodeHash(
            referralCode
        );

        bytes memory referralCodeSignature = sign(
            buyer1_private_key,
            referralCodeHash
        );

        vm.startPrank(seller1);
        referralAndLoyalty.withdrawListingSignature(listing, listingSignature);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                SignatureNotAvailable.selector,
                listingSignature
            )
        );

        vm.startPrank(buyer2);
        referralAndLoyalty.buy{value: listing.price}(
            listing,
            listingSignature,
            referralCode,
            referralCodeSignature
        );
        vm.stopPrank();
    }
}
