// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import "./common/BaseTest.sol";

import "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "./utils/ReferralAndLoyaltyDeployment.sol";
import "../src/ReferralAndLoyalty.sol";

contract TestGetReferralCodeHash is
    Test,
    BaseTest,
    ReferralAndLoyaltyDeployment,
    ReferralAndLoyalty
{
    function setUp() public override {
        super.setUp();
    }

    function test_unit_getReferralCodeHash() public {
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

        ReferralCode memory referralCode = ReferralCode(signature);

        bytes32 referralCodeHash = referralAndLoyalty.getReferralCodeHash(
            referralCode
        );

        bytes32 expectedFunctionHash = 0xe321fd57a0313c4c9a19b790048b32893b9438c2ab7761e8e6975c6ae625cd3e;

        assertEq(referralCodeHash, expectedFunctionHash);
    }
}
