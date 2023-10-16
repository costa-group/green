// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SHIBPREME is IERC20 {
    string public name = "SHIBPREME Los Angeles CA";
    string public symbol = "PREME";
    uint8 public decimals = 18;
    uint256 private constant _decimalsFactor = 10**18;
    uint256 private constant _totalSupply = 1_000_000_000 * _decimalsFactor;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public deployerWallet = 0x0aDaBB45f02595c87056975e37D77BFE501AcE49;
    address public incomingTaxWallet = 0x257Bd1435bfd4FA29F072c5941AEcd69caB7F8fB;
    address public nullAddress = address(0); // Null address for burning tokens

    uint256 public constant taxPercent = 6;

    mapping(address => uint256) private _lastTransactionTime;
    uint256 public constant cooldownPeriod = 1 minutes;

    // Trusted wallets
    address[] private _trustedWallets;
    address private pinkSaleFactoryAddress = 0x77AEf5dDD6E19b26f49D72D472f6031B8308Eb5b;
    uint256 private pinkSaleStartTime = 1653132000; // 5/21/23 07:00 AM UTC
    uint256 private pinkSaleEndTime = 1653717600; // 5/27/23 10:00 PM UTC

    constructor() {
        _balances[deployerWallet] = _totalSupply;

        emit Transfer(nullAddress, deployerWallet, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _balances[msg.sender], "Insufficient balance");
        require(_isCooldownOver(msg.sender), "Cooldown period is active. Please wait before initiating another transaction");

        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "Approve to the zero address");

        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _balances[sender], "Insufficient balance");
        require(amount <= _allowances[sender][msg.sender], "Transfer amount exceeds allowance");
        require(_isCooldownOver(sender), "Cooldown period is active. Please wait before initiating another transaction");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != nullAddress, "Transfer from the null address"); // Avoid burning from null address

        uint256 taxAmount = (amount * taxPercent) / 100;
        uint256 netAmount = amount - taxAmount;

        _balances[sender] -= amount;
        _balances[recipient] += netAmount;
        _balances[incomingTaxWallet] += taxAmount;

        emit Transfer(sender, recipient, netAmount);
        emit Transfer(sender, incomingTaxWallet, taxAmount);

        _updateLastTransactionTime(sender);
        _updateLastTransactionTime(recipient);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != nullAddress, "Approve from the null address"); // Avoid approving from null address
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _isCooldownOver(address wallet) internal view returns (bool) {
        if (_isTrustedWallet(wallet)) {
            return true;
        }
        return (block.timestamp - _lastTransactionTime[wallet]) >= cooldownPeriod;
    }

    function _updateLastTransactionTime(address wallet) internal {
        _lastTransactionTime[wallet] = block.timestamp;
    }

    // Multisig functions

    struct Transaction {
        address sender;
        address recipient;
        uint256 amount;
        uint256 confirmations;
        mapping(address => bool) isConfirmed;
        bool executed;
    }

    mapping(uint256 => Transaction) private _transactions;
    uint256 private _transactionIndex;

    modifier onlyTrustedWallet() {
        require(_isTrustedWallet(msg.sender), "Caller is not a trusted wallet");
        _;
    }

    function _isTrustedWallet(address wallet) private view returns (bool) {
        for (uint256 i = 0; i < _trustedWallets.length; i++) {
            if (wallet == _trustedWallets[i]) {
                return true;
            }
        }
        return false;
    }

    function addTrustedWallet(address wallet) external onlyTrustedWallet {
        require(wallet != address(0), "Cannot add zero address as a trusted wallet");
        require(!_isTrustedWallet(wallet), "Wallet is already trusted");

        _trustedWallets.push(wallet);
    }

    function removeTrustedWallet(address wallet) external onlyTrustedWallet {
        require(wallet != address(0), "Cannot remove zero address from trusted wallets");
        require(_isTrustedWallet(wallet), "Wallet is not a trusted wallet");

        for (uint256 i = 0; i < _trustedWallets.length; i++) {
            if (wallet == _trustedWallets[i]) {
                _trustedWallets[i] = _trustedWallets[_trustedWallets.length - 1];
                _trustedWallets.pop();
                break;
            }
        }
    }

    function getTrustedWallets() external view returns (address[] memory) {
        return _trustedWallets;
    }

    function initiateTransaction(address recipient, uint256 amount) external onlyTrustedWallet returns (uint256) {
        require(recipient != address(0), "Transaction recipient cannot be zero address");
        require(amount > 0, "Transaction amount must be greater than zero");

        uint256 transactionId = _transactionIndex;
        _transactionIndex++;

        _transactions[transactionId].sender = msg.sender;
        _transactions[transactionId].recipient = recipient;
        _transactions[transactionId].amount = amount;
        _transactions[transactionId].confirmations = 1;
        _transactions[transactionId].isConfirmed[msg.sender] = true;
        _transactions[transactionId].executed = false;

        return transactionId;
    }

    function confirmTransaction(uint256 transactionId) external onlyTrustedWallet {
        require(_transactions[transactionId].sender != address(0), "Transaction does not exist");
        require(!_transactions[transactionId].isConfirmed[msg.sender], "Transaction already confirmed by the wallet");
        require(!_transactions[transactionId].executed, "Transaction has already been executed");

        _transactions[transactionId].isConfirmed[msg.sender] = true;
        _transactions[transactionId].confirmations++;
    }

    function executeTransaction(uint256 transactionId) external onlyTrustedWallet {
        require(_transactions[transactionId].sender != address(0), "Transaction does not exist");
        require(!_transactions[transactionId].executed, "Transaction has already been executed");
        require(
            _transactions[transactionId].confirmations >= 2,
            "Transaction must have at least 2 confirmations to be executed"
        );

        _transfer(
            _transactions[transactionId].sender,
            _transactions[transactionId].recipient,
            _transactions[transactionId].amount
        );
        _transactions[transactionId].executed = true;
    }

    // Token allocation

    function allocateTokens() external {
        require(msg.sender == deployerWallet, "Only deployer can allocate tokens");

        uint256 totalTokens = 120_000 * _decimalsFactor;

        // Calculate the total percentage of shares
        uint256 totalPercentage = 0;
        uint256[] memory percentages = new uint256[](9);
        percentages[0] = 1750; // insurancePolicy: 1.75%
        percentages[1] = 500; // cexListingFees: 0.50%
        percentages[2] = 1000; // R&D: 1.00%
        percentages[3] = 1500; // marketingWallet: 1.50%
        percentages[4] = 750; // womanofBlockchain: 0.75%
        percentages[5] = 1500; // loot8: 1.50%
        percentages[6] = 2000; // liquidity(Preme): 2.00%
        percentages[7] = 1000; // businessDevFund: 1.00%
        percentages[8] = 2000; // rewardsFund: 2.00%

        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }

        // Allocate tokens proportionally based on percentages
        for (uint256 i = 0; i < percentages.length; i++) {
            address wallet = _getWalletAddress(i);
            uint256 allocation = (totalTokens * percentages[i]) / totalPercentage;
            allocation *= 10; // Multiply by 10 to adjust for decimals
            _transfer(deployerWallet, wallet, allocation);
        }
    }

    function _getWalletAddress(uint256 index) private pure returns (address) {
        if (index == 0) return 0x5f93EEA568aBfFBEBEeE35Aaf909545033fd3159; // insurancePolicy
        if (index == 1) return 0x9c16483558F3ABF582B7902742da543Fe57DA73f; // cexListingFees
        if (index == 2) return 0x500930b978321D66dc79CeA3151ec5Fc0e206D65; // R&D
        if (index == 3) return 0xD25526dCA1C008E9D486F9e9b916DC433c06D650; // marketingWallet
        if (index == 4) return 0x3a203014d6F137F517C9393A70F15bB0290438db; // womanofBlockchain
        if (index == 5) return 0x4a6103b0D5fA9110E3cc199FC3657cAD3eA6C137; // loot8
        if (index == 6) return 0x337aF85c4d7Fd5Fb4CF9cDe85EbC946B688600D9; // liquidity(Preme)
        if (index == 7) return 0x57b8BFDA02eC95D9C01fDb1561CD9Ec2Fe955Ffa; // businessDevFund
        if (index == 8) return 0x5fD3f4633EdE6913818d1f6Ee88a31e2c5d8cb71; // rewardsFund

        revert("Invalid wallet index");
    }
}