// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "./utils/ReferralAndLoyaltyDeployment.sol";
import "../src/ReferralAndLoyalty.sol";

contract TestGetListingHash is
    Test,
    ReferralAndLoyaltyDeployment,
    ReferralAndLoyalty
{
    function setUp() public override {
        super.setUp();
    }

    function test_unit_getListingHash() public {
        Listing memory listing = Listing({
            nftContractAddress: address(
                0xB4FFCD625FefD541b77925c7A37A55f488bC69d9
            ),
            nftId: 1,
            price: 1 ether,
            referralFee: 0.3 ether,
            expiration: uint32(1657217355)
        });

        bytes32 functionListingHash = referralAndLoyalty.getListingHash(
            listing
        );

        bytes32 expectedFunctionHash = 0x66ac632c4b042eaac2027b512410529e0b6bb2c788be6381c75d74e20213c730;

        assertEq(functionListingHash, expectedFunctionHash);
    }
}
