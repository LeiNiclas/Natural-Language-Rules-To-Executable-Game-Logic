import subprocess
import config

# ================================================================
# Internal functions
# ================================================================
def _run_goal(pl_file : str, goal : str) -> subprocess.CompletedProcess:
    safe_path = pl_file.replace("\\", "/")
    
    return subprocess.run(
        ["swipl", "-g", f"consult('{safe_path}'), {goal}", "-t", "halt(1)"],
        capture_output=True, text=True, timeout=config.SWIPL_TIMEOUT
    )


def _goal(pl_file : str, goal : str) -> str:
    result = _run_goal(pl_file, goal)
    
    return result.stdout.strip()


def _split_top_level(s : str) -> list[str]:
    parts = []
    depth = 0
    current = []
    
    for ch in s:
        if ch == "(":
            depth += 1
            current.append(ch)
        elif ch == ")":
            depth -= 1
            current.append(ch)
        elif ch == "," and depth == 0:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
    
    if current:
        parts.append("".join(current).strip())
    
    return [p for p in parts if p]
# ================================================================ 


# ================================================================
# Public endpoints
# ================================================================
def get_initial_state(pl_file : str) -> str | None:
    out = _goal(pl_file, "initial_state(S), write(S), halt")
    
    return out if out else None


def get_current_player(pl_file : str, state : str) -> str | None:
    out = _goal(pl_file, f"current_player({state}, P), write(P), halt")
    
    return out if out else None


def get_legal_moves(pl_file : str, state : str) -> list[str]:
    out = _goal(
        pl_file,
        f"findall(M, legal_move({state}, M), Moves), write(Moves), halt"
    )
    
    if not out or out == "[]":
        return []
    
    inner = out.strip()[1:-1] # Remove [ and ]
    
    return _split_top_level(inner)


def apply_move(pl_file : str, state : str, move : str) -> str | None:
    out = _goal(
        pl_file,
        f"(apply_move({state}, {move}, New) -> write(New) ; true), halt"
    )
    
    return out if out else None


def check_game_over(pl_file : str, state : str) -> str | None:
    out = _goal(
        pl_file,
        f"(game_over({state}, W) -> write(W) ; true), halt"
    )
    
    return out if out else None


def render_state(pl_file : str, state : str) -> str:
    result = _run_goal(pl_file, f"render_state({state}), halt")
    
    return result.stdout.strip()
# ================================================================
