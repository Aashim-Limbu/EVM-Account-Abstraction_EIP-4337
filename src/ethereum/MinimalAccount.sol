// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Account, ERC4337Utils} from "@openzeppelin/community-contracts/account/Account.sol";
import {PackedUserOperation} from "@openzeppelin/account-abstraction/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Account Contract
 * @author Aashim limbu
 * @notice The Account Contract is a smart contract that implements the logic required to validate a UserOperation in the context of ERC-4337. Any smart contract account should conform with the IAccount interface to validate operations.
 * @dev
 *         EntryPoint contract will call this function.
 *         You can implement custom logic here to verify signatures,
 *         such as multisig, social login attestations (e.g. Google),
 *         external oracle verification, or rate limiting.
 */
contract MinimalAccount is Ownable {
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes result);

    IEntryPoint private immutable i_entryPoint;

    modifier onlyEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier onlyEntryPointElseOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    // EntryPoint contract will call this function

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateUserOp(userOp, userOpHash); // if it fails it would be 1 else 0; opposite
        _payPrefund(missingAccountFunds);
    }

    receive() external payable {}
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    function execute(address dest, uint256 value, bytes calldata functionData) external onlyEntryPointElseOwner {
        (bool success, bytes memory result) = dest.call{value: value}(functionData);
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/
    function _validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        // Coverting the userOpHash to EIP-191 Hash format. we could also do with EIP-712 format to decode to the address.
        bytes32 ethSignedMessagehash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address recoveredAddress = ECDSA.recover(ethSignedMessagehash, userOp.signature);
        if (recoveredAddress != owner()) {
            return ERC4337Utils.SIG_VALIDATION_FAILED; // returns 1
        }
        return ERC4337Utils.SIG_VALIDATION_SUCCESS; // return 0
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            // no operation. it evaluates the success boolean but doesn't do anything with it (no return, no require, no event).
            (success);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/

    function getEntryPoint() external view returns (address entryPoint) {
        entryPoint = address(i_entryPoint);
    }
}
