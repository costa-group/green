// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function owner() external view returns (address);

  function transferOwnership(address newOwner) external;

  // function renounceOwnership() external;
}
