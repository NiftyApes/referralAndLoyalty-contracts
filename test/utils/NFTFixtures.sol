pragma solidity 0.8.18;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "forge-std/Test.sol";

import "./UsersFixtures.sol";

// mints NFTs to sellers
contract NFTFixtures is Test, UsersFixtures {
    address public flamingoDAO = 0xB88F61E6FbdA83fbfffAbE364112137480398018;
    IERC721 boredApeYachtClub =
        IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

    function setUp() public virtual override {
        vm.rollFork(16901983);
        super.setUp();

        vm.startPrank(flamingoDAO);

        boredApeYachtClub.transferFrom(flamingoDAO, address(seller1), 8661);
        boredApeYachtClub.transferFrom(flamingoDAO, address(buyer1), 6974);

        vm.stopPrank();
    }
}
