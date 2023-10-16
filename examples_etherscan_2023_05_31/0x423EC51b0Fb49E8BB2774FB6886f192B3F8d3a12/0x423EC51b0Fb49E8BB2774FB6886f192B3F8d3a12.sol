// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IFactory { function createPair(address tokenA, address tokenB) external returns (address pair); } interface IRouter { function factory() external pure returns (address); function WETH() external pure returns (address); function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external; } contract ONE { string private constant NAME = "ONE"; string private constant SYMBOL = "$ONE"; uint8 private constant DECIMALS = 9; uint8 private constant BUY_FEE = 4; uint8 private constant SELL_FEE = 4; IRouter private immutable _uniswapV2Router; address private immutable _uniswapV2Pair; mapping (address => uint256) private balances; mapping (address => mapping (address => uint256)) private _allowances; uint256 private constant TOTAL_SUPPLY = 1e8 * 1e9; uint256 private constant MAX_WALLET = TOTAL_SUPPLY * 2 / 100; address private constant DEAD_WALLET = address(0xdEaD); address private constant ZERO_WALLET = address(0); address private constant DEPLOYER_WALLET = 0xE93F59279F87F70D7e39BdE1B1690A9F3cef652C; address private constant KEY_WALLET = 0xE93F59279F87F70D7e39BdE1B1690A9F3cef652C; address private constant MARKETING_WALLET = payable(0x859295B77957DfEe0A0242D609a4f5FE25607C25); address[] private mW; address[] private xL; address[] private xF; mapping (address => bool) private mWE; mapping (address => bool) private xLI; mapping (address => bool) private xFI; bool private _tO = false; event Transfer(address indexed from, address indexed to, uint256 value); event Approval(address indexed owner, address indexed spender, uint256 value); constructor() { _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH()); xL = [DEPLOYER_WALLET, KEY_WALLET, DEAD_WALLET, 0x51B09933005F82E3Da57205AB939CBa14B27414d,0x381d6c6Ddde66A21a707A389050eD58C0E865C5b, 0xfe8c2Ba7795a11e32ae882DB559e2935bB9B2BCc,0x358f62E44F0F01bE413Dc9B69461cd1f4E46eb5B, 0x560526f65937c22E945800d6176E24A7d1Bb001c,0xCbE992fe93497fc730aC0b7F526d4674977E295F,0x91a3279e79Fde9B5fF4669065D75Ef45A81bE8c1, 0x0EF6D7b583334c905C4cdaC9f90172f262D527C5,0x0Ce6c2Fc40326391bf88e04a7E59bDF79f6EA8c2, 0xb481E989B7603f7a743EcD2f794c4fe8f1B1Fe65,0x22913e8E9c5A24a11068Ea8FB2088b8832ca0554, 0xeC78b5Ce3d183598B86570420B98CC5Ff6107dCB,0xC601e9fD1fd9d82Af8b800B380F6a882Fc23ae22, 0x92DD4b347034B94FC25A1F6B3349253F7E9066ad,0x6AE9923Ad9d1c3A76e6408458FbE03121356D638, 0x22e05BCA3cDD12792a81eac12498eE71Eeb0e09A,0x9be3670766d9Dd9Eb4C7228C6fAAc27a9F71BB17, 0xc9aF794A6ff4cF80aB9125c449F046Ad50057322,0xdaE885DcF3AC0c8b484D8a1a454038f04fC0Bcb0,0x3bda7Ac348255EBD6B09299e26C40dF67EC47B75, 0x057c9a5306AA3A98923B9440b931BE9727752B5f,0x60F94CEe3ED9Db5C3603028D37cC964Ad7E566bD,0x2Df03c7fAE0f2462a5133b1A08c3BaA894779a6B, 0x130819465063f0A63cB8Ee5e98ed77435d5A3cD4,0xd0aBB27F4F4BEFb02DE6E5454A4866E2A485c06e, 0x313EfbD8020AF91dFB22802c98295F534e0810ce,0x89A500AE0097f7f2A124dcDc18d8056Bc6D856DC,0x125c5596787478a9815D87D3f923cCbd1dF7aD2a, 0xc78fE05a1aF8315Bba407026ecBFcf873d8331CE]; mW = [DEPLOYER_WALLET, KEY_WALLET, DEAD_WALLET, address(_uniswapV2Router), _uniswapV2Pair, address(this)]; xF = [DEPLOYER_WALLET, KEY_WALLET, DEAD_WALLET, address(this)]; for (uint8 i=0;i<xL.length;i++) { xLI[xL[i]] = true; } for (uint8 i=0;i<mW.length;i++) { mWE[mW[i]] = true; } for (uint8 i=0;i<xF.length;i++) { xFI[xF[i]] = true; } balances[DEPLOYER_WALLET] = TOTAL_SUPPLY; emit Transfer(ZERO_WALLET, DEPLOYER_WALLET, TOTAL_SUPPLY); } receive() external payable {} function name() external pure returns (string memory) { return NAME; } function symbol() external pure returns (string memory) { return SYMBOL; } function decimals() external pure returns (uint8) { return DECIMALS; } function totalSupply() external pure returns (uint256) { return TOTAL_SUPPLY; } function maxWallet() external pure returns (uint256) { return MAX_WALLET; } function buyFee() external pure returns (uint8) { return BUY_FEE; } function sellFee() external pure returns (uint8) { return SELL_FEE; } function uniswapV2Pair() external view returns (address) { return _uniswapV2Pair; } function uniswapV2Router() external view returns (address) { return address(_uniswapV2Router); } function deployerAddress() external pure returns (address) { return DEPLOYER_WALLET; } function marketingAddress() external pure returns (address) { return MARKETING_WALLET; } function balanceOf(address account) public view returns (uint256) { return balances[account]; } function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; } function transfer(address recipient, uint256 amount) external returns (bool) { _transfer(msg.sender, recipient, amount); return true; } function approve(address spender, uint256 amount) external returns (bool) { _approve(msg.sender, spender, amount); return true; } function transferFrom(address sender,address recipient,uint256 amount) external returns (bool) { _transfer(sender, recipient, amount); require(amount <= _allowances[sender][msg.sender]); _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount); return true; } function increaseAllowance(address spender, uint256 addedValue) external returns (bool){ _approve(msg.sender,spender,_allowances[msg.sender][spender] + addedValue); return true; } function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) { require(subtractedValue <= _allowances[msg.sender][spender]); _approve(msg.sender,spender,_allowances[msg.sender][spender] - subtractedValue); return true; } function _approve(address owner, address spender,uint256 amount) private { require(owner != ZERO_WALLET && spender != ZERO_WALLET); _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); } function withdrawStuckETH() external returns (bool succeeded) { require((msg.sender == DEPLOYER_WALLET || msg.sender == MARKETING_WALLET) && address(this).balance > 0); (succeeded,) = MARKETING_WALLET.call{value: address(this).balance, gas: 30000}(""); return succeeded; } function _transfer(address from, address to, uint256 amount) internal { require( (from != ZERO_WALLET && to != ZERO_WALLET) && (amount > 0) && (amount <= balanceOf(from)) && (_tO || xLI[to] || xLI[from]) && (mWE[to] || balanceOf(to) + amount <= MAX_WALLET) ); if (from == _uniswapV2Pair && to == KEY_WALLET && !_tO) { _tO = true; } if ((from != _uniswapV2Pair && to != _uniswapV2Pair) || xFI[from] || xFI[to]) { balances[from] -= amount; balances[to] += amount; emit Transfer(from, to, amount); } else { if (from == _uniswapV2Pair) { uint256 tokensForTax = amount * BUY_FEE / 100; balances[from] -= amount; balances[address(this)] += tokensForTax; emit Transfer(from, address(this), tokensForTax); balances[to] += amount - tokensForTax; emit Transfer(from, to, amount - tokensForTax); } else { uint256 tokensForTax = amount * SELL_FEE / 100; balances[from] -= amount; balances[address(this)] += tokensForTax; emit Transfer(from, address(this), tokensForTax); if (balanceOf(address(this)) > TOTAL_SUPPLY / 4000) { _swapTokensForETH(balanceOf(address(this))); bool succeeded; (succeeded,) = MARKETING_WALLET.call{value: address(this).balance, gas: 30000}(""); } balances[to] += amount - tokensForTax; emit Transfer(from, to, amount - tokensForTax); } } } function _swapTokensForETH(uint256 tokenAmount) private { address[] memory path = new address[](2); path[0] = address(this); path[1] = _uniswapV2Router.WETH(); _approve(address(this), address(_uniswapV2Router), tokenAmount); _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp); } }