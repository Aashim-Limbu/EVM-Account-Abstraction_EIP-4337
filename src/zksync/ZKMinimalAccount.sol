// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IAccount} from "@cyfrin/system-contracts/interfaces/IAccount.sol";
import {Transaction} from "@cyfrin/system-contracts/libraries/MemoryTransactionHelper.sol";

contract ZKMinimalAccount is IAccount {
    /*//////////////////////////////////////////////////////////////
                            EXTERNALFUNCTION
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Must increase the nonce in Nonce Holder.
     * @notice Must validate the transaction.
     */
    function validateTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
        returns (bytes4 magic)
    {}

    function executeTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {}

    function payForTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

    /*//////////////////////////////////////////////////////////////
                            INTERNALFUNCTION
    //////////////////////////////////////////////////////////////*/
}
