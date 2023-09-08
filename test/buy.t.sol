// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./common/BaseTest.sol";

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

    function setUp() public override {
        super.setUp();
    }

    function test_buy_without_referralCode(
        uint256 price,
        uint256 referralFee
    ) private {
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

        ReferralCode memory referralCode = ReferralCode(signature);

        vm.startPrank(seller1);
        boredApeYachtClub.approve(address(referralAndLoyalty), nftId);
        vm.stopPrank();

        uint256 sellerBalanceBefore = address(seller1).balance;

        vm.startPrank(buyer1);
        referralAndLoyalty.buy(listing, signature, referralCode, "");
        vm.stopPrank();

        // buyer is the owner of the nft after the sale
        assertEq(boredApeYachtClub.ownerOf(nftId), buyer1);

        uint256 sellerBalanceAfter = address(seller1).balance;

        // seller paid out correctly
        assertEq(sellerBalanceAfter, (sellerBalanceBefore + listing.price));
    }

    // function _test_buyNow_reverts_if_insufficient_msgValue(
    //     FuzzedOfferFields memory fuzzed
    // ) private {
    //     Offer memory offer = saleOfferStructFromFields(
    //         fuzzed,
    //         defaultFixedOfferFields,
    //         address(0)
    //     );

    //     bytes memory offerSignature = seller1CreateOffer(offer);

    //     vm.startPrank(buyer1);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             INiftyApesErrors.InsufficientMsgValue.selector,
    //             offer.loanTerms.downPaymentAmount - 1,
    //             offer.loanTerms.downPaymentAmount
    //         )
    //     );
    //     sellerFinancing.buyNow{value: offer.loanTerms.downPaymentAmount - 1}(
    //         offer,
    //         offerSignature,
    //         buyer1,
    //         offer.collateralItem.tokenId,
    //         offer.collateralItem.amount
    //     );
    //     vm.stopPrank();
    // }

    // function test_fuzz_buyNow_reverts_if_insufficient_msgValue(
    //     FuzzedOfferFields memory fuzzed
    // ) public validateFuzzedOfferFields(fuzzed) {
    //     _test_buyNow_reverts_if_insufficient_msgValue(fuzzed);
    // }

    // function test_unit_buyNow_reverts_if_insufficient_msgValue() public {
    //     FuzzedOfferFields
    //         memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
    //     _test_buyNow_reverts_if_insufficient_msgValue(fixedForSpeed);
    // }

    // function _test_buy_withMarketplaceFees(
    //     FuzzedOfferFields memory fuzzed
    // ) private {
    //     Offer memory offer = saleOfferStructFromFields(
    //         fuzzed,
    //         defaultFixedOfferFields,
    //         address(0)
    //     );
    //     uint256 marketplaceFee = ((offer.loanTerms.principalAmount +
    //         offer.loanTerms.downPaymentAmount) * SUPERRARE_MARKET_FEE_BPS) /
    //         10_000;

    //     offer.marketplaceRecipients = new MarketplaceRecipient[](1);
    //     offer.marketplaceRecipients[0] = MarketplaceRecipient(
    //         address(SUPERRARE_MARKETPLACE),
    //         marketplaceFee
    //     );

    //     (
    //         address payable[] memory recipients1,
    //         uint256[] memory amounts1
    //     ) = IRoyaltyEngineV1(0x0385603ab55642cb4Dd5De3aE9e306809991804f)
    //             .getRoyalty(
    //                 offer.collateralItem.token,
    //                 offer.collateralItem.tokenId,
    //                 offer.loanTerms.downPaymentAmount
    //             );

    //     uint256 totalRoyaltiesPaid;

    //     // payout royalties
    //     for (uint256 i = 0; i < recipients1.length; i++) {
    //         totalRoyaltiesPaid += amounts1[i];
    //     }

    //     uint256 sellerBalanceBefore = address(seller1).balance;
    //     uint256 royaltiesBalanceBefore = address(recipients1[0]).balance;

    //     uint256 marketplaceBalanceBefore = address(SUPERRARE_MARKETPLACE)
    //         .balance;

    //     bytes memory offerSignature = seller1CreateOffer(offer);

    //     vm.startPrank(buyer1);
    //     sellerFinancing.buyNow{
    //         value: offer.loanTerms.downPaymentAmount + marketplaceFee
    //     }(
    //         offer,
    //         offerSignature,
    //         buyer1,
    //         offer.collateralItem.tokenId,
    //         offer.collateralItem.amount
    //     );

    //     // buyer is the owner of the nft after the sale
    //     assertEq(
    //         boredApeYachtClub.ownerOf(offer.collateralItem.tokenId),
    //         buyer1
    //     );

    //     uint256 sellerBalanceAfter = address(seller1).balance;
    //     uint256 royaltiesBalanceAfter = address(recipients1[0]).balance;
    //     uint256 marketplaceBalanceAfter = address(SUPERRARE_MARKETPLACE)
    //         .balance;

    //     assertEq(
    //         marketplaceBalanceAfter,
    //         (marketplaceBalanceBefore + marketplaceFee)
    //     );

    //     // seller paid out correctly
    //     assertEq(
    //         sellerBalanceAfter,
    //         (sellerBalanceBefore +
    //             offer.loanTerms.downPaymentAmount -
    //             totalRoyaltiesPaid)
    //     );

    //     // royatlies paid out correctly
    //     assertEq(
    //         royaltiesBalanceAfter,
    //         (royaltiesBalanceBefore + totalRoyaltiesPaid)
    //     );
    // }

    // function test_fuzz_buy_withMarketplaceFees(
    //     FuzzedOfferFields memory fuzzed
    // ) public validateFuzzedOfferFields(fuzzed) {
    //     _test_buy_withMarketplaceFees(fuzzed);
    // }

    // function test_unit_buy_withMarketplaceFees() public {
    //     FuzzedOfferFields
    //         memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
    //     _test_buy_withMarketplaceFees(fixedForSpeed);
    // }
}
