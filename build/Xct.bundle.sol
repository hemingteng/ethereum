pragma solidity ^0.4.19;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a / b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The contract has an owner address, and provides basic authorization control
 * whitch simplifies the implementation of user permissions. This contract is based
 * on the source code at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner)
    onlyOwner
    public
  {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/tokens/Xct.sol

/*
 * @title XCT protocol token.
 * @dev Standard ERC20 token used by the protocol. This contract follows the
 * implementation at https://goo.gl/64yCkF. 
 */
contract Xct is Ownable {
  using SafeMath for uint256;

  /**
   * Token name.
   */
  string public name;

  /**
   * Token symbol.
   */
  string public symbol;

  /**
   * Nubber of decimals.
   */
  uint8 public decimals;

  /**
   * Ballance information map.
   */
  mapping (address => uint256) internal balances;

  /**
   * Number of tokens in circulation.
   */
  uint256 internal currentSupply;

  /**
   * Allowance information map.
   */
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * Transfer feature state.
   */
  bool public transferEnabled;

  /**
   * @dev An event which is triggered when funds are transfered.
   * @param _from The address sending tokens.
   * @param _to The address recieving tokens.
   * @param _value The amount of transferred tokens.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev An event which is triggered when an address to spend the specified amount of
   * tokens on behalf is approved.
   * @param _owner The address of an owner.
   * @param _spender The address which spent the funds.
   * @param _value The amount of spent tokens.
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev An event which is triggered when tokens are burned.
   * @param _burner The address which burns tokens.
   * @param _value The amount of burned tokens.
   */
  event Burn(address indexed _burner, uint256 _value);

  /**
   * @dev Assures that the provided address is a valid destination to transfer tokens to.
   * @param _to Target address.
   */
  modifier validDestination(address _to) {
    require(_to != address(0x0));
    require(_to != address(this));
    _;
  }

  /**
   * @dev Assures that tokens can be transfered.
   */
  modifier onlyWhenTransferAllowed() {
    require(transferEnabled);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  function Xct()
    public
  {
    name = "0xcert Protocol Token";
    symbol = "XCT";
    decimals = 18;
    currentSupply = 400000000000000000000000000;
    transferEnabled = false;

    balances[owner] = currentSupply;
    Transfer(address(0x0), owner, currentSupply);
  }

  /**
   * @dev Returns the total number of tokens in circulation. This function is based on BasicToken
   * implementation at goo.gl/GZEhaq.
   */
  function totalSupply()
    public
    view
    returns (uint256)
  {
    return currentSupply;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param _from address The address which you want to send tokens from.
   * @param _to address The address which you want to transfer to.
   * @param _value uint256 the amount of tokens to be transferred.
   */
  function transferFrom(address _from, address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   */
  function balanceOf(address _owner)
    public
    view
    returns (uint256)
  {
    return balances[_owner];
  }

  /**
   * @dev Approves the passed address to spend the specified amount of tokens on behalf
   * of the msg.sender. This function is based on StandardToken implementation at goo.gl/GZEhaq
   * and goo.gl/fG8R4i.
   * To change the approve amount you first have to reduce the spender's allowance to zero by
   * calling `approve(_spender, 0)` if it is not already 0 to mitigate the race condition described
   * here https://goo.gl/7n9A4J.
   * @param _spender The address which will spend the funds.
   * @param _value The allowed amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    returns (bool)
  {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Returns the amount of tokens that a spender can transfer on behalf of an owner. This
   * function is based on StandardToken implementation at goo.gl/GZEhaq.
   * @param _owner The address which owns the funds.
   * @param _spender The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Enables token transfers.
   */
  function enableTransfer()
    onlyOwner()
    external
  {
    transferEnabled = true;
  }

  /**
   * @dev Burns a specific amount of tokens. Only owner is allowed to perform this operation. This
   * function is based on BurnableToken implementation at goo.gl/GZEhaq.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value)
    onlyOwner()
    public
  {
    require(_value <= balances[msg.sender]);

    balances[owner] = balances[owner].sub(_value);
    currentSupply = currentSupply.sub(_value);

    Burn(owner, _value);
    Transfer(owner, address(0x0), _value);
  }

}
pragma solidity ^0.4.19;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a / b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The contract has an owner address, and provides basic authorization control
 * whitch simplifies the implementation of user permissions. This contract is based
 * on the source code at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner)
    onlyOwner
    public
  {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/tokens/Xct.sol

/*
 * @title XCT protocol token.
 * @dev Standard ERC20 token used by the protocol. This contract follows the
 * implementation at https://goo.gl/64yCkF. 
 */
contract Xct is Ownable {
  using SafeMath for uint256;

  /**
   * Token name.
   */
  string public name;

  /**
   * Token symbol.
   */
  string public symbol;

  /**
   * Nubber of decimals.
   */
  uint8 public decimals;

  /**
   * Ballance information map.
   */
  mapping (address => uint256) internal balances;

  /**
   * Number of tokens in circulation.
   */
  uint256 internal currentSupply;

  /**
   * Allowance information map.
   */
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * Transfer feature state.
   */
  bool public transferEnabled;

  /**
   * @dev An event which is triggered when funds are transfered.
   * @param _from The address sending tokens.
   * @param _to The address recieving tokens.
   * @param _value The amount of transferred tokens.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev An event which is triggered when an address to spend the specified amount of
   * tokens on behalf is approved.
   * @param _owner The address of an owner.
   * @param _spender The address which spent the funds.
   * @param _value The amount of spent tokens.
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev An event which is triggered when tokens are burned.
   * @param _burner The address which burns tokens.
   * @param _value The amount of burned tokens.
   */
  event Burn(address indexed _burner, uint256 _value);

  /**
   * @dev Assures that the provided address is a valid destination to transfer tokens to.
   * @param _to Target address.
   */
  modifier validDestination(address _to) {
    require(_to != address(0x0));
    require(_to != address(this));
    _;
  }

  /**
   * @dev Assures that tokens can be transfered.
   */
  modifier onlyWhenTransferAllowed() {
    require(transferEnabled);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  function Xct()
    public
  {
    name = "0xcert Protocol Token";
    symbol = "XCT";
    decimals = 18;
    currentSupply = 400000000000000000000000000;
    transferEnabled = false;

    balances[owner] = currentSupply;
    Transfer(address(0x0), owner, currentSupply);
  }

  /**
   * @dev Returns the total number of tokens in circulation. This function is based on BasicToken
   * implementation at goo.gl/GZEhaq.
   */
  function totalSupply()
    public
    view
    returns (uint256)
  {
    return currentSupply;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param _from address The address which you want to send tokens from.
   * @param _to address The address which you want to transfer to.
   * @param _value uint256 the amount of tokens to be transferred.
   */
  function transferFrom(address _from, address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   */
  function balanceOf(address _owner)
    public
    view
    returns (uint256)
  {
    return balances[_owner];
  }

  /**
   * @dev Approves the passed address to spend the specified amount of tokens on behalf
   * of the msg.sender. This function is based on StandardToken implementation at goo.gl/GZEhaq
   * and goo.gl/fG8R4i.
   * To change the approve amount you first have to reduce the spender's allowance to zero by
   * calling `approve(_spender, 0)` if it is not already 0 to mitigate the race condition described
   * here https://goo.gl/7n9A4J.
   * @param _spender The address which will spend the funds.
   * @param _value The allowed amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    returns (bool)
  {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Returns the amount of tokens that a spender can transfer on behalf of an owner. This
   * function is based on StandardToken implementation at goo.gl/GZEhaq.
   * @param _owner The address which owns the funds.
   * @param _spender The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Enables token transfers.
   */
  function enableTransfer()
    onlyOwner()
    external
  {
    transferEnabled = true;
  }

  /**
   * @dev Burns a specific amount of tokens. Only owner is allowed to perform this operation. This
   * function is based on BurnableToken implementation at goo.gl/GZEhaq.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value)
    onlyOwner()
    public
  {
    require(_value <= balances[msg.sender]);

    balances[owner] = balances[owner].sub(_value);
    currentSupply = currentSupply.sub(_value);

    Burn(owner, _value);
    Transfer(owner, address(0x0), _value);
  }

}
pragma solidity ^0.4.19;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a / b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The contract has an owner address, and provides basic authorization control
 * whitch simplifies the implementation of user permissions. This contract is based
 * on the source code at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner)
    onlyOwner
    public
  {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/tokens/Xct.sol

/*
 * @title XCT protocol token.
 * @dev Standard ERC20 token used by the protocol. This contract follows the
 * implementation at https://goo.gl/64yCkF. 
 */
contract Xct is Ownable {
  using SafeMath for uint256;

  /**
   * Token name.
   */
  string public name;

  /**
   * Token symbol.
   */
  string public symbol;

  /**
   * Nubber of decimals.
   */
  uint8 public decimals;

  /**
   * Ballance information map.
   */
  mapping (address => uint256) internal balances;

  /**
   * Number of tokens in circulation.
   */
  uint256 internal currentSupply;

  /**
   * Allowance information map.
   */
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * Transfer feature state.
   */
  bool public transferEnabled;

  /**
   * @dev An event which is triggered when funds are transfered.
   * @param _from The address sending tokens.
   * @param _to The address recieving tokens.
   * @param _value The amount of transferred tokens.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev An event which is triggered when an address to spend the specified amount of
   * tokens on behalf is approved.
   * @param _owner The address of an owner.
   * @param _spender The address which spent the funds.
   * @param _value The amount of spent tokens.
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev An event which is triggered when tokens are burned.
   * @param _burner The address which burns tokens.
   * @param _value The amount of burned tokens.
   */
  event Burn(address indexed _burner, uint256 _value);

  /**
   * @dev Assures that the provided address is a valid destination to transfer tokens to.
   * @param _to Target address.
   */
  modifier validDestination(address _to) {
    require(_to != address(0x0));
    require(_to != address(this));
    _;
  }

  /**
   * @dev Assures that tokens can be transfered.
   */
  modifier onlyWhenTransferAllowed() {
    require(transferEnabled);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  function Xct()
    public
  {
    name = "0xcert Protocol Token";
    symbol = "XCT";
    decimals = 18;
    currentSupply = 400000000000000000000000000;
    transferEnabled = false;

    balances[owner] = currentSupply;
    Transfer(address(0x0), owner, currentSupply);
  }

  /**
   * @dev Returns the total number of tokens in circulation. This function is based on BasicToken
   * implementation at goo.gl/GZEhaq.
   */
  function totalSupply()
    public
    view
    returns (uint256)
  {
    return currentSupply;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param _from address The address which you want to send tokens from.
   * @param _to address The address which you want to transfer to.
   * @param _value uint256 the amount of tokens to be transferred.
   */
  function transferFrom(address _from, address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   */
  function balanceOf(address _owner)
    public
    view
    returns (uint256)
  {
    return balances[_owner];
  }

  /**
   * @dev Approves the passed address to spend the specified amount of tokens on behalf
   * of the msg.sender. This function is based on StandardToken implementation at goo.gl/GZEhaq
   * and goo.gl/fG8R4i.
   * To change the approve amount you first have to reduce the spender's allowance to zero by
   * calling `approve(_spender, 0)` if it is not already 0 to mitigate the race condition described
   * here https://goo.gl/7n9A4J.
   * @param _spender The address which will spend the funds.
   * @param _value The allowed amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    returns (bool)
  {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Returns the amount of tokens that a spender can transfer on behalf of an owner. This
   * function is based on StandardToken implementation at goo.gl/GZEhaq.
   * @param _owner The address which owns the funds.
   * @param _spender The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Enables token transfers.
   */
  function enableTransfer()
    onlyOwner()
    external
  {
    transferEnabled = true;
  }

  /**
   * @dev Burns a specific amount of tokens. Only owner is allowed to perform this operation. This
   * function is based on BurnableToken implementation at goo.gl/GZEhaq.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value)
    onlyOwner()
    public
  {
    require(_value <= balances[msg.sender]);

    balances[owner] = balances[owner].sub(_value);
    currentSupply = currentSupply.sub(_value);

    Burn(owner, _value);
    Transfer(owner, address(0x0), _value);
  }

}
pragma solidity ^0.4.19;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a / b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The contract has an owner address, and provides basic authorization control
 * whitch simplifies the implementation of user permissions. This contract is based
 * on the source code at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner)
    onlyOwner
    public
  {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/tokens/Xct.sol

/*
 * @title XCT protocol token.
 * @dev Standard ERC20 token used by the protocol. This contract follows the
 * implementation at https://goo.gl/64yCkF. 
 */
contract Xct is Ownable {
  using SafeMath for uint256;

  /**
   * Token name.
   */
  string public name;

  /**
   * Token symbol.
   */
  string public symbol;

  /**
   * Nubber of decimals.
   */
  uint8 public decimals;

  /**
   * Ballance information map.
   */
  mapping (address => uint256) internal balances;

  /**
   * Number of tokens in circulation.
   */
  uint256 internal currentSupply;

  /**
   * Allowance information map.
   */
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * Transfer feature state.
   */
  bool public transferEnabled;

  /**
   * @dev An event which is triggered when funds are transfered.
   * @param _from The address sending tokens.
   * @param _to The address recieving tokens.
   * @param _value The amount of transferred tokens.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev An event which is triggered when an address to spend the specified amount of
   * tokens on behalf is approved.
   * @param _owner The address of an owner.
   * @param _spender The address which spent the funds.
   * @param _value The amount of spent tokens.
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev An event which is triggered when tokens are burned.
   * @param _burner The address which burns tokens.
   * @param _value The amount of burned tokens.
   */
  event Burn(address indexed _burner, uint256 _value);

  /**
   * @dev Assures that the provided address is a valid destination to transfer tokens to.
   * @param _to Target address.
   */
  modifier validDestination(address _to) {
    require(_to != address(0x0));
    require(_to != address(this));
    _;
  }

  /**
   * @dev Assures that tokens can be transfered.
   */
  modifier onlyWhenTransferAllowed() {
    require(transferEnabled);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  function Xct()
    public
  {
    name = "0xcert Protocol Token";
    symbol = "XCT";
    decimals = 18;
    currentSupply = 400000000000000000000000000;
    transferEnabled = false;

    balances[owner] = currentSupply;
    Transfer(address(0x0), owner, currentSupply);
  }

  /**
   * @dev Returns the total number of tokens in circulation. This function is based on BasicToken
   * implementation at goo.gl/GZEhaq.
   */
  function totalSupply()
    public
    view
    returns (uint256)
  {
    return currentSupply;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param _from address The address which you want to send tokens from.
   * @param _to address The address which you want to transfer to.
   * @param _value uint256 the amount of tokens to be transferred.
   */
  function transferFrom(address _from, address _to, uint256 _value)
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value); // will fail on insufficient funds
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   */
  function balanceOf(address _owner)
    public
    view
    returns (uint256)
  {
    return balances[_owner];
  }

  /**
   * @dev Approves the passed address to spend the specified amount of tokens on behalf
   * of the msg.sender. This function is based on StandardToken implementation at goo.gl/GZEhaq
   * and goo.gl/fG8R4i.
   * To change the approve amount you first have to reduce the spender's allowance to zero by
   * calling `approve(_spender, 0)` if it is not already 0 to mitigate the race condition described
   * here https://goo.gl/7n9A4J.
   * @param _spender The address which will spend the funds.
   * @param _value The allowed amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    returns (bool)
  {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Returns the amount of tokens that a spender can transfer on behalf of an owner. This
   * function is based on StandardToken implementation at goo.gl/GZEhaq.
   * @param _owner The address which owns the funds.
   * @param _spender The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Enables token transfers.
   */
  function enableTransfer()
    onlyOwner()
    external
  {
    transferEnabled = true;
  }

  /**
   * @dev Burns a specific amount of tokens. Only owner is allowed to perform this operation. This
   * function is based on BurnableToken implementation at goo.gl/GZEhaq.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value)
    onlyOwner()
    public
  {
    require(_value <= balances[msg.sender]);

    balances[owner] = balances[owner].sub(_value);
    currentSupply = currentSupply.sub(_value);

    Burn(owner, _value);
    Transfer(owner, address(0x0), _value);
  }

}
