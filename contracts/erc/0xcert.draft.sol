pragma solidity ^0.4.19;

import "../math/SafeMath.sol";
import "../ownership/Ownable.sol";

/*
 * @title Xcert
 * @dev Xcert is an implementation of EIP721 and EIP721Metadata. This contract is based on:
 * - EIP721: goo.gl/FLaJc9
 * - OpenZeppelin contract: goo.gl/ybV1aV
 * - nastassiasachs github example: goo.gl/eFrTqz
 * This deed is Burnable:
 * - Deed that can be irreversibly burned (destroyed).
 * This deed is Ownable:
 * - The Ownable contract has an owner address, and provides basic authorization control
 *   functions, this simplifies the implementation of "user permissions".
 */
contract Xcert is Ownable {

  using SafeMath for uint256;

  /*
  * @dev Total number of deeda
  */
  uint256 private totalDeeds;

  /*
   * @dev deed issuer name
   */
  string private issuerName;

  /*
   * @dev deed issuer symbol
   */
  string private issuerSymbol;

  /*
   * @dev A mapping from deed ID to the address that owns it.
   */
  mapping (uint256 => address) private idToOwner;

  /*
   * @dev Mapping from deed ID to approved address
   */
  mapping (uint256 => address) private idToApprovals;

  /*
   * @dev Mapping from deed ID to metadata uri.
   */
  mapping (uint256 => string) private idToUri;

  /*
   * @dev Mapping from Owner address to list of his deed ids.
   */
  mapping (address => uint256[]) private ownerToList;

  /*
   * @dev Mapping from deed ID to its index in ownerToList.
   */
  mapping (uint256 => uint256) private idToIndex;

  /*
   * @dev Sets name and symbol of the deed issuer.
   * @param _name Name of the deed issuer.
   * @param _symbol Symbol of the deed issuer.
   */
  function Xcert(string _name,
                 string _symbol)
    public
  {
    issuerName = _name;
    issuerSymbol = _symbol;
  }

  /*
   * @dev Guarantees msg.sender is owner of the given deed.
   * @param _deedId ID of the deed to validate its ownership belongs to msg.sender.
   */
  modifier onlyOwnerOf(uint256 _deedId) {
    require(ownerOf(_deedId) == msg.sender);
    _;
  }

  /*
   * @notice Find the owner of a deed.
   * @param _deedId The identifier for a deed we are inspecting.
   * @return _owner Address of the deed owner.
   */
  function ownerOf(uint256 _deedId)
    public
    view
    returns (address _owner)
  {
    _owner = idToOwner[_deedId];
    require(_owner != address(0));
  }

  /*
   * @notice Count deeds tracked by this contract.
   * @return A count of valid deed tracked by this contract.
   */
  function countOfDeeds()
    external
    view
    returns (uint256)
  {
    return totalDeeds;
  }

  /*
   * @notice Count all deeds assigent to an owner
   * @param _owner Address where we are interested in deeds owned by them.
   * @return The number of deeds owned by `_owner`, possibly zero
   */
  function countOfDeedsByOwner(address _owner)
    public
    view
    returns (uint256 _count)
  {
    require(_owner != address(0));
    _count = ownerToList[_owner].length;
  }

  /*
   * @notice Enumerate deeds assigned to an owner
   * @param _owner An address where we are interested in deed owned by them.
   * @param _index A counter less than `countOfDeedsByOwner(_owner)`.
   * @return The identifier for the `_index`th deed assigned to `_owner`,
   * (sort order not specified).
   */
  function deedOfOwnerByIndex(address _owner,
                              uint256 _index)
    external
    view
    returns (uint256 _deedId)
  {
    require(_owner != address(0));
    require(_index < ownerToList[_owner].length);
    _deedId = ownerToList[_owner][_index];
  }

  /*
   * @dev Approves another address to claim for the ownership of the given deed ID.
   * @param _to Address to be approved for the given deed ID.
   * @param _deedId ID of the token to be approved.
   */
  function approve(address _to,
                   uint256 _deedId)
    public
    onlyOwnerOf(_deedId)
  {
    address owner = ownerOf(_deedId);
    require(_to != owner);
    require(!(approvedFor(_deedId) == address(0) && _to == address(0)));

    idToApprovals[_deedId] = _to;
    Approval(owner, _to, _deedId);
  }

  /*
   * @dev Claims the ownership of a given deed ID.
   * @param _deedId ID of the deed being claimed by the msg.sender.
   */
  function takeOwnership(uint256 _deedId)
    public
  {
    address from = ownerOf(_deedId);
    address to = msg.sender;

    require(approvedFor(_deedId) == to);
    require(to != from);

    clearApproval(from, _deedId);
    removeDeed(from, _deedId);
    addDeed(to, _deedId);

    Transfer(from, to, _deedId);
  }

  /*
   * @notice Set a new owner for your deed
   * @param _deedId The deed that is being transferred.
   */
  function transfer(address _to,
                    uint256 _deedId)
    onlyOwnerOf(_deedId)
    external
  {
    address from = msg.sender;
    require(_to != address(0));
    require(from != _to);

    clearApproval(from, _deedId);
    removeDeed(from, _deedId);
    addDeed(_to, _deedId);

    Transfer(from, _to, _deedId);
  }

   /*
    * @dev Gets the approved address to take ownership of a given deed ID
    * @param _deedId ID of the deed to query the approval of.
    * @return Address currently approved to take ownership of the given deed ID.
    */
  function approvedFor(uint256 _deedId)
    public
    view
    returns (address)
  {
    return idToApprovals[_deedId];
  }

  /*
   * @dev Internal function to clear current approval of a given deed ID.
   * @param _tokenId ID of the deed to be transferred.
   */
  function clearApproval(address _owner,
                         uint256 _deedId)
    private
  {
    require(ownerOf(_deedId) == _owner);
    delete idToApprovals[_deedId];
    Approval(_owner, 0, _deedId);
  }

  /*
   * @dev Mint deed function.
   * @param _to The address that will own the minted deed.
   * @param _id of the deed to be minted by the msg.sender.
   * @param _uri that points to deed metadata (optional, max length 2083(max length that
   * browsers accept)).
   * @return Id of created deed.
   */
  function mint(address _to,
                 uint256 _id,
                 string _uri)
    external
    onlyOwner()
  {
    require(_to != address(0));
    require(_id != 0);
    require(idToOwner[_id] == address(0));
    require(utfStringLength(_uri) <= 2083);

    idToUri[_id] = _uri;
    addDeed(_to, _id);
    totalDeeds = totalDeeds.add(1);

    Transfer(address(0), _to, _id);
  }

 /*
  * @dev Burns specified Deed.
  * @param _deedId Id of the deed we want to burn.
  */
 function burn(uint256 _deedId)
   onlyOwnerOf(_deedId)
   external
 {
    if (approvedFor(_deedId) != 0) {
      clearApproval(msg.sender, _deedId);
    }

    removeDeed(msg.sender, _deedId);
    delete idToUri[_deedId];
    totalDeeds = totalDeeds.sub(1);

    Transfer(msg.sender, address(0), _deedId);
 }

 /*
  * @dev Removes deed from owner.
  * @param _from Address from wich we want to remove the deed.
  * @param _deedId Which deed we want to remove.
  */
 function removeDeed(address _from,
                     uint256 _deedId)
   private
 {
    require(idToOwner[_deedId] == _from);

    uint256 tokenIndex = idToIndex[_deedId];
    uint256 lastTokenIndex = countOfDeedsByOwner(_from).sub(1);
    uint256 lastToken = ownerToList[_from][lastTokenIndex];

    delete idToOwner[_deedId];

    ownerToList[_from][tokenIndex] = lastToken;
    delete ownerToList[_from][lastTokenIndex];

    ownerToList[_from].length--;
    delete idToIndex[_deedId];
    idToIndex[lastToken] = tokenIndex;
 }

 /*
  * @dev Adds deed from owner.
  * @param _To Address to wich we want to add the deed.
  * @param _deedId Which deed we want to add.
  */
 function addDeed(address _to,
                  uint256 _deedId)
   private
 {
    require(idToOwner[_deedId] == address(0));

    idToOwner[_deedId] = _to;
    uint256 length = ownerToList[_to].length;
    ownerToList[_to].push(_deedId);
    idToIndex[_deedId] = length;
 }

  /*
   * @dev Gets all deed IDs of the specified address.
   * @param _owner Address for the deed's owner.
   * @return _ownedDeedIds Eepresenting all deed IDs owned by the passed address.
   */
  function deedsOf(address _owner)
    external
    view
    returns (uint256[] _ownedDeedIds)
  {
    require(_owner != address(0));
    _ownedDeedIds = ownerToList[_owner];
  }

  /*
   * @notice A descriptive name for a collection of deeds managed by this
   * contract
   * @dev Wallets and exchanges MAY display this to the end user.
   * @return _name Name of the deed issuer.
   */
  function name()
    external
    view
    returns (string _name)
  {
    _name = issuerName;
  }

  /*
  * @notice An abbreviated name for deeds managed by this contract.
  * @dev Wallets and exchanges MAY display this to the end user.
  * @return _symbol Symbol of the deed issuer.
  */
  function symbol()
    external
    view
    returns (string _symbol)
  {
    _symbol = issuerSymbol;
  }

  /*
   * @notice A distinct URI (RFC 3986) for a given token.
   * @param _deedId Id for which we want uri.
   * @return _deedUri Uri of the deed.
   */
  function deedUri(uint256 _deedId)
    external
    view
    returns (string _deedUri)
  {
    require(idToOwner[_deedId] != address(0));
    _deedUri = idToUri[_deedId];
  }

  /*
   * @notice helper function to calculate string length
   * @dev Taken from: https://solidity.readthedocs.io/en/develop/frequently-asked-questions.html:
   * string is basically identical to bytes only that it is assumed to hold the UTF-8 encoding
   * of a real string. Since string stores the data in UTF-8 encoding it is quite expensive to
   * compute the number of characters in the string (the encoding of some characters takes more than
   * a single byte). Because of that, string s; s.length is not yet supported and not even index
   * access s[2]. But if you want to access the low-level byte encoding of the string, you can use
   * bytes(s).length and bytes(s)[2] which will result in the number of bytes in the UTF-8 encoding
   * of the string (not the number of characters) and the second byte (not character) of the UTF-8
   * encoded string, respectively.
   *
   * This function takes the bytes and shifts them to check value and calculate te appropriate
   * length. Based on: https://ethereum.stackexchange.com/questions/13862/is-it-possible-to-check-str
   * ing-variables-length-inside-the-contract/13886
   *
   * @param str string the utf string we want the length of
   * @return length uint256 length of the string
   */
  function utfStringLength(string str)
    internal
    pure
    returns (uint256 length)
  {
    uint256 i = 0;
    bytes memory string_rep = bytes(str);

    while (i < string_rep.length)
    {
      if (string_rep[i] >> 7 == 0)
        i+=1;
      else if (string_rep[i] >> 5 == 0x6)
        i+=2;
      else if (string_rep[i] >> 4 == 0xE)
        i+=3;
      else if (string_rep[i] >> 3 == 0x1E)
        i+=4;
      else
          //For safety
        i+=1;

      length++;
    }
  }

  /// @dev This event emits when ownership of any deed changes by any
  ///  mechanism. This event emits when deeds are created (`from` == 0) and
  ///  destroyed (`to` == 0). Exception: during contract creation, any
  ///  transfers may occur without emitting `Transfer`. At the time of any transfer,
  ///  the "approved taker" is implicitly reset to the zero address.
  event Transfer(address indexed from, address indexed to, uint256 indexed deedId);

  /// @dev The Approve event emits to log the "approved taker" for a deed -- whether
  ///  set for the first time, reaffirmed by setting the same value, or setting to
  ///  a new value. The "approved taker" is the zero address if nobody can take the
  ///  deed now or it is an address if that address can call `takeOwnership` to attempt
  ///  taking the deed. Any change to the "approved taker" for a deed SHALL cause
  ///  Approve to emit. However, an exception, the Approve event will not emit when
  ///  Transfer emits, this is because Transfer implicitly denotes the "approved taker"
  ///  is reset to the zero address.
  event Approval(address indexed from, address indexed to, uint256 indexed deedId);

}
