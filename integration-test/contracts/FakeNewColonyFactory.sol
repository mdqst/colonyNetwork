
import "IColonyFactory.sol";
import "IUpgradable.sol";
import "IRootColonyResolver.sol";
import "FakeUpdatedColony.sol";

contract FakeNewColonyFactory is IColonyFactory {

  event ColonyCreated(bytes32 colonyKey, address colonyAddress, address colonyOwner, uint now);
  event ColonyDeleted(bytes32 colonyKey, address colonyOwner, uint now);
  event ColonyUpgraded(address colonyAddress, address colonyOwner, uint now);

  modifier onlyRootColony(){
    if(msg.sender != IRootColonyResolver(rootColonyResolverAddress).rootColonyAddress()) throw;
    _
  }

  struct ColonyRecord {
    uint index;
    bool _exists;
  }

  struct ColonyMapping {
    mapping(bytes32 => ColonyRecord) catalog;
    address [] data;
  }

  ColonyMapping colonies;

  function FakeNewColonyFactory()
  refundEtherSentByAccident
  {

  }

  /// @notice this function registers the address of the RootColonyResolver
  /// @param rootColonyResolverAddress_ the default root colony resolver address
  function registerRootColonyResolver(address rootColonyResolverAddress_)
  refundEtherSentByAccident
  onlyOwner
  {
    rootColonyResolverAddress = rootColonyResolverAddress_;
  }

  function createColony(bytes32 key_, address tokenLedger_, address eternalStorage_)
  throwIfIsEmptyBytes32(key_)
  throwIfAddressIsInvalid(tokenLedger_)
  onlyRootColony
  {
    if(colonies.catalog[key_]._exists) throw;

    var colonyIndex = colonies.data.length++;
    var colony = new FakeUpdatedColony(rootColonyResolverAddress, tokenLedger_, eternalStorage_);

    Ownable(tokenLedger_).changeOwner(colony);
    Ownable(eternalStorage_).changeOwner(colony);

    colonies.catalog[key_] = ColonyRecord({index: colonyIndex, _exists: true});
    colonies.data[colonyIndex] = colony;

    ColonyCreated(key_, colony, tx.origin, now);
  }

  function removeColony(bytes32 key_)
  refundEtherSentByAccident
  throwIfIsEmptyBytes32(key_)
  onlyRootColony
  {
    colonies.catalog[key_]._exists = false;
    ColonyDeleted(key_, tx.origin, now);
  }

  function getColony(bytes32 key_) constant returns(address)
  {
    if(!colonies.catalog[key_]._exists) return address(0x0);

    var colonyIndex = colonies.catalog[key_].index;
    return colonies.data[colonyIndex];
  }

  function getColonyAt(uint256 idx_) constant returns(address)
  {
    return colonies.data[idx_];
  }

  function upgradeColony(bytes32 key_)
  {
    uint256 colonyIndex = colonies.catalog[key_].index;
    address colonyAddress = colonies.data[colonyIndex];

    if(!FakeUpdatedColony(colonyAddress).getUserInfo(tx.origin)) throw;

    address tokenLedger = FakeUpdatedColony(colonyAddress).tokenLedger();
    address eStorage = FakeUpdatedColony(colonyAddress).eternalStorage();

    FakeUpdatedColony colonyNew = new FakeUpdatedColony(rootColonyResolverAddress, tokenLedger, eStorage);
    IUpgradable(colonyAddress).upgrade(colonyNew);

    colonies.data[colonyIndex] = colonyNew;
    ColonyUpgraded(colonyNew, tx.origin, now);
  }

  function () {
    // This function gets executed if a
    // transaction with invalid data is sent to
    // the contract or just ether without data.
    // We revert the send so that no-one
    // accidentally loses money when using the
    // contract.
    throw;
  }
}
