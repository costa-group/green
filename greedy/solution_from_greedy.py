"""
Adapted from /private_gasol_with_ml/smt_encoding. Remove transformation from minizinc model

"""
from  gasol_optimizer.smt_encoding.complete_encoding.synthesis_full_encoding import SMS_T
from  gasol_asm import OptimizeOutcome
from .algorithm import greedy_from_json
import resource
from typing import List, Tuple

def greedy_to_gasol(sms:SMS_T) -> Tuple[OptimizeOutcome, float, List[str]]:
    usage_start = resource.getrusage(resource.RUSAGE_SELF)
    try:
        greedy_json, _, _, resids, error = greedy_from_json(sms)
        usage_stop = resource.getrusage(resource.RUSAGE_SELF)
    except:
        usage_stop = resource.getrusage(resource.RUSAGE_SELF)
        error = 1
        resids = []
    optimization_outcome = OptimizeOutcome.error if error == 1 else OptimizeOutcome.non_optimal
    return optimization_outcome, usage_stop.ru_utime + usage_stop.ru_stime - usage_start.ru_utime - usage_start.ru_stime, resids
