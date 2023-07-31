#!/usr/bin/python3

import importlib
import sys
import os
import six
import argparse
import shutil

sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/ethir_complete/ethir")
sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/gasol_optimizer")

import ethir_complete.ethir.oyente_ethir as ethir_main
import ethir_complete.ethir.symExec as symExec
from ethir_complete.ethir.input_helper import InputHelper
from ethir_complete.ethir.memory_optimizer_connector import OptimizableBlockInfo
import ethir_complete.ethir.global_params_ethir as global_params
import gasol_optimizer.gasol_asm as gasol_main
from timeit import default_timer as dtimer
import traceback



import gasol_optimizer.global_params.constants as constants
import gasol_optimizer.global_params.paths as paths
import gasol_optimizer.sfs_generator.ir_block as ir_block
from gasol_optimizer.sfs_generator.gasol_optimization import get_sfs_dict
from gasol_optimizer.sfs_generator.parser_asm import (parse_asm,
                                      generate_block_from_plain_instructions,
                                      parse_blocks_from_plain_instructions)
from gasol_optimizer.sfs_generator.utils import process_blocks_split,get_gasol_path
from gasol_optimizer.verification.sfs_verify import verify_block_from_list_of_sfs, are_equals
from gasol_optimizer.solution_generation.optimize_from_sub_blocks import rebuild_optimized_asm_block
from gasol_optimizer.sfs_generator.asm_block import AsmBlock, AsmBytecode
from gasol_optimizer.smt_encoding.block_optimizer import BlockOptimizer, OptimizeOutcome
from gasol_optimizer.solution_generation.ids2asm import asm_from_ids

import pandas as pd

def parse_args():    
    global args

    parser = argparse.ArgumentParser(description="GREEN Project")
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
    parser.add_argument("-gasol-mem-opt", "--gasol-mem-opt",             help="Executes optimization on blocks obtained by memory analysis.", action="store_true")

    output = parser.add_argument_group('Output options')
    output.add_argument("-o", help="Path for storing the optimized code", dest='output_path', action='store')
    output.add_argument("-csv", help="CSV file path", dest='csv_path', action='store')
    output.add_argument("-backend","--backend", action="store_false",
                        help="Disables backend generation, so that only intermediate files are generated")
    output.add_argument("-intermediate", "--intermediate", action="store_true",
                        help="Keeps temporary intermediate files. "
                             "These files contain the sfs representation, smt encoding...")

    log_generation = parser.add_argument_group('Log generation options', 'Options for managing the log generation')

    log_generation.add_argument("-log", "--generate-log", help ="Enable log file for verification",
                                action = "store_true", dest='log')
    log_generation.add_argument("-dest-log", help ="Log output path", action = "store", dest='log_stored_final')
    log_generation.add_argument("-optimize-from-log", dest='log_path', action='store', metavar="log_file",
                                help="Generates the same optimized bytecode than the one associated to the log file")
    
    basic = parser.add_argument_group('Max-SMT solver general options',
                                  'Basic options for solving the corresponding Max-SMT problem')

    basic.add_argument("-solver", "--solver", help="Choose the solver", choices=["z3", "barcelogic", "oms"],
                       default="oms")
    basic.add_argument("-tout", metavar='timeout', action='store', type=int,
                       help="Timeout in seconds. By default, set to 10s per block.", default=10)
    basic.add_argument("-direct-tout", dest='direct_timeout', action='store_true',
                       help="Sets the Max-SMT timeout to -tout directly, "
                            "without considering the structure of the block")
    basic.add_argument("-push0", "--push0", dest='push0_enabled', action='store_true',
                       help="Enables reasoning for optimizations with PUSH0 opcode.")
    
    blocks = parser.add_argument_group('Split block options', 'Options for deciding how to split blocks when optimizing')

    blocks.add_argument("-storage", "--storage", help="Split using SSTORE, MSTORE and MSTORE8", action="store_true")
    blocks.add_argument("-partition","--partition",help="It enables the partition in blocks of 24 instructions",action="store_true")

    hard = parser.add_argument_group('Hard constraints', 'Options for modifying the hard constraint generation')

    hard.add_argument("-memory-encoding", help="Choose the memory encoding model", choices=["l_vars", "direct"],
                      default="direct", dest='memory_encoding')
    hard.add_argument('-no-simplification',"--no-simplification", action='store_true', dest='no_simp',
                      help='Disables the application of simplification rules')
    hard.add_argument('-push-uninterpreted', action='store_true', dest='push_basic',
                      help='Disables push instruction as uninterpreted functions')
    hard.add_argument('-pop-uninterpreted', action='store_false', dest='pop_basic',
                      help='Encodes pop instruction as uninterpreted functions')
    hard.add_argument('-order-bounds', action='store_false', dest='order_bounds',
                      help='Disables bounds on the position instructions can appear in the encoding')
    hard.add_argument('-empty', action='store_true', dest='empty',
                      help='Consider "empty" value as part of the encoding to reflect some stack position is empty,'
                           'instead of using a boolean term')
    hard.add_argument('-term-encoding', action='store', dest='encode_terms',
                      choices=['int', 'stack_vars', 'uninterpreted_uf', 'uninterpreted_int'],
                      help='Decides how terms are encoded in the SMT encoding: directly as numbers, using stack'
                           'variables or introducing uninterpreted functions',default = 'uninterpreted_uf')
    hard.add_argument('-terminal', action='store_true', dest='terminal',
                      help='(UNSUPPORTED) Encoding for terminal blocks that end with REVERT or RETURN. '
                           'Instead of considering the full stack order, just considers the two top elements')
    hard.add_argument('-ac', action='store_true', dest='ac_solver',
                      help='(UNSUPPORTED) Commutativity in operations is considered as an extension inside the solver. '
                           'Can only be combined with Z3')

    soft = parser.add_argument_group('Soft constraints', 'Options for modifying the soft constraint generation')
    group_gasol = soft.add_mutually_exclusive_group()
    group_gasol.add_argument("-size", "--size", action="store_true",
                      help="It enables size cost model for optimization and disables rules that increase the size"
                           "The simplification rules are applied only if they reduce the size")

    group_gasol.add_argument("-length", "--length", action="store_true",
                      help="It enables the #instructions cost model. Every possible simplification rule is applied")

    soft.add_argument("-direct-inequalities", dest='direct', action='store_true',
                      help="Soft constraints with inequalities instead of equalities and without grouping")

    additional = parser.add_argument_group('Additional constraints',
                                       'Constraints that can help to speed up the optimization process, but are not '
                                       'necessary')
    additional.add_argument('-at-most', action='store_true', dest='at_most',
                            help='add a constraint for each uninterpreted function so that they are used at most once')
    additional.add_argument('-pushed-once', action='store_true', dest='pushed_once',
                            help='add a constraint to indicate that each pushed value is pushed at least once')
    additional.add_argument("-no-output-before-pop", action='store_false', dest='no_output_before_pop',
                            help='Remove the constraint representing the fact that the previous instruction'
                                 'of a pop can only be a instruction that does not produce an element')
    additional.add_argument('-order-conflicts', action='store_false', dest='order_conflicts',
                            help='Disable the order among the uninterpreted opcodes in the encoding')

    ml_options = parser.add_argument_group('ML Options', 'Options to execute the different ML modules')
    ml_options.add_argument('-bound-model', "--bound-model", action='store_true', dest='bound_select',
                            help="Enable bound regression model")
    ml_options.add_argument('-opt-model', "--opt-model", action='store_true', dest='opt_select',
                            help="Select which representation model is used for the opt classification")


    
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

    results, exit_code, opt_blocks_mem = run_solidity_analysis(inputs,hashes)
    helper.rm_tmp_files()

    return exit_code, opt_blocks_mem


def run_solidity_analysis(inputs,hashes):
    results = {}
    exit_code = 0
    returns = []

    optimized_blocks = {}
    
    i = 0
        
    if len(inputs) == 1:
        inp = inputs[0]
        function_names = hashes[inp["c_name"]]
        try:
            result, return_code = symExec.run(disasm_file=inp['disasm_file'], disasm_file_init = inp['disasm_file_init'], source_map=inp['source_map'], source_file=inp['source'],cfg = args.control_flow_graph,execution = 0, cname = inp["c_name"],hashes = function_names,debug = args.debug,evm_version = True,svc = {},opt_bytecode = (args.optimize_run or args.via_ir), mem_analysis = args.mem_analysis)
            if symExec.memory_opt_blocks != None:
                optimized_blocks[symExec.memory_opt_blocks.get_contract_name()] = symExec.memory_opt_blocks
            
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
                result, return_code = symExec.run(disasm_file=inp['disasm_file'], disasm_file_init = inp['disasm_file_init'], source_map=inp['source_map'], source_file=inp['source'],cfg = args.control_flow_graph,execution = i,cname = inp["c_name"],hashes = function_names,debug = args.debug,evm_version = True, svc = {}, opt_bytecode = (args.optimize_run or args.via_ir), mem_analysis = args.mem_analysis)

                if symExec.memory_opt_blocks != None:
                    optimized_blocks[symExec.memory_opt_blocks.get_contract_name()] = symExec.memory_opt_blocks
                
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
    
    return results, exit_code, optimized_blocks


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
        exit_code, opt_blocks_mem = analyze_solidity()
    six.print_("The files generated by EthIR are stored in the following directory: "+global_params.costabs_path)
    return opt_blocks_mem

def run_gasol(instr, contract_name, block_id, output_file, csv_file, dep_information = {}):
    statistics_rows = []
    instructions = instr
    
    timeout = args.tout
    parsed_args = args

    blocks = parse_blocks_from_plain_instructions(instructions)
    asm_blocks = []

    is_timeout = False
    
    for old_block in blocks:
        asm_block, _, statistics_csv = gasol_main.optimize_asm_block_asm_format(old_block, timeout, parsed_args, dep_information)
        statistics_rows.extend(statistics_csv)

        real_timeout = statistics_csv[0]["timeout"]
        
        eq, reason = gasol_main.compare_asm_block_asm_format(old_block, asm_block, parsed_args,dep_information)

        tout = statistics_csv[0]["outcome"] == "no_model"

        is_timeout = is_timeout or tout
        
        if not eq and dep_information == {}:
            print("Comparison failed, so initial block is kept")
            print("\t[REASON]: "+reason)
            print(old_block.to_plain())
            print(asm_block.to_plain())
            print("")
            asm_block = old_block

        gasol_main.update_gas_count(old_block, asm_block)
        gasol_main.update_length_count(old_block, asm_block)
        gasol_main.update_size_count(old_block, asm_block)
        asm_blocks.append(asm_block)

    if parsed_args.backend:
        df = pd.DataFrame(statistics_rows)
        df.to_csv(csv_file)
        print("")
        print("Initial sequence (basic block per line):")
        print('\n'.join([old_block.to_plain_with_byte_number() for old_block in blocks]))
        print("")
        print("Optimized sequence (basic block per line):")
        print('\n'.join([asm_block.to_plain_with_byte_number() for asm_block in asm_blocks]))
        with open(output_file, 'w') as f:
            f.write('\n'.join([asm_block.to_plain_with_byte_number() for asm_block in asm_blocks]))

        df = pd.DataFrame(statistics_rows)
        df.to_csv(csv_file)
        
    if parsed_args.intermediate or not parsed_args.backend:
        print("")
        print("Intermediate files stored at " + get_gasol_path())
    else:
        shutil.rmtree(paths.gasol_path, ignore_errors=True)
        
    if parsed_args.backend:
        print("")
        print("Optimized code stored in " + output_file)
        print("Optimality results stored in " + csv_file)
        print("")
        print("Estimated initial gas: "+str(gasol_main.previous_gas))
        print("Estimated gas optimized: " + str(gasol_main.new_gas))
        print("")
        print("Estimated initial size in bytes: " + str(gasol_main.previous_size))
        print("Estimated size optimized in bytes: " + str(gasol_main.new_size))
        print("")
        print("Initial number of instructions: " + str(gasol_main.prev_n_instrs))
        print("Final number of instructions: " + str(gasol_main.new_n_instrs))


        opt_instructions = " ".join([asm_block.to_plain_with_byte_number() for asm_block in asm_blocks])

        dif_gas =gasol_main.previous_gas-gasol_main.new_gas
        dif_size = gasol_main.previous_size-gasol_main.new_size 
        dif_n_instrs = gasol_main.prev_n_instrs-gasol_main.new_n_instrs
        
        greenres = [args.source+"_"+contract_name+"_"+str(block_id),args.source,contract_name,block_id,real_timeout,is_timeout,instructions,opt_instructions,gasol_main.previous_gas,gasol_main.previous_size,gasol_main.prev_n_instrs,gasol_main.new_gas,gasol_main.new_size,gasol_main.new_n_instrs,dif_gas,dif_size,dif_n_instrs]

        green_res_str = list(map(lambda x: str(x), greenres))

        print("")
        print("GREENRES: "+";".join(green_res_str))
        print("")
    else:
        print("")
        print("Estimated initial gas: "+str(gasol_main.previous_gas))
        print("")
        print("Estimated initial size in bytes: " + str(gasol_main.previous_size))
        print("")
        print("Initial number of instructions: " + str(gasol_main.new_n_instrs))
        
# def run_gasol(opt_blocks = {}):
#     pass


def final_file_names(parsed_args,cname,block):
    input_file_name = cname

    if parsed_args.output_path is None:
        # if parsed_args.block:
        output_file = input_file_name +str(block)+ "_optimized.txt"
        # elif parsed_args.sfs:
        #     output_file = input_file_name +str(block)+ "_optimized.json"
        # elif parsed_args.log_path is not None:
        #     output_file = input_file_name +str(block)+ "_optimized_from_log.json_solc"
        # else:
        #     output_file = input_file_name +str(block)+ "_optimized.json_solc"
    else:
        output_file = parsed_args.output_path+input_file_name+"_"+str(block)+"_optimized.txt"

    if parsed_args.csv_path is None:
        if parsed_args.output_path is None:
            csv_file = input_file_name +"_"+str(block)+ "_statistics.csv"
        else:
            csv_file = parsed_args.output_path+input_file_name +"_"+str(block)+ "_statistics.csv"

    if parsed_args.log_stored_final is None:
        if parsed_args.output_path is None:
            log_file = input_file_name+"_"+str(block) + ".log"
        else:
            log_file = parsed_args.output_path+input_file_name+"_"+str(block) + ".log"
    else:
        log_file = parsed_args.log_stored_final

    return output_file, csv_file, log_file



def run_gasol_test(dep_information = {}):
    statistics_rows = []
    instructions = "SWAP2 SWAP1 MSTORE MLOAD PUSH 5 SSTORE"
    
    timeout = 50

    output_file = "out.txt"
    csv_file = "csv.csv"
    constants._set_push0(args.push0_enabled)
    args.optimized_predictor_model = None


    dep_information = OptimizableBlockInfo("block0",instructions.split())
    dep_information.add_pair("block0:2","block0:3","!=")
    
    args.input_path = "test"
    args.debug_flag = args.debug
    args.bound_model = None
    
    parsed_args = args
    
    blocks = parse_blocks_from_plain_instructions(instructions)
    asm_blocks = []

    for old_block in blocks:
        asm_block, _, statistics_csv = gasol_main.optimize_asm_block_asm_format(old_block, timeout, parsed_args, dep_information)
        statistics_rows.extend(statistics_csv)

        
        eq, reason = gasol_main.compare_asm_block_asm_format(old_block, asm_block, parsed_args,dep_information)
         
        if not eq and dep_information == {}:
            print("Comparison failed, so initial block is kept")
            print("\t[REASON]: "+reason)
            print(old_block.to_plain())
            print(asm_block.to_plain())
            print("")
            asm_block = old_block

        gasol_main.update_gas_count(old_block, asm_block)
        gasol_main.update_length_count(old_block, asm_block)
        gasol_main.update_size_count(old_block, asm_block)
        asm_blocks.append(asm_block)

    if parsed_args.backend:
        df = pd.DataFrame(statistics_rows)
        df.to_csv(csv_file)
        print("")
        print("Initial sequence (basic block per line):")
        print('\n'.join([old_block.to_plain_with_byte_number() for old_block in blocks]))
        print("")
        print("Optimized sequence (basic block per line):")
        print('\n'.join([asm_block.to_plain_with_byte_number() for asm_block in asm_blocks]))
        with open("out.txt", 'w') as f:
            f.write('\n'.join([asm_block.to_plain_with_byte_number() for asm_block in asm_blocks]))

        df = pd.DataFrame(statistics_rows)
        df.to_csv(csv_file)

    if parsed_args.intermediate or not parsed_args.backend:
        print("")
        print("Intermediate files stored at " + get_gasol_path())
    else:
        shutil.rmtree(paths.gasol_path, ignore_errors=True)


    if parsed_args.backend:
        print("")
        print("Optimized code stored in " + output_file)
        print("Optimality results stored in " + csv_file)
        print("")
        print("Estimated initial gas: "+str(gasol_main.previous_gas))
        print("Estimated gas optimized: " + str(gasol_main.new_gas))
        print("")
        print("Estimated initial size in bytes: " + str(gasol_main.previous_size))
        print("Estimated size optimized in bytes: " + str(gasol_main.new_size))
        print("")
        print("Initial number of instructions: " + str(gasol_main.prev_n_instrs))
        print("Final number of instructions: " + str(gasol_main.new_n_instrs))

    else:
        print("")
        print("Estimated initial gas: "+str(gasol_main.previous_gas))
        print("")
        print("Estimated initial size in bytes: " + str(gasol_main.previous_size))
        print("")
        print("Initial number of instructions: " + str(gasol_main.new_n_instrs))




if __name__ == "__main__":
    global args
    
    print("Green Main")
    parse_args()
    
    opt_blocks_mem = run_ethir()
    
    # Set push0 global variable to the corresponding flag
    constants._set_push0(args.push0_enabled)
    args.optimized_predictor_model = None

    for c in opt_blocks_mem:
        blocks = opt_blocks_mem[c].get_optimizable_blocks()
        for b in blocks:
            if args.debug:
                print(blocks[b].get_instructions())

            output_file, csv_file, log_file = final_file_names(args,c,b)

            args.input_path = c
            args.debug_flag = args.debug
            args.bound_model = None
            gasol_main.init()
            instructions_as_plain_text = " ".join(blocks[b].get_instructions())
            # print(blocks[b])
            # print(type(blocks[b]))
            if not args.gasol_mem_opt:
                print("\nNORMAL EXECUTION\n")
                run_gasol(instructions_as_plain_text,c,b,output_file,csv_file)
            else:
                print("\nADDITIONAL EXECUTION\n")
                run_gasol(instructions_as_plain_text,c,b,output_file,csv_file,blocks[b])
    
