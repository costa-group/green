pragma solidity ^0.8.0;

struct StrType {
  uint a;
  uint b;
}
  
contract running {
  function fn(StrType memory p) private pure returns (StrType memory o) {
    o.a = p.a;
    o.b = p.b;
  }

  function extfn() external pure returns (StrType memory oo) {
    StrType memory pp = StrType(12,17);
    oo = fn(pp);
  }
}
