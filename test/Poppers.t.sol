// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Poppers.sol";
import "./mocks/TestERC20.sol";

contract PoppersTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    Poppers nft;

    function setUp() public {
        vm.deal(alice, 10_000_000);

        nft = new Poppers(10, 10, 3, 10, 10, "POPPERS", "POPPERS");
    }

    function test_mint() public {
        nft.setSale(block.timestamp - 1);
        vm.startPrank(alice);

        nft.mint{value: 10}();

        vm.stopPrank();

        assertEq(address(nft).balance, 10 - 1);
        assertEq(nft.currentSupply(), 4);
        assertEq(nft.ownerOf(3), alice);
    }

    function test_mint3() public {
        nft.setSale(block.timestamp - 1);
        vm.startPrank(alice);

        nft.mint{value: 10}();
        nft.mint{value: 10}();
        nft.mint{value: 10}();

        vm.stopPrank();
        assertEq(address(nft).balance, 30 - 3);
        assertEq(nft.currentSupply(), 6);
        assertEq(nft.ownerOf(5), alice);
        assertEq(nft.ownerOf(3), alice);
        assertEq(nft.ownerOf(4), alice);
    }

    function test_mintOverMax() public {
        nft.setSale(block.timestamp - 1);
        vm.startPrank(alice);

        nft.mint{value: 10}();
        nft.mint{value: 10}();
        nft.mint{value: 10}();

        vm.expectRevert(Poppers.NotEligible.selector);
        nft.mint{value: 10}();

        vm.stopPrank();
    }

    function test_mintMetadata() public {
        nft.setSale(block.timestamp - 1);
        vm.startPrank(alice);

        nft.mint{value: 10}();

        vm.stopPrank();
        assertEq(nft.tokenURI(0), nft.PREREVEAL_URI());
        nft.setBaseURI("ipfs:xxx/");
        assertEq(nft.tokenURI(0), "ipfs:xxx/0");
    }

    function test_mintFail() public {
        nft.setSale(block.timestamp - 1);
        vm.startPrank(bob);

        vm.expectRevert(Poppers.NotEligible.selector);
        nft.mint{value: 0}();

        vm.deal(bob, 10_000_000);
        nft.mint{value: 10}();

        vm.stopPrank();

        assertEq(nft.ownerOf(3), bob);
    }

    function test_notSale() public {
        vm.startPrank(alice);

        vm.expectRevert(Poppers.NotSale.selector);
        nft.mint{value: 10}();

        vm.stopPrank();

        vm.startPrank(alice);

        vm.expectRevert(Poppers.NotSale.selector);
        nft.mint{value: 10}();

        vm.stopPrank();
    }

    function test_changeSale() public {
        vm.startPrank(alice);

        vm.expectRevert(Poppers.NotSale.selector);
        nft.mint{value: 10}();

        vm.stopPrank();

        nft.setSale(block.timestamp - 1);
        nft.setSale(block.timestamp * 2);

        vm.startPrank(alice);

        vm.expectRevert(Poppers.NotSale.selector);
        nft.mint{value: 10}();

        vm.stopPrank();
    }

    function test_maxSupply() public {
        nft.setSale(block.timestamp - 1);

        for (uint256 i; i < 7; ++i) {
            address addr = makeAddr(Strings.toString(i));

            vm.startPrank(addr);

            vm.deal(addr, 10_000_000);

            nft.mint{value: 10}();

            vm.stopPrank();
        }

        vm.startPrank(alice);

        vm.expectRevert(Poppers.MaxSupplyReached.selector);
        nft.mint{value: 10}();

        vm.stopPrank();
    }

    function test_recover() public {
        nft.setSale(block.timestamp - 1);
        vm.startPrank(alice);

        nft.mint{value: 10}();

        vm.stopPrank();

        nft.transferOwnership(bob);

        vm.prank(bob);
        nft.recoverFunds();
        assertEq(bob.balance, 9);
    }

    function test_distribution() public {
        vm.deal(0xc7d48f75E1C4B3f2B97A57Fd925d9c2388F844EF, 40);
        nft.setSale(block.timestamp - 1);
        vm.startPrank(0xc7d48f75E1C4B3f2B97A57Fd925d9c2388F844EF);

        nft.mint{value: 10}();
        nft.mint{value: 10}();
        nft.mint{value: 10}();

        vm.stopPrank();

        assertEq(address(0).balance, 3);
    }

    function test_freeMint() public {
        nft.setSale(block.timestamp - 1);

        nft.addFreeMint(alice);

        vm.startPrank(alice);

        nft.mint();

        vm.stopPrank();

        assertEq(address(nft).balance, 0);
        assertEq(nft.currentSupply(), 4);
        assertEq(nft.ownerOf(3), alice);
    }

    function test_freeMinttwo() public {
        nft.setSale(block.timestamp - 1);

        nft.addFreeMint(alice);
        nft.addFreeMint(alice);

        vm.startPrank(alice);

        nft.mint();
        nft.mint();

        vm.stopPrank();

        assertEq(address(nft).balance, 0);
        assertEq(nft.currentSupply(), 5);
        assertEq(nft.ownerOf(4), alice);
    }

    function test_freeMintOver() public {
        nft.setSale(block.timestamp - 1);

        nft.addFreeMint(alice);

        vm.startPrank(alice);

        nft.mint();
        vm.expectRevert(Poppers.InsufficientFunds.selector);
        nft.mint();

        vm.stopPrank();
    }
}
