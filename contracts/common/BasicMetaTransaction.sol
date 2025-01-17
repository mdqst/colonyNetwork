// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import { DSMath } from "../../lib/dappsys/math.sol";
import { MetaTransactionMsgSender } from "./MetaTransactionMsgSender.sol";
import { MultiChain } from "./MultiChain.sol";
import { IBasicMetaTransaction } from "./IBasicMetaTransaction.sol";

abstract contract BasicMetaTransaction is
  IBasicMetaTransaction,
  DSMath,
  MetaTransactionMsgSender,
  MultiChain
{
  function getMetatransactionNonce(address _user) public view virtual returns (uint256 nonce);

  // NB if implementing this functionality in a contract with recovery mode,
  // you MUST prevent the metatransaction nonces from being editable with recovery mode.
  function incrementMetatransactionNonce(address _user) internal virtual;

  /// @notice Main function to be called when user wants to execute meta transaction.
  /// The actual function to be called should be passed as param with name functionSignature
  /// Here the basic signature recovery is being used. Signature is expected to be generated using
  /// personal_sign method.
  /// @param _user Address of user trying to do meta transaction
  /// @param _payload Function call to make via meta transaction
  /// @param _sigR R part of the signature
  /// @param _sigS S part of the signature
  /// @param _sigV V part of the signature
  /// @return returnData Return data returned by the actual function called
  // slither-disable-next-line locked-ether
  function executeMetaTransaction(
    address _user,
    bytes memory _payload,
    bytes32 _sigR,
    bytes32 _sigS,
    uint8 _sigV
  ) public payable returns (bytes memory returnData) {
    require(
      verify(_user, getMetatransactionNonce(_user), block.chainid, _payload, _sigR, _sigS, _sigV),
      "metatransaction-signer-signature-mismatch"
    );
    incrementMetatransactionNonce(_user);

    // Append _user at the end to extract it from calling context
    bool success;
    (success, returnData) = address(this).call(
      abi.encodePacked(_payload, METATRANSACTION_FLAG, _user)
    );
    require(success, "colony-metatx-function-call-unsuccessful");

    emit MetaTransactionExecuted(_user, msgSender(), _payload);
    return returnData;
  }

  // Builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 _hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
  }

  /// @notice Verifies the signature for the metatransaction
  /// @param _user Address of user trying to do meta transaction
  /// @param _nonce Nonce of the user
  /// @param _chainId Chain id where the signature is valid for
  /// @param _payload Function call to make via meta transaction
  /// @param _sigR R part of the signature
  /// @param _sigS S part of the signature
  /// @param _sigV V part of the signature
  /// @return bool indicating if the signature is valid or not
  function verify(
    address _user,
    uint256 _nonce,
    uint256 _chainId,
    bytes memory _payload,
    bytes32 _sigR,
    bytes32 _sigS,
    uint8 _sigV
  ) public view returns (bool) {
    bytes32 hash = prefixed(keccak256(abi.encodePacked(_nonce, this, _chainId, _payload)));
    address signer = ecrecover(hash, _sigV, _sigR, _sigS);
    require(signer != address(0), "colony-metatx-invalid-signature");
    return (_user == signer);
  }
}
