# green

Green is a superoptimization tool for Ethereum smart contracts. We have integrated in the superoptimizer GASOL a global heap analysis that allows us to infer useless write heap accesses, aliasing and non-aliasing properties, and calling-contexts for EVM bytecode sequences.
Green is built on top of two tools, [EthIR](https://github.com/costa-group/EthIR), a decompiler of EVM bytecode that generates a complete and sounf CFG of the smart contract under analysis, and [GASOL](https://github.com/costa-group/gasol-optimizer/tree/main), a superoptmization tool of EVM bytecode. In order to install Green, you have to check the requirements of each of these tools in their corresponding README files. After that, once you have cloned this repository, execute the following command to finish the installation:

```
git submodule init
git submodule update
```

## Usage

Green optimizes all basic blocks obtained from the CFG of the smart contract that have memory information. Execute the following command to analyze a smart contract: 

```
./green.py -s examples/running.sol -mem-analysis offset --compact-clones -optimize-run --via-ir [MEMORY-OPTIMIZATION-FLAGS]
```
 The memory optimization flags [MEMORY-OPTIMIZATION-FLAGS] can be either:
 * --aliasing-info: It uses the inferred information of aliasing and non-aliasing in the optimization process of the block.
 * --useless-info: It uses the information of the useless STORE operations in the optimization process of the block.
 * --context-info: It uses the constancy information and the aliasing information about the context to optimize the block.

Note that all the memory options can be combined with each other.


 ## Contributors
* Elvira Albert
* Jesús Correas
* Pablo Gordillo
* Alejandro Hernández-Cerezo
* Guillermo Román-Díez
* Albert Rubio
