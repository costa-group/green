#!/usr/bin/python3
import argparse
import json
import os
import shutil
import sys
from typing import Tuple, Optional, List, Dict
from copy import deepcopy
from timeit import default_timer as dtimer
from argparse import ArgumentParser, Namespace

import pandas as pd

sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/gasol_ml")

import global_params.constants as constants
import global_params.paths as paths
import sfs_generator.ir_block as ir_block
from sfs_generator.gasol_optimization import get_sfs_dict,get_discount_op
from sfs_generator.parser_asm import (parse_asm,
                                      generate_block_from_plain_instructions,
                                      parse_blocks_from_plain_instructions)
from sfs_generator.utils import process_blocks_split
from verification.sfs_verify import verify_block_from_list_of_sfs, are_equals
from solution_generation.optimize_from_sub_blocks import rebuild_optimized_asm_block
from sfs_generator.asm_block import AsmBlock, AsmBytecode
from smt_encoding.block_optimizer import BlockOptimizer, OptimizeOutcome
from solution_generation.ids2asm import asm_from_ids
# from greedy.solution_from_greedy import greedy_to_gasol


def init():
    global previous_gas
    previous_gas = 0

    global new_gas
    new_gas = 0

    global previous_size
    previous_size = 0

    global new_size
    new_size = 0

    global new_n_instrs
    new_n_instrs = 0

    global prev_n_instrs
    prev_n_instrs = 0

    global equal_aliasing
    equal_aliasing = False

    global sfs_information
    sfs_information = {}

def select_model_and_config(model: str, criteria: str, i: int) -> Tuple[str, int]:
    configurations = {"bound_size": ("bound_size.pyt", 4), "bound_gas": ("bound_gas.pyt", 4),
                      "opt_size": ("opt_size.pyt", 0),
                      "opt_gas": ("opt_gas.pyt", 0)}

    selected_config = configurations.get(f"{model}_{criteria}", [])
    return f"models/{selected_config[0]}", selected_config[1]


def create_ml_models(parsed_args: Namespace) -> None:
    if parsed_args.bound_select or parsed_args.opt_select:
        import torch
        torch.set_num_threads(1)
        torch.set_num_interop_threads(1)

    criteria = "size" if parsed_args.size else "gas"

    if parsed_args.bound_select:
        import gasol_ml.bound_predictor as bound_predictor

        model_name, conf = select_model_and_config("bound", criteria, parsed_args.bound_select)
        parsed_args.bound_model = bound_predictor.ModelQuery(model_name, conf)
    else:
        parsed_args.bound_model = None

    if parsed_args.opt_select:
        import gasol_ml.opt_predictor as opt_predictor

        model_name, conf = select_model_and_config("opt", criteria, parsed_args.opt_select)
        parsed_args.optimized_predictor_model = opt_predictor.ModelQuery(model_name, conf)
    else:
        parsed_args.optimized_predictor_model = None


def compute_original_sfs_with_simplifications(block: AsmBlock, parsed_args: Namespace, dep_mem_info: Dict = {}, opt_info: Dict = {}):
    stack_size = block.source_stack
    block_name = block.block_name
    block_id = block.block_id
    instructions = block.to_plain()

    instructions_to_optimize = block.instructions_to_optimize_plain()

    if ("REVERT" in instructions or "RETURN" in instructions) and parsed_args.terminal:
        revert_flag = True
    else:
        revert_flag = False

    # if last_const:
    #     new_stack_size, rest_instructions = remove_last_constant_instructions(instructions_to_optimize)
    # else:
    #     new_stack_size = stack_size

    block_data = {"instructions": instructions_to_optimize, "input": stack_size}

    fname = parsed_args.input_path.split("/")[-1].split(".")[0]
    
    exit_code, subblocks_list = \
        ir_block.evm2rbr_compiler(file_name=fname, block=block_data, block_name=block_name, block_id=block_id,
                                  simplification=not parsed_args.no_simp, storage=parsed_args.storage,
                                  size=parsed_args.size, part=parsed_args.partition,
                                  pop=not parsed_args.pop_basic, push=not parsed_args.push_basic, revert=revert_flag,
                                  extra_dependences_info=dep_mem_info,extra_opt_info=opt_info,debug_info=parsed_args.debug_flag)

    sfs_dict = get_sfs_dict()

    return sfs_dict, subblocks_list


# Given the sequence of bytecodes, the initial stack size, the contract name and the
# block id, returns the output given by the solver, the name given to that block and current gas associated
# to that sequence.
def optimize_block(sfs_dict, timeout, parsed_args: Namespace, dep_mem_info: Dict = {}, opt_info: Dict = {}) -> List[Tuple[AsmBlock, OptimizeOutcome, float,
List[AsmBytecode], int, int, List[str], List[str]]]:
    block_solutions = []
    # SFS dict of syrup contract contains all sub-blocks derived from a block after splitting
    for block_name in sfs_dict:
        sfs_block = sfs_dict[block_name]
        initial_solver_bound = sfs_block['init_progr_len']
        original_instr = sfs_block['original_instrs']
        previous_bound = sfs_block['init_progr_len']
        original_block = generate_block_from_plain_instructions(original_instr, block_name)

        if parsed_args.bound_model is not None:
            inferred_bound = parsed_args.bound_model.eval(sfs_block)
            if inferred_bound == 0:
                new_bound = previous_bound
            else:
                new_bound = min(previous_bound, inferred_bound)
            sfs_block['init_progr_len'] = new_bound

            if parsed_args.debug_flag:
                print(f"Previous bound: {previous_bound} Inferred bound: {inferred_bound} Final bound: {new_bound}")

        # To match previous results, multiply timeout by number of storage instructions
        # TODO devise better heuristics to deal with timeouts
        if parsed_args.direct_timeout:
            tout = parsed_args.tout
        else:
            if opt_info.get("dependences",False) and not opt_info.get("non_aliasing_disabled",False):
                taux = 2.5*(len(dep_mem_info.get_equal_pairs_memory())+len(dep_mem_info.get_nonequal_pairs_memory()))
            elif opt_info.get("context",False):
                taux = 2*(len(dep_mem_info.get_aliasing_context())+len(dep_mem_info.get_constancy_context()))
            elif opt_info.get("useless",False):
                taux = len(dep_mem_info.get_useless_info())
            else:
                taux = 0
            tout = parsed_args.tout * (1 + len([True for instr in sfs_block['user_instrs'] if instr["storage"]])+taux)

        optimizer = BlockOptimizer(block_name, sfs_block, parsed_args, tout)
        print(f"Optimizing {block_name}... Timeout:{str(tout)}")

        if parsed_args.greedy or parsed_args.backend:
            if parsed_args.greedy:
                # optimization_outcome, solver_time, optimized_ids = greedy_to_gasol(sfs_block)
                pass
            else:
                optimization_outcome, solver_time, optimized_ids = optimizer.optimize_block()

            optimized_asm = asm_from_ids(sfs_block, optimized_ids)
            block_solutions.append((original_block, optimization_outcome, solver_time,
                                    optimized_asm, tout, initial_solver_bound, sfs_block['rules'], optimized_ids))
        else:
            optimizer.generate_intermediate_files()

    return block_solutions


# Given the log file loaded in json format, current block and the contract name, generates three dicts: one that
# contains the sfs from each block, the second one contains the sequence of instructions and
# the third one is a set that contains all block ids.
def generate_sfs_dicts_from_log(block, json_log, parsed_args: Namespace):
    contracts_dict, sub_block_list = compute_original_sfs_with_simplifications(block, parsed_args)
    syrup_contracts = contracts_dict["syrup_contract"]

    # Contains sfs blocks considered to check the SMT problem. Therefore, a block is added from
    # sfs_original iff solver could not find an optimized solution, and from sfs_dict otherwise.
    optimized_sfs_dict = {}

    # Dict that contains all instr sequences
    instr_sequence_dict = {}

    # Set that contains all ids
    ids = set()

    # We need to inspect all sub-blocks in the sfs dict.
    for block_id in syrup_contracts:

        ids.add(block_id)

        # If the id is not at json log, this means it has not been optimized
        if block_id not in json_log:
            continue

        instr_sequence = json_log[block_id]

        sfs_block = syrup_contracts[block_id]

        optimized_sfs_dict[block_id] = sfs_block
        instr_sequence_dict[block_id] = instr_sequence

    return syrup_contracts, optimized_sfs_dict, sub_block_list, instr_sequence_dict, ids


# Given a dict with the sfs from each block and another dict that contains whether previous block was optimized or not,
# generates the corresponding solution. All checks are assumed to have been done previously
def optimize_asm_block_from_log(block, sfs_dict, sub_block_list, instr_sequence_dict: Dict[str, List[str]]):
    # Optimized blocks. When a block is not optimized, None is pushed to the list.
    optimized_blocks = {}

    for sub_block_name, sfs_sub_block in sfs_dict.items():

        if sub_block_name not in instr_sequence_dict:
            optimized_blocks[sub_block_name] = None
        else:
            new_sub_block = asm_from_ids(sfs_sub_block, instr_sequence_dict[sub_block_name])
            optimized_blocks[sub_block_name] = new_sub_block

    new_block = rebuild_optimized_asm_block(block, sub_block_list, optimized_blocks)

    return new_block


def optimize_asm_from_log(file_name, json_log, output_file, parsed_args: Namespace):
    asm = parse_asm(file_name)

    # Blocks from all contracts are checked together. Thus, we first will obtain the needed
    # information from each block
    sfs_dict_to_check, instr_sequence_dict, file_ids = {}, {}, set()
    contracts = []

    for c in asm.contracts:

        new_contract = deepcopy(c)

        # If it does not have the asm field, then we skip it, as there are no instructions to optimize
        if not c.has_asm_field:
            contracts.append(new_contract)
            continue

        contract_name = c.shortened_name
        init_code = c.init_code
        init_code_blocks = []

        print("\nAnalyzing Init Code of: " + contract_name)
        print("-----------------------------------------\n")
        for block in init_code:

            if block.instructions_to_optimize_plain() == []:
                init_code_blocks.append(deepcopy(block))
                continue

            sfs_all, sfs_optimized, sub_block_list, instr_sequence_dict_block, block_ids = \
                generate_sfs_dicts_from_log(block, json_log, parsed_args)

            new_block = optimize_asm_block_from_log(block, sfs_all, sub_block_list, instr_sequence_dict_block)
            eq, reason = compare_asm_block_asm_format(block, new_block, parsed_args)

            if not eq:
                raise ValueError(f"Error parsing the log file. [REASON]: {reason}")

            init_code_blocks.append(new_block)

        new_contract.init_code = init_code_blocks

        print("\nAnalyzing Runtime Code of: " + contract_name)
        print("-----------------------------------------\n")
        for identifier in c.get_data_ids_with_code():
            blocks = c.get_run_code(identifier)

            run_code_blocks = []

            for block in blocks:

                if block.instructions_to_optimize_plain() == []:
                    run_code_blocks.append(deepcopy(block))
                    continue

                sfs_all, sfs_optimized, sub_block_list, instr_sequence_dict_block, block_ids = \
                    generate_sfs_dicts_from_log(block, json_log, parsed_args)

                new_block = optimize_asm_block_from_log(block, sfs_all, sub_block_list, instr_sequence_dict_block)
                eq, reason = compare_asm_block_asm_format(block, new_block, parsed_args)

                if not eq:
                    raise ValueError(f"Error parsing the log file. [REASON]: {reason}")

                run_code_blocks.append(new_block)

            new_contract.set_run_code(identifier, run_code_blocks)

        contracts.append(new_contract)

    print("Solution generated from log file has been verified correctly")
    new_asm = deepcopy(asm)
    new_asm.contracts = contracts

    with open(output_file, 'w') as f:
        f.write(json.dumps(new_asm.to_json()))

    print("")
    print("Optimized code stored at " + output_file)


def optimize_isolated_asm_block(file_name, output_file, csv_file, parsed_args: Namespace, timeout=10, block_name="",
                                block_name_prefix=""):
    statistics_rows = []

    with open(file_name, "r") as f:
        instructions = f.read()

    blocks = parse_blocks_from_plain_instructions(instructions, block_name, block_name_prefix)
    asm_blocks = []

    for old_block in blocks:
        asm_block, _, statistics_csv = optimize_asm_block_asm_format(old_block, timeout, parsed_args)
        statistics_rows.extend(statistics_csv)

        eq, reason = compare_asm_block_asm_format(old_block, asm_block, parsed_args)

        if not eq:
            print("Comparison failed, so initial block is kept")
            print("\t[REASON]: " + reason)
            print(old_block.to_plain())
            print(asm_block.to_plain())
            print("")
            asm_block = old_block

        update_gas_count(old_block, asm_block)
        update_length_count(old_block, asm_block)
        update_size_count(old_block, asm_block)
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


def update_gas_count(old_block: AsmBlock, new_block: AsmBlock):
    global previous_gas
    global new_gas

    previous_gas += old_block.gas_spent
    new_gas += new_block.gas_spent


def update_size_count(old_block: AsmBlock, new_block: AsmBlock):
    global previous_size
    global new_size

    previous_size += old_block.bytes_required
    new_size += new_block.bytes_required


def update_length_count(old_block: AsmBlock, new_block: AsmBlock):
    global prev_n_instrs
    global new_n_instrs

    prev_n_instrs += len([True for instruction in old_block.instructions if instruction.disasm != 'tag'])
    new_n_instrs += len([True for instruction in new_block.instructions if instruction.disasm != 'tag'])


def generate_statistics_info(original_block: AsmBlock, outcome: Optional[OptimizeOutcome], solver_time: float,
                             optimized_block: AsmBlock, initial_bound: int, tout: int, rules: List[str]) -> Dict:
    block_name = original_block.block_name
    original_instr = ' '.join(original_block.instructions_to_optimize_plain())

    statistics_row = {"block_id": block_name, "previous_solution": original_instr, "timeout": tout,
                      "initial_n_instrs": initial_bound, 'initial_estimated_size': original_block.bytes_required,
                      'initial_estimated_gas': original_block.gas_spent, 'rules': ','.join(rules),
                      'initial_length': len(original_block.instructions_to_optimize_plain()),
                      'saved_length': 0}

    # The outcome of the solver is unsat
    if outcome == OptimizeOutcome.unsat:
        statistics_row.update(
            {"model_found": False, "shown_optimal": False, "solver_time_in_sec": round(solver_time, 3),
             "saved_size": 0, "saved_gas": 0, 'outcome': 'unsat'})

    # The solver has returned no model
    elif outcome == OptimizeOutcome.no_model:
        statistics_row.update(
            {"model_found": False, "shown_optimal": False, "solver_time_in_sec": round(solver_time, 3),
             "saved_size": 0, "saved_gas": 0, 'outcome': 'no_model'})

    # The solver has returned a valid model
    else:
        shown_optimal = outcome == OptimizeOutcome.optimal
        optimized_size = optimized_block.bytes_required
        optimized_gas = optimized_block.gas_spent
        optimized_length = len(optimized_block.instructions_to_optimize_plain())
        initial_size = original_block.bytes_required
        initial_gas = original_block.gas_spent
        initial_length = len(original_block.instructions_to_optimize_plain())

        statistics_row.update({"solver_time_in_sec": round(solver_time, 3), "saved_size": initial_size - optimized_size,
                               "saved_gas": initial_gas - optimized_gas, "model_found": True,
                               "shown_optimal": shown_optimal,
                               "solution_found": ' '.join([instr.to_plain() for instr in optimized_block.instructions]),
                               "optimized_n_instrs": optimized_length, 'optimized_length': optimized_length,
                               'optimized_estimated_size': optimized_size, 'optimized_estimated_gas': optimized_gas,
                               'outcome': 'model', 'saved_length': initial_length - optimized_length})

    return statistics_row


def improves_criterion(saved_criterion: int, *saved_other):
    if saved_criterion > 0:
        return True
    elif saved_criterion == 0:
        any_improves = False
        for crit in saved_other:
            if crit > 0:
                any_improves = True
            elif crit < 0:
                return False
        return any_improves
    else:
        return False


def block_has_been_optimized(original_block: AsmBlock, optimized_block: AsmBlock,
                             size_criterion: bool, length_criterion: bool) -> bool:
    saved_size = original_block.bytes_required - optimized_block.bytes_required
    saved_gas = original_block.gas_spent - optimized_block.gas_spent
    saved_length = original_block.length - optimized_block.length

    return (size_criterion and improves_criterion(saved_size, saved_gas)) or \
        (length_criterion and improves_criterion(saved_length, saved_gas, saved_size)) or \
        (not size_criterion and not length_criterion and improves_criterion(saved_gas, saved_size))


# Given an asm_block and its contract name, returns the asm block after the optimization
def optimize_asm_block_asm_format(block: AsmBlock, timeout: int, parsed_args: Namespace, dep_mem_info: Dict = {}, opt_info: Dict = {}) -> \
Tuple[AsmBlock, Dict, List[Dict]]:
    global equal_aliasing
    global sfs_information
    
    csv_statistics = []
    new_block = deepcopy(block)
    
    # Optimized blocks. When a block is not optimized, None is pushed to the list.
    optimized_blocks = {}

    log_dicts = {}

    instructions = block.instructions_to_optimize_plain()

    sfs_dict = {}
    # No instructions to optimize
    if instructions == []:
        return new_block, {}, []

    if parsed_args.optimized_predictor_model is not None and parsed_args.backend:

        stack_size = block.source_stack

        instructions_to_optimize = block.instructions_to_optimize_plain()
        block_data = {"instructions": instructions_to_optimize, "input": stack_size}
        sub_block_list = ir_block.get_subblocks(block_data, storage=parsed_args.storage, part=parsed_args.partition)
        subblocks2analyze = [instructions for instructions in process_blocks_split(sub_block_list)]

        for i, subblock in enumerate(subblocks2analyze):
            # If we have an empty sub block, we just consider it has not been optimized and go on with the new block
            if subblock == []:
                continue

            ins_str = " ".join(subblock)
            new_block = parse_blocks_from_plain_instructions(ins_str)[0]
            new_block.set_block_name(block.get_block_name())
            new_block.set_block_id(i)
            out = parsed_args.optimized_predictor_model.eval(ins_str)

            # The new sub block name is generated as follows. Important to match the format in the sfs_dict
            sub_block_name = f'{new_block.get_block_name()}_{new_block.get_block_id()}'

            # Out == 1 means the predictors predicts the block won't lead to any optimization, and hence, it's not worthy
            # to try optimization
            if out == 0:
                optimized_blocks[sub_block_name] = None
                if parsed_args.debug_flag:
                    print(f"{block.block_name} has been chosen not to be optimized")

            else:
                try:
                    contracts_dict, _ = compute_original_sfs_with_simplifications(new_block, parsed_args, dep_mem_info,opt_info)
                except Exception as e:
                    failed_row = {'instructions': instructions, 'exception': str(e)}
                    return new_block, {}, []

                old_name = list(contracts_dict["syrup_contract"].keys())[0]
                sfs_dict[sub_block_name] = contracts_dict["syrup_contract"][old_name]

    else:
        try:
            contracts_dict, sub_block_list = compute_original_sfs_with_simplifications(block, parsed_args, dep_mem_info,opt_info)
            if (opt_info.get("dependences",False) or opt_info.get("context",False)):
                old_val = parsed_args.debug_flag
                parsed_args.debug_flag = False
                if parsed_args.debug_flag:
                    print("COMPUTING SFS WIITHUT HEAP INFO")
                contracts_dict_init, sub_block_list_init = compute_original_sfs_with_simplifications(block, parsed_args, dep_mem_info,{})
                parsed_args.debug_flag = old_val
                sfs_dict_extra = contracts_dict_init["syrup_contract"]
                sfs_dict_origin = contracts_dict["syrup_contract"]
                if sfs_dict_extra == sfs_dict_origin:
                    equal_aliasing = True
                    return new_block, {}, [] 
        except Exception as e:
            failed_row = {'instructions': instructions, 'exception': str(e)}
            return new_block, {}, []

        
        sfs_dict = contracts_dict["syrup_contract"]
        sfs_information = {}
        for s in sfs_dict:
            sfs_information[s] = {}
            sfs_information[s]["rules"]= sfs_dict[s]["rules"]
            sfs_information[s]["deps"]= sfs_dict[s]["memory_dependences"]
            sfs_information[s]["discount_op"] = get_discount_op()
            
    if not parsed_args.backend:
        optimize_block(sfs_dict, timeout, parsed_args,dep_mem_info, opt_info)
        return new_block, {}, []

    for sub_block, optimization_outcome, solver_time, optimized_asm, tout, initial_solver_bound, rules, optimized_log_rep in optimize_block(
            sfs_dict, timeout, parsed_args,dep_mem_info, opt_info):

        optimal_block = AsmBlock('optimized', sub_block.block_id, sub_block.block_name, sub_block.is_init_block)
        optimal_block.instructions = optimized_asm

        statistics_info = generate_statistics_info(sub_block, optimization_outcome, solver_time, optimal_block,
                                                   initial_solver_bound, tout, rules)

        csv_statistics.append(statistics_info)

        # Only check if the new block is considered if the solver has generated a new one
        if optimization_outcome == OptimizeOutcome.non_optimal or optimization_outcome == OptimizeOutcome.optimal:
            sub_block_name = sub_block.block_name
            if block_has_been_optimized(sub_block, optimal_block, parsed_args.size, parsed_args.length):
                optimized_blocks[sub_block_name] = optimized_asm
                log_dicts[sub_block_name] = optimized_log_rep
            else:
                optimized_blocks[sub_block_name] = None

    new_block = rebuild_optimized_asm_block(block, sub_block_list, optimized_blocks)
    
    return new_block, log_dicts, csv_statistics


def compare_asm_block_asm_format(old_block: AsmBlock, new_block: AsmBlock, parsed_args: Namespace,
                                 dep_mem_info: Dict = {}, opt_info: Dict = {}) -> Tuple[bool, str]:
    new_block.set_block_name("alreadyOptimized_" + new_block.get_block_name())

    old_val = parsed_args.debug_flag
    parsed_args.debug_flag = False
    new_sfs_information, _ = compute_original_sfs_with_simplifications(new_block, parsed_args, dep_mem_info, opt_info)

    new_sfs_dict = new_sfs_information["syrup_contract"]

    old_sfs_information, _ = compute_original_sfs_with_simplifications(old_block, parsed_args, dep_mem_info, opt_info)

    parsed_args.debug_flag = old_val
    
    old_sfs_dict = old_sfs_information["syrup_contract"]

    final_comparison, reason = verify_block_from_list_of_sfs(old_sfs_dict, new_sfs_dict)

    # We also must check intermediate instructions match i.e those that are not sub blocks
    initial_instructions_old = old_block.instructions_initial_bytecode()
    initial_instructions_new = new_block.instructions_initial_bytecode()

    final_instructions_old = old_block.instructions_final_bytecode()
    final_instructions_new = new_block.instructions_final_bytecode()

    return final_comparison and (initial_instructions_new == initial_instructions_old) and \
           final_instructions_new == final_instructions_old, reason


def optimize_asm_in_asm_format(file_name, output_file, csv_file, log_file, parsed_args: Namespace, timeout=10):
    statistics_rows = []

    asm = parse_asm(file_name)
    log_dicts = {}
    contracts = []

    for c in asm.contracts:

        new_contract = deepcopy(c)

        # If it does not have the asm field, then we skip it, as there are no instructions to optimize. Same if a
        # contract has been specified and current name does not match.
        if not c.has_asm_field or (parsed_args.contract is not None and c.shortened_name != parsed_args.contract):
            contracts.append(new_contract)
            continue

        contract_name = c.shortened_name
        init_code = c.init_code

        print("\nAnalyzing Init Code of: " + contract_name)
        print("-----------------------------------------\n")

        init_code_blocks = []

        for old_block in init_code:
            optimized_block, log_element, csv_statistics = optimize_asm_block_asm_format(old_block, timeout,
                                                                                         parsed_args)
            statistics_rows.extend(csv_statistics)

            eq, reason = compare_asm_block_asm_format(old_block, optimized_block, parsed_args)

            if not eq:
                print("Comparison failed, so initial block is kept")
                print("\t[REASON]: " + reason)
                print(old_block.to_plain())
                print(optimized_block.to_plain())
                print("")
                optimized_block = old_block
                log_element = {}

            log_dicts.update(log_element)
            init_code_blocks.append(optimized_block)

            # Deployment size is not considered when measuring it
            update_gas_count(old_block, optimized_block)
            update_length_count(old_block, optimized_block)

        new_contract.init_code = init_code_blocks

        print("\nAnalyzing Runtime Code of: " + contract_name)
        print("-----------------------------------------\n")
        for identifier in c.get_data_ids_with_code():
            blocks = c.get_run_code(identifier)

            run_code_blocks = []
            for old_block in blocks:
                optimized_block, log_element, csv_statistics = optimize_asm_block_asm_format(old_block, timeout,
                                                                                             parsed_args)
                statistics_rows.extend(csv_statistics)

                eq, reason = compare_asm_block_asm_format(old_block, optimized_block, parsed_args)

                if not eq:
                    print("Comparison failed, so initial block is kept")
                    print("\t[REASON]: " + reason)
                    print(old_block.to_plain())
                    print(optimized_block.to_plain())
                    print("")
                    optimized_block = old_block
                    log_element = {}

                log_dicts.update(log_element)
                run_code_blocks.append(optimized_block)

                update_gas_count(old_block, optimized_block)
                update_length_count(old_block, optimized_block)
                update_size_count(old_block, optimized_block)

            new_contract.set_run_code(identifier, run_code_blocks)

        contracts.append(new_contract)

    new_asm = deepcopy(asm)
    new_asm.contracts = contracts

    if parsed_args.log:
        with open(log_file, "w") as log_f:
            json.dump(log_dicts, log_f)

    if parsed_args.backend:
        with open(output_file, 'w') as f:
            f.write(json.dumps(new_asm.to_json()))

        df = pd.DataFrame(statistics_rows)
        df.to_csv(csv_file)


def optimize_from_sfs(json_file: str, output_file: str, csv_file: str, parsed_args: Namespace):
    block_name = 'isolated_block_sfs'

    with open(json_file, 'r') as f:
        sfs_block = json.load(f)

    sfs_dict = {block_name: sfs_block}

    csv_statistics = []
    for original_block, optimization_outcome, solver_time, optimized_asm, tout, initial_solver_bound, rules, optimized_log_rep \
            in optimize_block(sfs_dict, parsed_args.tout, parsed_args):

        optimal_block = AsmBlock('optimized', original_block.block_id, original_block.block_name,
                                 original_block.is_init_block)
        optimal_block.instructions = optimized_asm

        statistics_info = generate_statistics_info(original_block, optimization_outcome, solver_time, optimal_block,
                                                   initial_solver_bound, tout, rules)

        csv_statistics.append(statistics_info)

        new_sfs_information, _ = compute_original_sfs_with_simplifications(original_block, parsed_args)
        new_sfs_block = new_sfs_information["syrup_contract"][block_name + '_0']

        eq, reason = are_equals(sfs_block, new_sfs_block)

        final_block = original_block

        if not eq:
            print("Comparison failed, so initial block is kept")
            print("\t[REASON]: " + reason)
            print("")

        elif (optimization_outcome == OptimizeOutcome.optimal or optimization_outcome == OptimizeOutcome.optimal) \
                and block_has_been_optimized(original_block, optimal_block, parsed_args.size, parsed_args.length):
            final_block = deepcopy(original_block)
            final_block.instructions = optimized_asm

        update_gas_count(original_block, final_block)
        update_length_count(original_block, final_block)
        update_size_count(original_block, final_block)

    if parsed_args.backend:
        df = pd.DataFrame(csv_statistics)
        df.to_csv(csv_file)
        print("")
        print("Initial sequence (basic block per line):")
        print(original_block.to_plain_with_byte_number())
        print("")
        print("Optimized sequence (basic block per line):")
        print(final_block.to_plain_with_byte_number())
        with open(output_file, 'w') as f:
            f.write(json.dumps(new_sfs_block))

        df = pd.DataFrame(csv_statistics)
        df.to_csv(csv_file)


def final_file_names(parsed_args: argparse.Namespace) -> Tuple[str, str, str]:
    input_file_name = parsed_args.input_path.split("/")[-1].split(".")[0]

    if parsed_args.output_path is None:
        if parsed_args.block:
            output_file = input_file_name + "_optimized.txt"
        elif parsed_args.sfs:
            output_file = input_file_name + "_optimized.json"
        elif parsed_args.log_path is not None:
            output_file = input_file_name + "_optimized_from_log.json_solc"
        else:
            output_file = input_file_name + "_optimized.json_solc"
    else:
        output_file = parsed_args.output_path

    if parsed_args.csv_path is None:
        csv_file = input_file_name + "_statistics.csv"
    else:
        csv_file = parsed_args.csv_path

    if parsed_args.log_stored_final is None:
        log_file = input_file_name + ".log"
    else:
        log_file = parsed_args.log_stored_final

    return output_file, csv_file, log_file


def parse_encoding_args() -> Namespace:
    # Unused options
    # ap.add_argument("-last-constants", "--last-constants", help="It removes the last instructions of a block when they generate a constant value", dest="last_constants", action = "store_true")
    # ap.add_argument("-mem40", "--mem40", help="It assumes that pos 64 in memory is not dependant with variables", action = "store_true")

    ap = ArgumentParser(description='GASOL, the EVM super-optimizer')

    input = ap.add_argument_group('Input options')

    input.add_argument('input_path', help='Path to input file that contains the code to optimize. Can be either asm, '
                                          'plain instructions or a json containing the SFS. The corresponding flag'
                                          'must be enabled')
    group_input = input.add_mutually_exclusive_group()
    group_input.add_argument("-bl", "--block", help="Enable analysis of a single asm block", action="store_true")
    group_input.add_argument("-sfs", "--sfs", dest='sfs', help="Enable analysis of a single SFS", action="store_true")
    group_input.add_argument("-c", "--contract", dest="contract", action='store',
                             help='Specify the specific contract in the json_solc to be optimized. The name of the '
                                  'contract must match the name that appears in the solc file. '
                                  'The remaining contracts are left unchanged.')

    output = ap.add_argument_group('Output options')

    output.add_argument("-o", help="Path for storing the optimized code", dest='output_path', action='store')
    output.add_argument("-csv", help="CSV file path", dest='csv_path', action='store')
    output.add_argument("-backend", "--backend", action="store_false",
                        help="Disables backend generation, so that only intermediate files are generated")
    output.add_argument("-intermediate", "--intermediate", action="store_true",
                        help="Keeps temporary intermediate files. "
                             "These files contain the sfs representation, smt encoding...")
    output.add_argument("-d", "--debug", help="It prints debugging information", dest='debug_flag', action="store_true")

    log_generation = ap.add_argument_group('Log generation options', 'Options for managing the log generation')

    log_generation.add_argument("-log", "--generate-log", help="Enable log file for verification",
                                action="store_true", dest='log')
    log_generation.add_argument("-dest-log", help="Log output path", action="store", dest='log_stored_final')
    log_generation.add_argument("-optimize-from-log", dest='log_path', action='store', metavar="log_file",
                                help="Generates the same optimized bytecode than the one associated to the log file")

    basic = ap.add_argument_group('Max-SMT solver general options',
                                  'Basic options for solving the corresponding Max-SMT problem')

    basic.add_argument("-solver", "--solver", help="Choose the solver", choices=["z3", "barcelogic", "oms"],
                       default="oms")
    basic.add_argument("-tout", metavar='timeout', action='store', type=int,
                       help="Timeout in seconds. By default, set to 2s per block.", default=2)
    basic.add_argument("-direct-tout", dest='direct_timeout', action='store_true',
                       help="Sets the Max-SMT timeout to -tout directly, "
                            "without considering the structure of the block")
    basic.add_argument("-push0", "--push0", dest='push0_enabled', action='store_true',
                       help="Enables reasoning for optimizations with PUSH0 opcode.")
    basic.add_argument('-greedy', '--greedy', dest='greedy', help='Uses greedy directly to generate the results',
                       action='store_true')

    blocks = ap.add_argument_group('Split block options', 'Options for deciding how to split blocks when optimizing')

    blocks.add_argument("-storage", "--storage", help="Split using SSTORE, MSTORE and MSTORE8", action="store_true")
    blocks.add_argument("-partition", "--partition", help="It enables the partition in blocks of 24 instructions",
                        action="store_true")

    hard = ap.add_argument_group('Hard constraints', 'Options for modifying the hard constraint generation')

    hard.add_argument("-memory-encoding", help="Choose the memory encoding model", choices=["l_vars", "direct"],
                      default="direct", dest='memory_encoding')
    hard.add_argument('-no-simplification', "--no-simplification", action='store_true', dest='no_simp',
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
                           'variables or introducing uninterpreted functions', default='uninterpreted_uf')
    hard.add_argument('-terminal', action='store_true', dest='terminal',
                      help='(UNSUPPORTED) Encoding for terminal blocks that end with REVERT or RETURN. '
                           'Instead of considering the full stack order, just considers the two top elements')
    hard.add_argument('-ac', action='store_true', dest='ac_solver',
                      help='(UNSUPPORTED) Commutativity in operations is considered as an extension inside the solver. '
                           'Can only be combined with Z3')

    soft = ap.add_argument_group('Soft constraints', 'Options for modifying the soft constraint generation')
    group = soft.add_mutually_exclusive_group()
    group.add_argument("-size", "--size", action="store_true",
                       help="It enables size cost model for optimization and disables rules that increase the size"
                            "The simplification rules are applied only if they reduce the size")

    group.add_argument("-length", "--length", action="store_true",
                       help="It enables the #instructions cost model. Every possible simplification rule is applied")

    soft.add_argument("-direct-inequalities", dest='direct', action='store_true',
                      help="Soft constraints with inequalities instead of equalities and without grouping")

    additional = ap.add_argument_group('Additional constraints',
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

    ml_options = ap.add_argument_group('ML Options', 'Options to execute the different ML modules')
    ml_options.add_argument('-bound-model', "--bound-model", action='store_true', dest='bound_select',
                            help="Enable bound regression model")
    ml_options.add_argument('-opt-model', "--opt-model", action='store_true', dest='opt_select',
                            help="Select which representation model is used for the opt classification")

    parsed_args = ap.parse_args()

    # Additional check: if ufs are used, push instructions must be represented as uninterpreted too
    if parsed_args.encode_terms == "uninterpreted_uf":
        parsed_args.push_basic = False

    return parsed_args


if __name__ == '__main__':
    global previous_gas
    global new_gas
    global previous_size
    global new_size
    global prev_n_instrs
    global new_n_instrs

    init()
    parsed_args = parse_encoding_args()
    create_ml_models(parsed_args)

    # If storage or partition flag are activated, the blocks are split using store instructions
    if parsed_args.storage or parsed_args.partition:
        constants.append_store_instructions_to_split()

    # Set push0 global variable to the corresponding flag
    constants._set_push0(parsed_args.push0_enabled)

    output_file, csv_file, log_file = final_file_names(parsed_args)

    x = dtimer()
    if parsed_args.log_path is not None:
        with open(parsed_args.log_path) as path:
            log_dict = json.load(path)
            optimize_asm_from_log(parsed_args.input_path, log_dict, output_file, parsed_args)
            if not parsed_args.intermediate:
                shutil.rmtree(paths.gasol_path, ignore_errors=True)
            exit(0)

    if parsed_args.block:
        optimize_isolated_asm_block(parsed_args.input_path, output_file, csv_file, parsed_args, parsed_args.tout)
    elif parsed_args.sfs:
        optimize_from_sfs(parsed_args.input_path, output_file, csv_file, parsed_args)
    else:
        optimize_asm_in_asm_format(parsed_args.input_path, output_file, csv_file, log_file, parsed_args,
                                   parsed_args.tout)

    y = dtimer()

    print("")
    print("Total time: " + str(round(y - x, 2)) + " s")

    if parsed_args.intermediate or not parsed_args.backend:
        print("")
        print("Intermediate files stored at " + paths.gasol_path)
    else:
        shutil.rmtree(paths.gasol_path, ignore_errors=True)

    if parsed_args.backend:
        print("")
        print("Optimized code stored in " + output_file)
        print("Optimality results stored in " + csv_file)
        print("")
        print("Estimated initial gas: " + str(previous_gas))
        print("Estimated gas optimized: " + str(new_gas))
        print("")
        print("Estimated initial size in bytes: " + str(previous_size))
        print("Estimated size optimized in bytes: " + str(new_size))
        print("")
        print("Initial number of instructions: " + str(prev_n_instrs))
        print("Final number of instructions: " + str(new_n_instrs))

    else:
        print("")
        print("Estimated initial gas: " + str(previous_gas))
        print("")
        print("Estimated initial size in bytes: " + str(previous_size))
        print("")
        print("Initial number of instructions: " + str(new_n_instrs))
