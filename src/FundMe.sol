// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    // storage slot chứa 32 byte. tuần tự các biến được ghi vào slot theo thứ tự khai báo
    // bắt đầu từ slot 0. nếu 1 biến lớn hơn 32 byte sẽ được ghi vào slot tiếp theo
    // do đó sắp xếp các state variable ( hay global variable) hiệu quả sao cho chúng
    // xếp tối ưu 32 byte là để tối ưu gas
    // uint256 là 256 bit chia 8 ra được 32 byte, 128 bit = 16 byte
    // giờ sẽ sắp xếp các biến toàn cục bên dưới để tối ưu slot 32 byte
    // có một cách có thể áng chừng tốn bao nhiêu slot bằng cách cộng tất cả byte của storage
    // rồi chia cho 32(làm tròn lên), ví dụ
    // uint64 var1 = 1337; (8 byte)
    // uint128 var2 = 9000; (16 byte)
    // bool var3 = true; (1 byte)
    // bool var4 = false; (1 byte)
    // uint64 var5 = 10000; (8 byte)
    // address user1 = 0x1F98431c8aD98523631AE4a59f267346ea31F984; (20 byte)
    // uint128 var6 = 9999; (16 byte)
    // uint8 var7 = 3; (1 byte)
    // uint128 var8 = 20000000; (16 byte)
    // Tổng cộng: 8 + 16 + 1 + 1 + 8 + 20 + 16 + 1 + 16 = 87 byte
    // Chia cho 32: 87 / 32 = 2.71875
    // Làm tròn lên: 3 slot (3 * 32 = 96 byte) nên tối ưu nhất là 3 slot
    // và có thể xếp thành như thế này
    //// --- SLOT 0 (Tổng: 32 bytes) ---
    // uint128 var2;  // 16 bytes
    // uint64 var1;   //  8 bytes
    // uint64 var5;   //  8 bytes (16 + 8 + 8 = 32)

    // --- SLOT 1 (Tổng: 23 bytes -> còn trống 9 bytes) ---
    // address user1; // 20 bytes
    // bool var3;     //  1 byte
    // bool var4;     //  1 byte
    // uint8 var7;    //  1 byte  (20 + 1 + 1 + 1 = 23)

    // --- SLOT 2 (Tổng: 32 bytes) ---
    // uint128 var6;  // 16 bytes
    // uint128 var8;  // 16 bytes (16 + 16 = 32)
    mapping(address => uint256) private s_addressToAmountFunded; // chiếm 1 slot nên không cần
    //quan tâm nhưng chú ý đừng để nó ngắt quãng các biến nhỏ đang xếp vào 1 slot 32 byte
    address[] private s_funders; // cũng là 1 slot 32 byte

    // constant và immutable được biên dịch ra bytecode gắn thẳng vào contract không lưu storage
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    // Trong Solidity, một biến kiểu Interface (như AggregatorV3Interface) hay kiểu Contract
    // dưới tầng EVM thực chất chính là một biến address nên chiếm 20 bytes = 160 bits

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function getAddressToAmountFunded(
        address funder
    ) external view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // hàm này tối ưu hơn do lúc đầu vòng lặp for mỗi lần tốn gas để truy cập length của storage
    // mà biến storage thì tốn nhiều hơn memory nên khai báo một memory var để chứa length
    // của storage giúp tiết kiệm gas. bằng chứng có thể chạy test hai hàm
    // forge test -vv --mt "testWithdrawFromMultipleFunders"
    // forge test -vv --mt "testWithdrawFromMultipleFundersCheaperVersion"
    // để so sánh gas tiêu thụ. Kết quả test ở .gas-snapshot 566520 thành 565631
    function withdrawVersion2() public onlyOwner {
        uint256 numberOfFunders = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < numberOfFunders;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}
