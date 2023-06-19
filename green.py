import importlib
import sys
import os

sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/ethir_complete/ethir")
sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/gasol_optimizer")

if __name__ == "__main__":
    print("Green Main")
    import ethir_complete.ethir.oyente_ethir as e
    e.analyze_solidity()
