// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/facets/ERC20Facet.sol";
import "../src/facets/StakingFacet.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IDiamondLoupe.sol";
import "../src/interfaces/IERC173.sol";

// Import the DiamondUtils contract
import "./helpers/DiamondUtils.sol";

contract DiamondTest is Test, DiamondUtils {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupeFacet;
    OwnershipFacet ownershipFacet;
    ERC20Facet erc20Facet;
    StakingFacet stakingFacet;

    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        erc20Facet = new ERC20Facet();
        stakingFacet = new StakingFacet();

        // Deploy Diamond
        diamond = new Diamond(owner, address(dCutFacet));

        // Build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(dLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFunctionSelectors("DiamondLoupeFacet")
        });

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFunctionSelectors("OwnershipFacet")
        });

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(erc20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFunctionSelectors("ERC20Facet")
        });

        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(stakingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFunctionSelectors("StakingFacet")
        });

        // Upgrade diamond with facets
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Get facet addresses
        address loupe = IDiamondLoupe(address(diamond)).facetAddress(dLoupeFacet.facets.selector);
        address erc20 = IDiamondLoupe(address(diamond)).facetAddress(erc20Facet.totalSupply.selector);
        address staking = IDiamondLoupe(address(diamond)).facetAddress(stakingFacet.stake.selector);

        // Cast facets
        dLoupeFacet = DiamondLoupeFacet(loupe);
        erc20Facet = ERC20Facet(erc20);
        stakingFacet = StakingFacet(staking);
    }

    function testDiamondCut() public {
        assertEq(dLoupeFacet.facetAddresses().length, 5);
    }

    function testOwnership() public {
        assertEq(IERC173(address(diamond)).owner(), owner);
    }

    function testERC20Functionality() public {
        uint256 initialSupply = 1000000 * 10**18;
        // erc20Facet._mint(address(this), initialSupply);

        assertEq(erc20Facet.totalSupply(), initialSupply);
        assertEq(erc20Facet.balanceOf(address(this)), initialSupply);

        uint256 transferAmount = 1000 * 10**18;
        erc20Facet.transfer(user1, transferAmount);

        assertEq(erc20Facet.balanceOf(user1), transferAmount);
        assertEq(erc20Facet.balanceOf(address(this)), initialSupply - transferAmount);

        vm.prank(user1);
        erc20Facet.approve(user2, transferAmount);

        vm.prank(user2);
        erc20Facet.transferFrom(user1, user2, transferAmount / 2);

        assertEq(erc20Facet.balanceOf(user1), transferAmount / 2);
        assertEq(erc20Facet.balanceOf(user2), transferAmount / 2);
    }

    function testStakingFunctionality() public {
        uint256 initialSupply = 1000000 * 10**18;
        // erc20Facet._mint(address(this), initialSupply);

        uint256 stakeAmount = 1000 * 10**18;
        erc20Facet.approve(address(diamond), stakeAmount);
        stakingFacet.stake(stakeAmount);

        assertEq(stakingFacet.stakedBalanceOf(address(this)), stakeAmount);
        assertEq(stakingFacet.totalStaked(), stakeAmount);

        stakingFacet.unstake(stakeAmount / 2);

        assertEq(stakingFacet.stakedBalanceOf(address(this)), stakeAmount / 2);
        assertEq(stakingFacet.totalStaked(), stakeAmount / 2);
    }

    function testDiamondLoupe() public {
        IDiamondLoupe.Facet[] memory facets = dLoupeFacet.facets();
        assertEq(facets.length, 5);

        bytes4[] memory selectors = dLoupeFacet.facetFunctionSelectors(address(erc20Facet));
        assertTrue(selectors.length > 0);

        address facetAddress = dLoupeFacet.facetAddress(erc20Facet.totalSupply.selector);
        assertEq(facetAddress, address(erc20Facet));
    }

    function testFailStakeMoreThanBalance() public {
        uint256 initialSupply = 1000 * 10**18;
        // erc20Facet._mint(address(this), initialSupply);

        uint256 stakeAmount = 2000 * 10**18;
        erc20Facet.approve(address(diamond), stakeAmount);
        stakingFacet.stake(stakeAmount);
    }

    function testFailUnstakeMoreThanStaked() public {
        uint256 initialSupply = 1000 * 10**18;
        // erc20Facet._mint(address(this), initialSupply);

        uint256 stakeAmount = 500 * 10**18;
        erc20Facet.approve(address(diamond), stakeAmount);
        stakingFacet.stake(stakeAmount);

        stakingFacet.unstake(1000 * 10**18);
    }

}