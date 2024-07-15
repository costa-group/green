#!/usr/bin/python3
import copy
import importlib
import logging
import sys
import os
from typing import Dict, List
import json
import six
import argparse
import shutil

sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/ethir_complete/ethir")
sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/gasol_optimizer")

import ethir_complete.ethir.oyente_ethir as ethir_main
import ethir_complete.ethir.symExec as symExec
from ethir_complete.ethir.input_helper import InputHelper
from ethir_complete.ethir.optimizer.optimizer_connector import OptimizableBlockInfo
import ethir_complete.ethir.global_params_ethir as global_params
import gasol_asm as gasol_main
from timeit import default_timer as dtimer
import traceback

import gasol_optimizer.global_params.constants as constants
import gasol_optimizer.global_params.paths as paths
from gasol_optimizer.sfs_generator.parser_asm import (build_asm_contract,
                                      generate_block_from_plain_instructions,
                                      parse_blocks_from_plain_instructions)
from gasol_optimizer.sfs_generator.utils import process_blocks_split,get_gasol_path
from global_params.options import OptimizationParams

import pandas as pd

def parse_args():    
    global args

    parser = argparse.ArgumentParser(description="GREEN Project")
    group = parser.add_mutually_exclusive_group(required=True)

    group.add_argument("-s",  "--source",    type=str, help="local source file name. Solidity by default. Use -b to process evm instead. Use stdin to read from stdin.")

    parser.add_argument("-glt", "--global-timeout", help="Timeout for symbolic execution", action="store", dest="global_timeout", type=int)
    parser.add_argument( "-e",   "--evm",                    help="Do not remove the .evm file.", action="store_true")
    parser.add_argument( "-b",   "--bytecode",               help="read bytecode in source instead of solidity file", action="store_true")
    parser.add_argument("-asm", "--asm", "--assembly", dest="assembly_generation",
                         help="Generates an Assembly JSON file per analyzed contract", action="store_true")

    #Added by Pablo Gordillo
    parser.add_argument( "-d", "--debug",                   help="Display the status of the stack after each opcode", action = "store_true")
    parser.add_argument( "-cfg", "--control-flow-graph",    help="Store the CFG", choices=["normal","memory","storage","all"])
    parser.add_argument("-optimize-run", "--optimize-run",             help="Enable optimization flag in solc compiler", action="store_true")
    parser.add_argument("-run", "--run",             help="Set for how many contract runs to optimize (200 by default if --optimize-run)", default=-1,action="store",type=int)
    parser.add_argument("-no-yul-opt", "--no-yul-opt",             help="Disable yul optimization in solc compiler (when possible)", action="store_true")
    parser.add_argument("-via-ir", "--via-ir",             help="via-ir optimization in solc compiler (when possible)", action="store_true")
    parser.add_argument( "-hashes", "--hashes",             help="Generate a file that contains the functions of the solidity file", action="store_true")
    parser.add_argument( "-out", "--out",             help="Generate a file that contains the functions of the solidity file", action="store", dest="path_out",type=str)
    parser.add_argument("-mem-analysis", "--mem-analysis",             help="Executes memory analysis. baseref runs the basic analysis where it only identifies the base refences. Offset runs baseref+offset option", choices = ["baseref","offset"])
    parser.add_argument("-storage-analysis", "--storage-analysis",             help="Executes storage analysis", action="store_true")
    parser.add_argument("-aliasing-info", "--aliasing-info",             help="Executes optimization on blocks obtained by memory analysis.", action="store_true")
    parser.add_argument("-non-aliasing-disabled", "--non-aliasing-disabled",             help="It only uses the information of aliasing.", action="store_true")
    parser.add_argument("-useless-info", "--useless-info",             help="Uses useless info from memory analysis.", action="store_true")
    parser.add_argument("-context-info", "--context-info",             help="Uses context info from memory analysis.", action="store_true")
    parser.add_argument("-compact-clones", "--compact-clones",             help="Intersect blocks cloned before invoking GASOL superoptimizer", action="store_true")


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
    basic.add_argument('-greedy', '--greedy', dest='greedy', help='Uses greedy directly to generate the results', action='store_true')
    basic.add_argument("-ub-greedy", "--ub-greedy", dest='ub_greedy', help='Enables greedy algorithm to predict the upper bound', action='store_true')

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
        helper = InputHelper(InputHelper.SOLIDITY, source=args.source,evm =args.evm,runtime=is_runtime,opt_options = compiler_opt,tmp_path = global_params.tmp_path)

    inputs = helper.get_inputs()
    solc_version = helper.get_solidity_version()

    hashes = ethir_main.process_hashes(args.source,solc_version)
    
    y = dtimer()
    print("*************************************************************")
    print("Compilation time: "+str(y-x)+"s")
    print("*************************************************************")

    results, exit_code, opt_blocks, asm_inputs = run_solidity_analysis(inputs,hashes)
    six.print_("Aux path: "+helper.get_aux_path())
    helper.rm_tmp_files()
    return exit_code, opt_blocks, asm_inputs


def run_solidity_analysis(inputs,hashes):
    results = {}
    exit_code = 0
    returns = []

    optimized_blocks = {}
    asm_inputs = {}
    
    i = 0
        
    if len(inputs) == 1:
        inp = inputs[0]
        function_names = hashes[inp["c_name"]]
        try:
            result, return_code = symExec.run(disasm_file=inp['disasm_file'], 
                                              disasm_file_init = inp['disasm_file_init'], 
                                              source_map=inp['source_map'], 
                                              source_file=inp['source'],
                                              cfg = args.control_flow_graph,
                                              execution = 0, 
                                              cname = inp["c_name"],
                                              hashes = function_names,
                                              debug = False,
                                              evm_version = True,
                                              svc = {},
                                              opt_bytecode = (args.optimize_run or args.via_ir), 
                                              mem_analysis = args.mem_analysis,
                                              storage_analysis = args.storage_analysis,
                                              compact_clones = args.compact_clones)

            if symExec.opt_blocks is not None:
                optimized_blocks[symExec.opt_blocks.get_contract_name()] = symExec.opt_blocks
                asm_inputs[symExec.opt_blocks.get_contract_name()] = inp["assembly"]

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
                result, return_code = symExec.run(disasm_file=inp['disasm_file'], 
                                                  disasm_file_init = inp['disasm_file_init'], 
                                                  source_map=inp['source_map'], 
                                                  source_file=inp['source'],
                                                  cfg = args.control_flow_graph,
                                                  execution = i,
                                                  cname = inp["c_name"],
                                                  hashes = function_names,
                                                  debug = False,
                                                  evm_version = True, 
                                                  svc = {}, 
                                                  opt_bytecode = (args.optimize_run or args.via_ir), 
                                                  mem_analysis = args.mem_analysis,
                                                  storage_analysis = args.storage_analysis,
                                                  compact_clones = args.compact_clones)
                if symExec.opt_blocks is not None:
                    optimized_blocks[symExec.opt_blocks.get_contract_name()] = symExec.opt_blocks
                    asm_inputs[symExec.opt_blocks.get_contract_name()] = inp["assembly"]

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

    if symExec.file_info != {}:
        for k in symExec.file_info:
            r = "FILERES: "+args.source+"_"+k
            info = symExec.file_info[k]
            r+=";"+str(info["num_blocks"])+";"+str(info["num_blocks_cloning"])+";"+str(info["optimizable_blocks"])+";"+str(info["memory_blocks"])+";"+str(info["memory_blocks2"])+";"+str(info["storage_blocks"])+";"+str(info["time"])
            print(r)
    print("\n")
    
    # print(optimized_blocks)
    # for b in optimized_blocks:
    #     print(optimized_blocks[b].print_blocks())
    # raise Exception
    
    return results, exit_code, optimized_blocks, asm_inputs


def run_ethir():
    if not ethir_main.has_dependencies_installed():
        return
    
    # ethir_main.clean_dir()

    try:
        if "costabs" in os.listdir(global_params.tmp_path):
            pass
    except:
        os.mkdir(global_params.tmp_path)
        os.mkdir(global_params.costabs_path)
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
        six.print_("Aux path: "+helper.get_aux_path())
    else:
        exit_code, opt_blocks, asm_inputs = analyze_solidity()
    six.print_("The files generated by EthIR are stored in the following directory: "+global_params.costabs_path)
    
    return opt_blocks, asm_inputs


def run_gasol_from_instructions(instr, contract_name, block_id, output_file, csv_file, dep_information = {}, opt_info = {}):
    blocks = parse_blocks_from_plain_instructions(instr)
    run_gasol_from_blocks(blocks, contract_name, block_id, output_file, csv_file, dep_information, opt_info)


def run_gasol_from_blocks(blocks, contract_name, block_id, output_file, csv_file, dep_information=None, opt_info=None) -> List:
    if opt_info is None:
        opt_info = {}

    statistics_rows = []
    timeout = args.tout
    parsed_args = args

    optimized_asm_blocks = []

    is_timeout = False
    model_found = True
    shown_optimal = True

    init_time = dtimer()

    storage_gas = 0
    storage_gas_original = 0
    discount_op = 0
    optimization_params = OptimizationParams()
    optimization_params.parse_args(parsed_args)
    instructions = ""
    for old_block in blocks:
        instructions += old_block.to_plain_with_byte_number() + " "
        storage_gas_original+=old_block.gas_spent_by_storage()
        
        asm_block, _, statistics_csv = gasol_main.optimize_asm_block_asm_format(old_block, timeout, optimization_params, dep_information, opt_info)

        storage_gas += asm_block.gas_spent_by_storage()
        if gasol_main.equal_aliasing:
            print("BLOCK "+args.source+"_"+contract_name+"_"+str(block_id)+" FILTERED WITH EQUAL SFS WITH AND WITHOUT HEAP ANALYSIS INFORMATION")
            return [asm_block]
        
        statistics_rows.extend(statistics_csv)

        if statistics_csv !=[]:
            real_timeout = statistics_csv[0].get("timeout",0)

            model = statistics_csv[0].get("model_found",False)
            optimal = statistics_csv[0].get("shown_optimal",False)
        else:
            real_timeout = 0
            model = False
            optimal = False
            
        model_found = model_found and model
        shown_optimal = shown_optimal and optimal

        if statistics_csv != []:
            tout1 = statistics_csv[0]["outcome"] == "no_model"
        else:
            tout1 = False
            
        tout2 = model and not optimal
        tout = tout1 or tout2
        
        is_timeout = is_timeout or tout
        
        has_info = (opt_info["useless"] or opt_info["dependences"])

        if not has_info:
            eq, reason = gasol_main.compare_asm_block_asm_format(old_block, asm_block, optimization_params,dep_information, opt_info)
        
            if not eq:
                print("Comparison failed, so initial block is kept")
                print("\t[REASON]: "+reason)
                print(old_block.to_plain())
                print(asm_block.to_plain())
                print("")
                asm_block = old_block

        gasol_main.update_gas_count(old_block, asm_block)
        gasol_main.update_length_count(old_block, asm_block)
        gasol_main.update_size_count(old_block, asm_block)
        optimized_asm_blocks.append(asm_block)

    end_time = dtimer()
        
    if parsed_args.backend:
        df = pd.DataFrame(statistics_rows)
        df.to_csv(csv_file)
        print("")
        print("Initial sequence (basic block per line):")
        print('\n'.join([old_block.to_plain_with_byte_number() for old_block in blocks]))
        print("")
        print("Optimized sequence (basic block per line):")
        print('\n'.join([asm_block.to_plain_with_byte_number() for asm_block in optimized_asm_blocks]))
        with open(output_file, 'w') as f:
            f.write('\n'.join([asm_block.to_plain_with_byte_number() for asm_block in optimized_asm_blocks]))

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

        opt_instructions = " ".join([asm_block.to_plain_with_byte_number() for asm_block in optimized_asm_blocks])

        dif_gas =gasol_main.previous_gas-gasol_main.new_gas
        dif_size = gasol_main.previous_size-gasol_main.new_size 
        dif_n_instrs = gasol_main.prev_n_instrs-gasol_main.new_n_instrs

        has_memory = False
        has_storage = False
        has_useless = False
        has_context = False
        
        has_info = (opt_info["useless"] or opt_info["dependences"] or opt_info["context"])

        if has_info and dep_information:
            has_memory = (dep_information.get_equal_pairs_memory()!= []) or (dep_information.get_nonequal_pairs_memory() != [])
            has_storage = (dep_information.get_equal_pairs_storage()!= []) or (dep_information.get_nonequal_pairs_storage() != [])
            has_useless = opt_info["useless"] and (dep_information.get_useless_info() != [])
            has_context = opt_info["context"] and dep_information.has_context_info()

        rules = []
        deps = []
        discount_op = 0
        sfs_applied = gasol_main.sfs_information
        for s in sfs_applied:
            rules += sfs_applied[s]["rules"]
            deps += sfs_applied[s]["deps"]
            discount_op += sfs_applied[s]["discount_op"]

        greenres = [args.source+"_"+contract_name+"_"+str(block_id),args.source,contract_name,block_id,real_timeout,is_timeout,model_found,shown_optimal,instructions,opt_instructions,gasol_main.previous_gas,gasol_main.previous_size,gasol_main.prev_n_instrs,gasol_main.new_gas,gasol_main.new_size,gasol_main.new_n_instrs,dif_gas,dif_size,dif_n_instrs,has_memory,has_storage,has_useless,has_context,(end_time-init_time), len(rules), len(deps),storage_gas_original,storage_gas,discount_op]

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

    return optimized_asm_blocks

# def run_gasol(opt_blocks = {}):
#     pass


def final_file_names(parsed_args,cname,block):
    input_file_name = cname

    if parsed_args.output_path is None:
        # if parsed_args.block:
        output_file = input_file_name+"_" +str(block)+ "_optimized.txt"
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
    # instructions = "SWAP2 SWAP1 MSTORE MLOAD PUSH 5 SSTORE"
    #instructions = "DUP2 DUP2 MSTORE DUP3 PUSH1 20 PUSH 5 MSTORE DUP2 ADD DUP5 MSTORE"
    # instructions = "JUMPDEST PUSH1 0x11 DUP2 MSTORE ADD PUSH1 0x0e DUP2 MSTORE DUP2 MLOAD SWAP1 PUSH1 0x11 DUP3 MSTORE MLOAD PUSH1 0x20 DUP3 ADD MSTORE RETURN"
    #instructions = "ADD PUSH 40 MSTORE PUSH 20 MSTORE DUP2 ISZERO PUSH 40 PUSH 20 KECCAK256"
    # instructions = "DUP1 MLOAD SWAP2 MLOAD"
    #instructions = "PUSH1 0x40 DUP1 MLOAD SWAP2 DUP3 MSTORE MLOAD SWAP1 DUP2 SWAP1 SUB PUSH1 0x20 ADD SWAP1"
    #instructions = "PUSH1 0x40 DUP1 MLOAD SWAP2 DUP3 MSTORE MLOAD SWAP1 DUP2 SWAP1 SUB PUSH1 0x20 ADD SWAP1"
    # instructions = "DUP2 DUP5 ISZERO DUP2 PUSH 20 ADD"
    #instructions = "DUP1 ISZERO PUSH 0x10 PUSH 0x10 ADD"
    #instructions = "PUSH1 0x40 DUP1 MLOAD SWAP2 DUP3 MSTORE POP SWAP1 DUP2 SWAP1 MSTORE SUB PUSH1 0x20 ADD SWAP1"
    #instructions = "JUMPDEST PUSH1 0x01 PUSH1 0x01 PUSH1 0xa0 SHL SUB DUP1 DUP6 AND PUSH1 0x00 SWAP1 DUP2 MSTORE PUSH1 0x01 PUSH1 0x20 MSTORE PUSH1 0x40 DUP1 DUP3 KECCAK256 SWAP4 SWAP1 SWAP4 SSTORE SWAP1 DUP5 AND DUP2 MSTORE KECCAK256 SLOAD PUSH2 0x1197 SWAP1 DUP3 PUSH2 0x0ec2 JUMP"
    instructions = "SWAP1 PUSH1 0x1f NOT DUP4 AND SWAP4 PUSH2 0x03b6 PUSH1 0x02 PUSH0 MSTORE PUSH32 0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace SWAP1"
    timeout = 75

    output_file = "out.txt"
    csv_file = "csv.csv"
    constants._set_push0(args.push0_enabled)
    args.optimized_predictor_model = None

    
    dep_information = OptimizableBlockInfo("block0",instructions.split(),1)
    #dep_information.add_pair("block0:2","block0:4","!=","memory")
    # dep_information.add_pair("block0:12","block0:33","==","memory")
    # dep_information.add_pair("block0:15","block0:36","==","memory")
    # dep_information.add_pair("block0:19","block0:40","==","storage")
    # dep_information.add_pair("block0:12","block0:15","!=","memory")
    # dep_information.add_pair("block0:12","block0:36","!=","memory")
    # dep_information.add_pair("block0:15","block0:33","!=","memory")
    # dep_information.add_pair("block0:33","block0:36","!=","memory")
    # dep_information.add_pair("block0:2","block0:19","!=","storage")
    # dep_information.add_pair("block0:2","block0:23","!=","storage")
    # dep_information.add_pair("block0:2","block0:40","!=","storage")
    # dep_information.add_pair("block0:2","block0:44","!=","storage")
    # dep_information.add_pair("block0:19","block0:23","!=","storage")
    # dep_information.add_pair("block0:19","block0:44","!=","storage")
    # dep_information.add_pair("block0:23","block0:40","!=","storage")
    # dep_information.add_pair("block0:23","block0:44","!=","storage")
    # dep_information.add_pair("block0:40","block0:44","!=","storage")
    #dep_information._add_context_pair((1,1))
    # dep_information._add_constancy_pair((0,32))
    # dep_information.add_pair("block0:11","block0:14","!=","memory")
    # dep_information.add_pair("block0:9","block0:18","==","memory")
    #dep_information.add_useless_info([7])
    args.input_path = "test"
    args.debug_flag = args.debug
    args.bound_model = None
    
    parsed_args = args
    
    blocks = parse_blocks_from_plain_instructions(instructions)
    asm_blocks = []


    opt_dict = {}
    opt_dict["useless"] = False
    opt_dict["dependences"] = False
    opt_dict["context"] = False
    
    for old_block in blocks:
        asm_block, _, statistics_csv = gasol_main.optimize_asm_block_asm_format(old_block, timeout, parsed_args, dep_information,opt_dict)

        if gasol_main.equal_aliasing:
            print("-----------------------------------------------")
            print("Equal SFS with and without aliasing information")
            print("-----------------------------------------------")
            return 0
        
        statistics_rows.extend(statistics_csv)

        # print("COMPARE")
        # eq, reason = gasol_main.compare_asm_block_asm_format(old_block, asm_block, parsed_args,dep_information,opt_dict)
         
        # if not eq and dep_information == {}:
        #     print("Comparison failed, so initial block is kept")
        #     print("\t[REASON]: "+reason)
        #     print(old_block.to_plain())
        #     print(asm_block.to_plain())
        #     print("")
        #     asm_block = old_block


            
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


def initialize_args_for_gasol(c: str) -> None:
    args.input_path = c
    args.debug_flag = args.debug
    args.bound_model = None
    gasol_main.init()


def optimize_optimizable_blocks(opt_blocks):
    """
    Optimizes only the blocks from the optimizable blocks. Ignores the asm json generation, as it is not needed
    """
    opt_dict = {"useless": args.useless_info, "dependences": args.aliasing_info, "context": args.context_info,
                "non_aliasing_disabled": args.non_aliasing_disabled and args.aliasing_info}
    optimize = args.aliasing_info or args.useless_info or args.context_info

    for c in opt_blocks:
        blocks = opt_blocks[c].get_optimizable_blocks()
        for b in blocks:
            # if args.debug:
            #     print(blocks[b].get_instructions())

            output_file, csv_file, log_file = final_file_names(args, c, b)
            initialize_args_for_gasol(c)
            instructions_as_plain_text = " ".join(blocks[b].get_instructions())

            if not optimize:
                print("\nNORMAL EXECUTION\n")
                run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)
            else:
                print(blocks[b])

                if (opt_dict["useless"] and opt_dict["dependences"] and opt_dict["context"]):
                    # if (blocks[b].has_dependences_info()  blocks[b].get_useless_info()!=[] and blocks[b].has_context_info()):
                    print("\nADDITIONAL EXECUTION WITH THREE\n")
                    run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)
                elif (opt_dict["useless"] and opt_dict["context"]):
                    if (blocks[b].has_context_info() and blocks[b].get_useless_info() != []):
                        print("\nADDITIONAL EXECUTION WITH USELESS AND CONTEXT\n")
                        run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)
                elif (opt_dict["context"] and opt_dict["dependences"]):
                    if (blocks[b].has_dependences_info() and blocks[b].has_context_info()):
                        print("\nADDITIONAL EXECUTION WITH ALIASING AND CONTEXT\n")
                        run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)

                elif (opt_dict["useless"] and opt_dict["dependences"]):
                    if (blocks[b].has_dependences_info() and blocks[b].get_useless_info() != []):
                        print("\nADDITIONAL EXECUTION WITH BOTH\n")
                        run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)
                elif opt_dict["useless"]:
                    if (blocks[b].get_useless_info() != []):
                        print("\nADDITIONAL EXECUTION WITH USELESS\n")
                        run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)
                elif opt_dict["dependences"]:
                    if (blocks[b].has_dependences_info()):
                        print("\nADDITIONAL EXECUTION WITH ALIASING\n")
                        run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)
                elif opt_dict["context"]:
                    if (blocks[b].has_context_info()):
                        print("\nADDITIONAL EXECUTION WITH CONTEXT\n")
                        run_gasol_from_instructions(instructions_as_plain_text, c, b, output_file, csv_file, blocks[b], opt_dict)


def compare_assingimmutable_words(concrete_words: List[str], abstract_words: List[str]):
    return True


def compare_instructions(concrete_words: List[str], abstract_words: List[str]):
    # Special case: ASSIGNIMMUTABLE can be translated to multiple MSTORE operations
    if "ASSIGNIMMUTABLE" in abstract_words:
        return compare_assingimmutable_words(concrete_words, abstract_words)

    # Compare lengths of concrete and absract words
    if len(concrete_words) != len(abstract_words):
        return False, "Different length when comparing instructions"

    # We must map the corresponding values of pseudo-push instructions to the concrete value in the list of
    # concrete words
    abstract_value2concrete = dict()
    i = 0
    while i < len(concrete_words):
        concrete_word, abstract_word = concrete_words[i], abstract_words[i]
        if abstract_word == "PUSH*":
            if not concrete_word.startswith("PUSH"):
                return False, f"Concrete word {concrete_word} in position {i} does not start with PUSH"
            concrete_value = concrete_words[i + 1]
            abstract_value = abstract_words[i + 1]

            # We only compare the abstract values that are not generic (i.e. *)
            if abstract_value != "*":
                # Assign the abstract value in the dict if not present yet
                if abstract_value not in abstract_value2concrete:
                    abstract_value2concrete[abstract_value] = concrete_value

                if concrete_value != abstract_value2concrete[abstract_value]:
                    return False, f"Abstract value does not match the expected concrete value in position {i+1}"

            i += 2

        elif concrete_word.startswith("0x"):
            if not abstract_word.startswith("0x"):
                return False, f"Values in position {i} do not match: {concrete_word}!={abstract_word}"
            if int(concrete_word, 16) != int(abstract_word, 16):
                return False, f"Values in position {i} do not match: {concrete_word}!={abstract_word}"
            i += 1
        else:
            if concrete_word != abstract_word:
                return False, f"Instructions do not match in position {i}: {concrete_word}!={abstract_word} "

            i += 1

    return True, ""


def print_blocks(opt_blocks, asm_inputs):
    with open('inputs.json', 'w') as f:
        json.dump(asm_inputs, f)
    for c in opt_blocks:
        asm_contract = build_asm_contract(c, asm_inputs[c])
        new_contract = copy.deepcopy(asm_contract)

        print("CONTRACT", c)
        assert len(asm_contract.get_data_ids_with_code()) == 1
        print("ASM")
        block_optimizer = opt_blocks[c].vertices
        for identifier in asm_contract.get_data_ids_with_code():
            blocks = asm_contract.get_run_code(identifier)
            for i, (asm_block, ethir_block) in enumerate(zip(blocks, block_optimizer)):
                concrete_instructions = block_optimizer[ethir_block].get_instructions_gasol()
                concrete_instructions = [word for instr in concrete_instructions
                                         for word in instr.split(' ') if word != '']
                abstract_instructions = asm_block.instructions_words_abstract()

                print(i)
                print(asm_block.to_json())
                print(compare_instructions(concrete_instructions, abstract_instructions))
                print(' '.join(concrete_instructions))
                print(' '.join(abstract_instructions))


def optimize_all_blocks(opt_blocks, asm_inputs):
    """
    Optimizes all the blocks from contracts stored in the asm inputs. Note that opt blocks only records the blocks
    for which some of the analysis have inferred some extra information
    """
    contracts = dict()
    opt_dict = {"useless": args.useless_info, "dependences": args.aliasing_info, "context": args.context_info,
                "non_aliasing_disabled": args.non_aliasing_disabled and args.aliasing_info}

    for c in opt_blocks:
        asm_contract = build_asm_contract(c, asm_inputs[c])
        new_contract = copy.deepcopy(asm_contract)

        initialize_args_for_gasol(c)

        # First we optimize the init code, as usual with no analysis applied
        optimized_init_code = run_gasol_from_blocks(asm_contract.init_code, c, "initial", f"{c}_init_output.txt",
                                                    f"{c}_init_stats.csv", {}, opt_dict)
        new_contract.init_code = optimized_init_code

        optimizable_blocks = opt_blocks[c].get_optimizable_blocks()
        block_number2blocks = {block.block_number: block for block in optimizable_blocks.values()}
        assert len(asm_contract.get_data_ids_with_code()) == 1
        for identifier in asm_contract.get_data_ids_with_code():
            blocks = asm_contract.get_run_code(identifier)

            run_code_blocks = []

            for block_number, asm_block in enumerate(blocks):
                # if args.debug:
                #     print(blocks[b].get_instructions())
                block_id = asm_block.block_id

                output_file, csv_file, log_file = final_file_names(args, c, block_id)

                initialize_args_for_gasol(c)
                # Retrieves the corresponding optimizable block if exists
                optimizable_block = block_number2blocks.get(block_number, None)

                # Extra check: the instructions match
                if optimizable_block:
                    optimizable_instructions = [word for instr in optimizable_block.get_instructions()
                                                for word in instr.split(' ') if word != '']

                    block_instructions = asm_block.instructions_words_abstract()

                    eq, reason = compare_instructions(optimizable_instructions, block_instructions)
                    if not eq:
                        print(reason)
                        print(optimizable_instructions)
                        print(block_instructions)
                        exit(1)

                run_code_blocks.extend(run_gasol_from_blocks([asm_block], c, block_id, output_file,
                                                             csv_file, optimizable_block, opt_dict))

            new_contract.set_run_code(identifier, run_code_blocks)

        contracts[c] = new_contract

    return contracts


def store_asm_json_contracts(asm_json_dict: Dict):
    for contract_name, asm_contract in asm_json_dict.items():
        with open(contract_name + ".json_solc", 'w') as f:
            print("STORING...", contract_name + ".json_solc")
            json.dump(asm_contract.to_asm_json(), f, indent=4)


if __name__ == "__main__":
    global args
    
    print("Green Main")
    parse_args()

    #For testing
    # gasol_main.init()
    # run_gasol_test()
    # raise Exception
    
    opt_blocks, asm_inputs = run_ethir()

    logging.debug("OPT blocks" + str(opt_blocks))
    logging.debug("ASM inputs" + str(asm_inputs))
    
    # Set push0 global variable to the corresponding flag
    constants._set_push0(args.push0_enabled)
    args.optimized_predictor_model = None

    # print_blocks(opt_blocks, asm_inputs)

    # If we only consider blocks that can be further optimized, we just analyze directly the corresponding info
    if args.assembly_generation:
        asm_json_dict = optimize_all_blocks(opt_blocks, asm_inputs)
        store_asm_json_contracts(asm_json_dict)
    # Otherwise, we consider the asm blocks
    else:
        optimize_optimizable_blocks(opt_blocks)

    # print("*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*")
    # for o in opt_blocks:
    #     opt_blocks[o].print_blocks()
    # raise Exception
