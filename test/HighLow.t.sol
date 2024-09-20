// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/shared/Token.sol";
import "../src/shared/Core.sol";
import "../src/shared/staking/StakingInterface.sol";
import "../src/HighLow.sol";
import "../src/HighLowBet.sol";

contract DiceTest is Test {
    Token public token;
    address public staking = address(999000999000);
    Core public core;
    Dice public dice;
    Partner public partner;
    BetsMemory public betsMemory;
    Pass public pass;
    address public affiliate = address(128911982379182361);

    address public alice = address(1);
    address public bob = address(2);
    address public carol = address(3);
    address public dave = address(4);
    address public eve = address(5);

    function setUp() public {
        pass = new Pass(address(this));
        pass.grantRole(pass.TIMELOCK(), address(this));
        pass.setAffiliate(affiliate);
        vm.mockCall(
            affiliate,
            abi.encodeWithSelector(
                AffiliateInterface.checkInviteCondition.selector,
                address(1)
            ),
            abi.encode(true)
        );
        vm.mockCall(
            address(pass),
            abi.encodeWithSelector(AffiliateMember.getInviter.selector, alice),
            abi.encode(address(0))
        );
        pass.mint(alice, address(0), address(0));

        token = new Token(address(this));
        betsMemory = new BetsMemory(address(this));
        betsMemory.grantRole(betsMemory.TIMELOCK(), address(this));
        betsMemory.setPass(address(pass));
        core = new Core(
            address(token),
            address(betsMemory),
            address(pass),
            address(this)
        );
        core.grantRole(core.TIMELOCK(), address(this));
        vm.mockCall(
            address(staking),
            abi.encodeWithSelector(StakingInterface.getAddress.selector),
            abi.encode(address(staking))
        );
        vm.mockCall(
            address(staking),
            abi.encodeWithSelector(StakingInterface.getToken.selector),
            abi.encode(address(token))
        );
        core.addStaking(address(staking));
        dice = new Dice(
            address(core),
            address(staking),
            555,
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed,
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
        );
        core.addGame(address(dice));
        betsMemory.addAggregator(address(core));
        address tariff = core.addTariff(0, 1_00, 0);
        vm.startPrank(carol);
        partner = Partner(core.addPartner(tariff));
        vm.stopPrank();
        for (uint160 i = 1; i <= 100; i++) {
            if (i > 1) {
                pass.mint(address(i), alice, alice);
            }
            token.transfer(address(i), 1000 ether);
        }
        token.transfer(address(staking), 5000 ether);
        token.transfer(address(core), 5000 ether);
    }

    function getRequest(uint256 requestId) internal {
        vm.mockCall(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed,
            abi.encodeWithSelector(
                VRFCoordinatorV2_5.requestRandomWords.selector,
                VRFV2PlusClient.RandomWordsRequest({
                    keyHash: bytes32(
                        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
                    ),
                    subId: uint256(555),
                    requestConfirmations: uint16(3),
                    callbackGasLimit: uint32(2_500_000),
                    numWords: uint32(1),
                    extraArgs: VRFV2PlusClient._argsToBytes(
                        VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                    )
                })
            ),
            abi.encode(requestId)
        );
    }

    function testConstructor() public {
        Dice _dice = new Dice(
            address(core),
            address(staking),
            555,
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed,
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
        );
        assertEq(_dice.getAddress(), address(_dice));
        assertEq(_dice.getStaking(), address(staking));
        assertEq(
            _dice.getVrfCoordinator(),
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        assertEq(
            _dice.getKeyHash(),
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
        );
        assertEq(_dice.getSubscriptionId(), 555);
    }

    function testBrokenBet() public {
        vm.startPrank(alice);
        token.approve(address(core), 1000 ether);

        vm.expectRevert(bytes("D02"));
        partner.placeBet(
            address(dice),
            100 ether,
            abi.encode(bob, 100, 5000, 1)
        );

        vm.expectRevert(bytes("D03"));
        partner.placeBet(
            address(dice),
            100 ether,
            abi.encode(alice, 100 ether, 5000, 1)
        );

        vm.expectRevert(bytes("D04"));
        partner.placeBet(
            address(dice),
            1000 ether,
            abi.encode(alice, 1000, 0, 1)
        );

        vm.expectRevert(bytes("D04"));
        dice.getPossibleWin(0, true, 1000);

        assertEq(dice.getPossibleWin(5000, true, 1000), 2000);
        assertEq(dice.getPossibleWin(5000, false, 1000), 2000);

        vm.stopPrank();
        assertEq(token.balanceOf(address(dice)), 0);
    }

    function testFuzz_fulFillRound(uint256 _threshold) public {
        vm.assume(_threshold > 0 && _threshold < 10000);
        // uint256 amount = 100;
        getRequest(5);
        token.transfer(address(dice), 1000 * 10000 ether);
        token.transfer(address(staking), 1000 * 10000 ether);
        token.transfer(address(core), 1000 * 10000 ether);

        vm.startPrank(alice);
        token.approve(address(core), 1000 * 1 ether);

        uint256 playBalance = token.balanceOf(alice);

        address bet = partner.placeBet(
            address(dice),
            1000 * 1 ether,
            abi.encode(alice, 1000, _threshold, 1)
        );

        DiceBet diceBet = DiceBet(bet);
        uint256[] memory words = new uint256[](3);
        uint256 profit = dice.getPossibleWin(_threshold, true, 1000 * 1 ether);
        uint256 stakingBalance = token.balanceOf(staking);

        words[0] = 256;
        vm.startPrank(dice.vrfCoordinator());
        dice.rawFulfillRandomWords(5, words);

        assertEq(diceBet.getResult(), 257 > _threshold ? profit : 0 ether);
        assertEq(diceBet.getStatus(), 2);
        assertEq(diceBet.getWinNumber(), words[0] + 1);
        assertEq(dice.getPlayerRequestsCount(alice), 1);
        assertEq(dice.getRequestBet(5), bet);

        (
            address __player,
            address __game,
            uint256 __amount,
            uint256 __result,
            uint256 __status,
            uint256 __created
        ) = diceBet.getBetInfo();
        assertEq(__player, alice);
        assertEq(__game, address(dice));
        assertEq(__amount, 1000 * 1 ether);
        assertEq(__result, 257 > _threshold ? profit : 0 ether);
        assertEq(__status, 2);
        assertEq(__created, block.timestamp);

        assertEq(token.balanceOf(address(dice)), 1000 * 10000 ether - profit);
        assertEq(token.balanceOf(alice), playBalance - __amount + __result);
        assertEq(
            token.balanceOf(staking),
            stakingBalance + (__result > 0 ? 0 : profit)
        );

        vm.stopPrank();
    }

    function testOnlyCore_placeBet() public {
        // warp to 26/03/2024 11:00:00
        vm.warp(1711450800);
        bytes memory data = abi.encode(alice, 500, 5000, true);
        vm.expectRevert(bytes("D05"));
        dice.placeBet(alice, 500 ether, data);
    }

    function testInsufficientStakingFunds() public {
        // Test scenario where staking funds are insufficient to cover the bet
        vm.startPrank(alice);

        // Mock insufficient funds in staking
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(staking)),
            abi.encode(0)
        );

        token.approve(address(core), 1000 ether);
        getRequest(100);

        vm.expectRevert(bytes("D07"));
        partner.placeBet(
            address(dice),
            1000 ether,
            abi.encode(alice, 1000, 5000, 1)
        );
        vm.stopPrank();
    }

    function testPlaceBet() public {
        // warp to 26/03/2024 11:00:00
        vm.warp(1711450800);
        //Test if the bet is placed correctly
        vm.startPrank(alice);
        token.approve(address(core), 1000 ether);
        getRequest(100);

        address bet = partner.placeBet(
            address(dice),
            1000 ether,
            abi.encode(alice, 1000, 5000, 1)
        );

        DiceBet diceBet = DiceBet(bet);

        assertEq(diceBet.getPlayer(), alice);
        assertEq(diceBet.getAmount(), 1000 ether);
        assertEq(diceBet.getGame(), address(dice));

        (uint256 threshold, bool side) = diceBet.getBets();
        assertEq(threshold, 5000);
        assertEq(side, true);

        assertEq(diceBet.getCreated(), block.timestamp);

        vm.stopPrank();
    }
}
