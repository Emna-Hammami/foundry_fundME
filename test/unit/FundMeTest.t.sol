// t.sol ===> convention in solidity to say this is a test file
// t.sol is a test file

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import "../../src/FundMe.sol";
import "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // uint256 number = 1;
    FundMe fundMe;

    address USER = makeAddr("user"); // Generate a deterministic Ethereum address from the string "user" for testing

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // number = 2;
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // deal --> sets the balance to a new balance
    }

    function testMinimumDollarIsFive() public view {
        /*console.log(number);
        console.log("Hi !");
        assertEq(number, 2);*/
        assertEq(fundMe.minimumUSD(), 5e18);
    }

    function testOwnerIsMsgSender() public view{
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        // assertEq(fundMe.i_owner(), address(this)); // i_owner --> immutable
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view{
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // the next line should revert
        // assert(this trx fails/reverts)
        fundMe.fund{value: 0}();
        // fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        /*vm.prank(USER); // the next trx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();*/
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        /*vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();*/

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        /*vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();*/
        console.log("******************");
        vm.expectRevert(); // Expect the next transaction to revert
        vm.prank(USER); // Simulate actions from the address USER in the following code
        fundMe.withdraw();
    }

    function testWithDawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        //uint256 gasStart = gasleft(); // tells you the gas left in the trx
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        /*uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);*/

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // fund the fundMe
            //vm.prank(USER);
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // fund the fundMe
            //vm.prank(USER);
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }
}
