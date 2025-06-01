// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "../script/DeployMinimal.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {
    SendPackedUserOps, PackedUserOperation, IEntryPoint, MessageHashUtils
} from "../script/SendPackedUserOps.s.sol";
import {ECDSA} from "@openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    MinimalAccount minimalAccount;
    HelperConfig helperConfig;
    ERC20Mock usdc;
    SendPackedUserOps sendPackedUserOps;

    uint256 constant AMOUNT = 1e18;
    address randomUser = makeAddr("RANDOM_USER");
    address DEFAULT_OWNER = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496; //due to transfer ownership
    address account = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public {
        DeployMinimal deployer = new DeployMinimal();
        sendPackedUserOps = new SendPackedUserOps();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        usdc = new ERC20Mock();
    }

    function testExecuteOwnerWorks() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        // we're eventually calling with value and destination. with low level call it is like mint(msg.sender,0);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNonOwnerCannotExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        // we're eventually calling with value and destination. with low level call it is like mint(msg.sender,0);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // Act
        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, value, functionData);
    }

    function testRecoverSignedOp() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOps =
            sendPackedUserOps.generatedSignedUserOperation(executeCallData, helperConfig.getConfig());
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOps);
        // Act
        (address recovered,,) = ECDSA.tryRecover(userOperationHash.toEthSignedMessageHash(), packedUserOps.signature);
        assertEq(recovered, minimalAccount.owner());
    }

    // 1. Sign user ops .
    // 2. Call validate userOps
    // 3. Assert The return is correct
    function testValidationOfUserOps() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOps =
            sendPackedUserOps.generatedSignedUserOperation(executeCallData, helperConfig.getConfig());
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOps);
        uint256 missingAccountFunds = 1e18;
        // Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOps, userOperationHash, missingAccountFunds);
        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {

    }
}
