// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address kid = makeAddr("kid");
    uint256 constant SEND_VALUE = 0.1e18;
    uint256 constant INITIAL_BALANCE_ETH = 100e18;

    modifier funded() {
        hoax(kid, INITIAL_BALANCE_ETH);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();
        // vm.deal(kid, INITIAL_BALANCE_ETH);
    }

    //vm.load(address(contract), bytes32(slot)) dùng để load dữ liệu của slot storage thứ i
    // của 1 contract
    function testPrintStorageData() public {
        // for lặp qua 3 slot storage đầu tiên của contract FundMe
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }

    function testMinimumDollarIsFive() external {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // function testOwnerIsMsgSender() external {
    //     assertEq(fundMe.i_owner(), msg.sender);
    // }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //khởi tạo mới fundMe ở trong cụm broadcast
    // vm.startBroadcast(): Hãy gửi các giao dịch tạo/gọi contract tiếp theo
    // bằng địa chỉ của tài khoản gửi mặc định (Default Sender)
    // khởi tạo funMeTest bằng foundry VM nên địa chỉ là tài khoản mặc định
    // do đó assertEq(fundMe.i_owner(), msg.sender); bằng nhau

    // còn nếu không dùng script mà khởi tạo ngay tại hàm setUp
    // function setUp() external {
    //     fundMe = new FundMe(address(0x...));
    // }
    // thì msg.sender của fundMe chính là địa chỉ của contract FundMeTest
    // do đó sửa thành assertEq(fundMe.i_owner(), address(this)) address(this) chính là
    // địa chỉ của hàm đang đứng hay FundMeTest.

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailNoEnoughETH() external {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundDataStructure() external funded {
        //vm.prank(kid); // dùng prank chỉ giả lập địa chỉ gửi phải kết hợp với
        //vm.deal(kid, INITIAL_BALANCE_ETH); để giả lập số dư
        // hoax(kid, INITIAL_BALANCE_ETH); // dùng hoax giả lập được địa chỉ và số dư cùng lúc
        // fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(kid);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(kid);
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaperVersion() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdrawVersion2();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }
}
