pragma solidity ^0.8.0;

struct StrType {
  uint a;
  uint b;
}
  
contract running {
  function fn() private pure returns (StrType memory o) {
    o.a = 17;
    o.b = 14;
  }

  function extfn() external pure returns (StrType memory oo) {
    oo = fn();
  }
}
