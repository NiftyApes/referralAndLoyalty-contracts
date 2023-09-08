// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import "./common/BaseTest.sol";

import "./utils/ReferralAndLoyaltyDeployment.sol";
import "../src/ReferralAndLoyalty.sol";

contract TestWithdrawListingSignature is
    Test,
    BaseTest,
    ReferralAndLoyaltyDeployment,
    ReferralAndLoyalty
{
    uint256 immutable SIGNER_PRIVATE_KEY_1 =
        0x60b919c82f0b4791a5b7c6a7275970ace1748759ebdaa4076d7eeed9dbcff3c3;
    address immutable SIGNER_1 = 0x503408564C50b43208529faEf9bdf9794c015d52;

    function setUp() public override {
        super.setUp();
    }

    function test_unit_withdrawListingSignature_works() public {
        Listing memory listing = Listing({
            nftContractAddress: address(
                0xB4FFCD625FefD541b77925c7A37A55f488bC69d9
            ),
            nftId: 1,
            price: 1 ether,
            referralFee: 0.3 ether,
            expiration: uint32(1657217355)
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory signature = sign(buyer1_private_key, listingHash);

        vm.startPrank(address(buyer1));
        referralAndLoyalty.withdrawListingSignature(listing, signature);
        vm.stopPrank();
    }

    function test_unit_cannot_withdrawListingSignature_not_signer() public {
        Listing memory listing = Listing({
            nftContractAddress: address(
                0xB4FFCD625FefD541b77925c7A37A55f488bC69d9
            ),
            nftId: 1,
            price: 1 ether,
            referralFee: 0.3 ether,
            expiration: uint32(1657217355)
        });

        bytes32 listingHash = referralAndLoyalty.getListingHash(listing);

        bytes memory signature = sign(buyer1_private_key, listingHash);

        vm.startPrank(address(seller1));
        vm.expectRevert(
            abi.encodeWithSelector(InvalidSigner.selector, buyer1, seller1)
        );
        referralAndLoyalty.withdrawListingSignature(listing, signature);
        vm.stopPrank();
    }
}
