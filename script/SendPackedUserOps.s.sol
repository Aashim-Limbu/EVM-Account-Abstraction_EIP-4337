// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {IEntryPoint, PackedUserOperation} from "@openzeppelin/account-abstraction/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOps is Script {
    using MessageHashUtils for bytes32;

    function run() public {}

    function generatedSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory networkConfig)
        external
        view
        returns (PackedUserOperation memory)
    {
        uint256 nonce = vm.getNonce(networkConfig.account);
        // Generate the unsigned Data.
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, networkConfig.account, nonce);
        // 2. Get the userOp Hash.
        bytes32 userOpHash = IEntryPoint(networkConfig.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // Sign it, and return it.
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_WALLET = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_WALLET, digest);
        } else {
            (v, r, s) = vm.sign(networkConfig.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory packedUserOperation)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        packedUserOperation = PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            /**
             * Shift one value to the left to move it to the upper half of a 256-bit space
             * Leave the second value in the lower half
             * Combine them using | (bitwise OR)
             */
            accountGasLimits: bytes32((uint256(verificationGasLimit) << 128) | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 182 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
