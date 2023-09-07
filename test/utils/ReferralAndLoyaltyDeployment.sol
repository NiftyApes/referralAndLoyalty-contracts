// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../../src/ReferralAndLoyalty.sol";
import "./NFTFixtures.sol";

import "forge-std/Test.sol";

// deploy & initializes ReferralAndLoyalty contracts
contract ReferralAndLoyaltyDeployment is Test, NFTFixtures {
    ReferralAndLoyalty referralAndLoyalty;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(owner);

        referralAndLoyalty = new ReferralAndLoyalty();

        vm.stopPrank();
        vm.label(address(0), "NULL !!!!! ");
    }
}
