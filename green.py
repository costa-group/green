import importlib
import sys
import os
import six
import argparse

sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/ethir_complete/ethir")
sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/gasol_optimizer")

import ethir_complete.ethir.oyente_ethir as ethir_main
import ethir_complete.ethir.symExec as symExec
from ethir_complete.ethir.input_helper import InputHelper
import ethir_complete.ethir.global_params as global_params
# import gasol_optimizer.gasol_asm as gasol_main
from timeit import default_timer as dtimer
import traceback

def parse_args():    
    global args

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)

    group.add_argument("-s",  "--source",    type=str, help="local source file name. Solidity by default. Use -b to process evm instead. Use stdin to read from stdin.")

    parser.add_argument("-glt", "--global-timeout", help="Timeout for symbolic execution", action="store", dest="global_timeout", type=int)
    parser.add_argument( "-e",   "--evm",                    help="Do not remove the .evm file.", action="store_true")
    parser.add_argument( "-b",   "--bytecode",               help="read bytecode in source instead of solidity file", action="store_true")
    
    #Added by Pablo Gordillo
    parser.add_argument( "-d", "--debug",                   help="Display the status of the stack after each opcode", action = "store_true")
    parser.add_argument( "-cfg", "--control-flow-graph",    help="Store the CFG", choices=["normal","memory"])
    parser.add_argument("-optimize-run", "--optimize-run",             help="Enable optimization flag in solc compiler", action="store_true")
    parser.add_argument("-run", "--run",             help="Set for how many contract runs to optimize (200 by default if --optimize-run)", default=-1,action="store",type=int)
    parser.add_argument("-no-yul-opt", "--no-yul-opt",             help="Disable yul optimization in solc compiler (when possible)", action="store_true")
    parser.add_argument("-via-ir", "--via-ir",             help="via-ir optimization in solc compiler (when possible)", action="store_true")
    parser.add_argument( "-hashes", "--hashes",             help="Generate a file that contains the functions of the solidity file", action="store_true")
    parser.add_argument( "-out", "--out",             help="Generate a file that contains the functions of the solidity file", action="store", dest="path_out",type=str)
    parser.add_argument("-mem-analysis", "--mem-analysis",             help="Executes memory analysis. baseref runs the basic analysis where it only identifies the base refences. Offset runs baseref+offset option", choices = ["baseref","offset"])


    args = parser.parse_args()
    
    global_params.PRINT_PATHS = 0 #1 if args.paths else 0
    global_params.REPORT_MODE = 0 #1  if args.report else 0
    global_params.USE_GLOBAL_BLOCKCHAIN = 0#1 if args.globalblockchain else 0
    global_params.INPUT_STATE = 0#1 if args.state else 0
    global_params.WEB = 0#1 if args.web else 0
    global_params.STORE_RESULT = 0#1 if args.json else 0
    global_params.CHECK_ASSERTIONS = 0#1 if args.assertion else 0
    global_params.DEBUG_MODE = 0#1 if args.debug else 0
    global_params.GENERATE_TEST_CASES = 0#1 if args.generate_test_cases else 0
    global_params.PARALLEL = 0#1 if args.parallel else 0

    if args.path_out:
        global_params.tmp_path = args.path_out
        global_params.costabs_path = global_params.tmp_path+"costabs/"


def analyze_solidity(input_type='solidity'):
    global args

    x = dtimer()
    is_runtime = True

    compiler_opt = {}
    compiler_opt["optimize"] = args.optimize_run
    compiler_opt["no-yul"] = args.no_yul_opt
    compiler_opt["runs"] = args.run
    compiler_opt["via-ir"] = args.via_ir

    if input_type == 'solidity':
        print(args)
        helper = InputHelper(InputHelper.SOLIDITY, source=args.source,evm =args.evm,runtime=is_runtime,opt_options = compiler_opt)

    inputs = helper.get_inputs()
    solc_version = helper.get_solidity_version()

    hashes = ethir_main.process_hashes(args.source,solc_version)
    
    y = dtimer()
    print("*************************************************************")
    print("Compilation time: "+str(y-x)+"s")
    print("*************************************************************")

    results, exit_code = run_solidity_analysis(inputs,hashes)
    helper.rm_tmp_files()

    return exit_code


def run_solidity_analysis(inputs,hashes):
    results = {}
    exit_code = 0
    returns = []
    
    i = 0
        
    if len(inputs) == 1:
        inp = inputs[0]
        function_names = hashes[inp["c_name"]]
        try:
            result, return_code = symExec.run(disasm_file=inp['disasm_file'], disasm_file_init = inp['disasm_file_init'], source_map=inp['source_map'], source_file=inp['source'],cfg = args.control_flow_graph,execution = 0, cname = inp["c_name"],hashes = function_names,debug = args.debug,evm_version = True,svc = {},opt_bytecode = (args.optimize_run or args.via_ir), mem_analysis = args.mem_analysis)
            
        except Exception as e:
            traceback.print_exc()

            if len(e.args)>1:
                return_code = e.args[1]
            else:
                return_code = 1
            result = []
            #return_code = -1
            print ("\n Exception: "+str(return_code)+"\n")
            exit_code = return_code
            
    elif len(inputs)>1:
        for inp in inputs:
            #print hashes[inp["c_name"]]
            function_names = hashes[inp["c_name"]]
            #logging.info("contract %s:", inp['contract'])
            try:            
                result, return_code = symExec.run(disasm_file=inp['disasm_file'], disasm_file_init = inp['disasm_file_init'], source_map=inp['source_map'], source_file=inp['source'],cfg = args.control_flow_graph,saco = args.saco,execution = i,cname = inp["c_name"],hashes = function_names,debug = args.debug,evm_version = True, svc = {}, opt_bytecode = (args.optimize_run or args.via_ir), mem_analysis = args.mem_analysis)
                
            except Exception as e:
                traceback.print_exc()
                if len(e.args)>1:
                    return_code = e.args[1]
                else:
                    return_code = 1
                    
                result = []
                # return_code = -1
                print ("\n Exception: "+str(return_code)+"\n")
            i+=1
            returns.append(return_code)
            try:
                c_source = inp['c_source']
                c_name = inp['c_name']
                results[c_source][c_name] = result
            except:
                results[c_source] = {c_name: result}

            if return_code == 1:
                exit_code = 1


    '''
    Exception management:
    1- Oyente Error
    2- Oyente TimeOut
    3- Cloning Error
    4- RBR generation Error
    5- SACO Error
    6- C Error
    '''
        
    if (1 in returns):
        exit_code = 1
    elif (2 in returns):
        exit_code = 2
    elif (3 in returns):
        exit_code = 3
    elif (7 in returns):
        exit_code = 7
    elif (4 in returns):
        exit_code = 4
    elif (5 in returns):
        exit_code = 5
    elif (6 in returns):
        exit_code = 6

    symExec.print_daos()
        
    return results, exit_code


        
def run_ethir():
    if not ethir_main.has_dependencies_installed():
        return

    ethir_main.clean_dir()

    #Added by Pablo Gordillo

    if args.bytecode:
        exit_code = ethir_main.analyze_bytecode()

    elif ethir_main.hashes_cond(args):

        is_runtime = True

        compiler_opt = {}
        compiler_opt["optimize"] = args.optimize_run
        compiler_opt["no-yul"] = args.no_yul_opt
        compiler_opt["runs"] = args.run
        compiler_opt["via-ir"] = args.via_ir
        helper = InputHelper(InputHelper.SOLIDITY, source=args.source,evm =args.evm,runtime=is_runtime,opt_options = compiler_opt)

        solc_version = helper.get_solidity_version()
        
        mp = ethir_main.process_hashes(args.source, solc_version)
        ethir_main.generate_saco_hashes_file(mp)
        exit_code = 0
        
    else:
        exit_code = analyze_solidity()
    six.print_("The files generated by EthIR are stored in the following directory: "+global_params.costabs_path)

    exit(exit_code)


def run_gasol():
    pass

if __name__ == "__main__":
    print("Green Main")
    parse_args()
    run_ethir()
