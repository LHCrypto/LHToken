pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns (uint256);

    function transfer(address to, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);

    function transferFrom(address from, address to, uint256 value);

    function approve(address spender, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;
    mapping (address => bool) public onChain;
    address[] public ownersOfToken;


    function ownersLen() constant returns (uint256) { return ownersOfToken.length; }
    function ownerAddress(uint256 number) constant returns (address) { return ownersOfToken[number]; }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) {

        require(balances[msg.sender] >= _value);
        // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to]);
        // Check for overflows

        if (!onChain[_to]){
            ownersOfToken.push(_to);
            onChain[_to] = true;
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    // burn tokens from sender balance
    function burn(uint256 _value) {

        require(balances[msg.sender] >= _value);
        // Check if the sender has enough

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }


    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;
    address[] public ownersOfToken;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;
        if (!onChain[_to]){
            ownersOfToken.push(_to);
        }
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract Ownable {

    address public owner;
    address public manager;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }



    function setManager(address _manager) onlyOwner {
        manager = _manager;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    string public name = "LHCoin";

    string public symbol = "LHC";

    uint256 public decimals = 8;

    uint256 public decimalMultiplier = 100000000;

    bool public mintingFinished = false;

    address bountyCoin;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function MintableToken(){
        mint(msg.sender, 70000000 * decimalMultiplier);
        finishMinting();
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function exchangeBounty(address user, uint amount) {
        assert(msg.sender == bountyCoin);
        balances[user] = amount;
        totalSupply += amount;
    }

    function setBountyCoin(address _bountyCoin) onlyAdmin {
        bountyCoin = _bountyCoin;
    }
}


contract BasicTokensale is Ownable {

    using SafeMath for uint256;

    // The token being sold
    MintableToken public token;

    //start date
    uint public start;

    // deadline tokenslae
    uint public deadline;

    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    // how many tokens sold by this contract
    uint public tokensSold;

    // how many tokens was sold without ethers
    uint public tokonesSoldWithoutEthers = 0;

    struct tokenBuyer {
    address memberAddr;
    uint tokenCount;
    }

    // token buyers from pre ICO
    tokenBuyer[] public buyers;

    modifier afterdeadline() {
        require(now > deadline);
        _;
    }

    mapping (bytes32 => bool) validIds;

    event updatedPrice(string price);

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // first parameter is address token for reward
    function BasicTokensale(MintableToken tokenContract, address _wallet) {
        require(_wallet != 0x0);

        //token = createTokenContract(); // do not create a new token contract
        token = tokenContract;
        // but use deployed token contract
        start = 1509310800;
        deadline = 1512334860;
        // set in minutes for testing
        wallet = _wallet;
    }

    // send some tokens from contract by owner
    function transferTokens(address _to, uint tokensCount) onlyAdmin {
        require(token.balanceOf(this) >= tokensCount + 1);
        token.transfer(_to, tokensCount);
        tokonesSoldWithoutEthers = tokonesSoldWithoutEthers.add(tokensCount);
    }

    // set new token contract owner
    function setNewTokenOwner(address newOwner) onlyOwner {
        token.transferOwnership(newOwner);
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return (now > deadline);
    }

    function hasStarted() public constant returns (bool) {
        return (now > start);
    }

    function addBuyer(address buyer, uint amount) internal {
        tokenBuyer memory newBuyer;
        // = tokenBuyer(buyer,amount);
        newBuyer.memberAddr = buyer;
        newBuyer.tokenCount = amount;
        buyers.push(newBuyer);
    }

    function buyersLength() public constant returns (uint) {
        return buyers.length;
    }
}


contract PreSale is BasicTokensale {

    mapping (address => uint256) public balances;
    mapping (address => bool) public alreadyGet;
    // how much tokens we distribute in presale
    uint public tokensForSale;
    // minimal token price
    uint public minTokenPrice;
    // final token price
    uint public finTokenPrice;
    // if price is already calculated
    bool public isCalculated;
    // if token already sended
    bool public isTokenSended;

    // ether senders list
    address[] public senders;

    uint safeCounter = 0;

    function PreSale
    (MintableToken tokenContract,
    address _wallet)
    BasicTokensale(tokenContract ,_wallet)
    {
        tokensForSale = 20000000;
        //0.1$ in wei
        minTokenPrice = 308000000000000;
        isCalculated = false;
        isTokenSended = false;
    }

    // receive ether
    function() payable {
        assert(!hasEnded() && hasStarted());
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        senders.push(msg.sender);
        weiRaised = weiRaised.add(msg.value);
        forwardFunds();
    }

    function setMinPrice(uint _actualMinPrice) onlyAdmin {
        minTokenPrice = _actualMinPrice;
    }

    // transfer received founds to benefeciary wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // final calculate price
    function calculatePrice() afterdeadline onlyAdmin {
        require(!isCalculated);

        finTokenPrice = weiRaised.div(tokensForSale.mul(100000000) - tokonesSoldWithoutEthers);
        finTokenPrice = finTokenPrice.mul(100000000);
        isCalculated = true;
    }

    function safeTokenReward(uint _number) afterdeadline onlyAdmin {
        require(isCalculated);
        uint limit = safeCounter.add(_number);
        if (limit > senders.length) {
            limit = senders.length;
        }
        for (uint i = safeCounter; i < limit; i++) {
            if (balances[senders[i]] > 0 && !alreadyGet[senders[i]]) {
                uint tokens = (balances[senders[i]]).div(finTokenPrice).mul(100000000);
                token.transfer(senders[i], tokens);
                addBuyer(senders[i], tokens);
                tokensSold = tokensSold.add(tokens);
                alreadyGet[senders[i]] = true;
            }
        }
        safeCounter = limit;
    }


    // send tokens for every buyer
    function tokenReward() afterdeadline onlyAdmin {
        require(isCalculated);
        require(!isTokenSended);
        for (uint i = 0; i < senders.length; i++) {
            if (balances[senders[i]] > 0 && !alreadyGet[senders[i]]) {
                uint tokens = (balances[senders[i]]).div(finTokenPrice).mul(100000000);
                token.transfer(senders[i], tokens);
                addBuyer(senders[i], tokens);
                tokensSold = tokensSold.add(tokens);
                alreadyGet[senders[i]] = true;
            }
        }
        isTokenSended = true;
    }

    function getTokenBack(address _owner, uint amount) onlyOwner {
        token.transfer(_owner, amount);
    }
}

