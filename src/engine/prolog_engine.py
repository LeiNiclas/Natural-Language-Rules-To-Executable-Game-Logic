"""
prolog_engine.py
----------------
Thin wrapper around SWI-Prolog.

All public functions raise PrologError on hard failures so callers can
distinguish "engine broken" from "move was illegal / game still going".
"""

import subprocess
import config

# ================================================================
# Exceptions
# ================================================================
class PrologError(RuntimeError):
    """Raised when SWI-Prolog itself fails (not found, load error, timeout)."""


# ================================================================
# Internal helpers
# ================================================================
def _run_goal(pl_file: str, goal: str) -> subprocess.CompletedProcess:
    """
    Spawn swipl, consult *pl_file*, run *goal*, then halt.
    Raises PrologError on timeout or if swipl cannot be found.
    """
    safe_path = pl_file.replace("\\", "/")
    try:
        return subprocess.run(
            ["swipl", "-g", f"consult('{safe_path}'), {goal}", "-t", "halt(1)"],
            capture_output=True,
            text=True,
            timeout=config.SWIPL_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        raise PrologError(f"SWI-Prolog timed out running goal: {goal}")
    except FileNotFoundError:
        raise PrologError(
            "swipl not found on PATH. Is SWI-Prolog installed?"
        )


def _goal(pl_file: str, goal: str) -> str:
    """Run *goal* and return stripped stdout. Raises PrologError on load errors."""
    result = _run_goal(pl_file, goal)
    # A non-zero exit with stderr almost always means a load/syntax error.
    if result.returncode != 0 and result.stderr.strip():
        raise PrologError(f"Prolog error:\n{result.stderr.strip()}")
    return result.stdout.strip()


def _split_top_level(s: str) -> list[str]:
    """Split a comma-separated Prolog list body respecting nested parens."""
    parts: list[str] = []
    depth = 0
    current: list[str] = []

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
# Public endpoints
# ================================================================
def get_initial_state(pl_file: str) -> str | None:
    try:
        out = _goal(pl_file, "initial_state(S), write(S), halt")
        return out if out else None
    except PrologError:
        return None


def get_current_player(pl_file: str, state: str) -> str | None:
    try:
        out = _goal(pl_file, f"current_player({state}, P), write(P), halt")
        return out if out else None
    except PrologError:
        return None


def get_legal_moves(pl_file: str, state: str) -> list[str]:
    try:
        out = _goal(
            pl_file,
            f"findall(M, legal_move({state}, M), Moves), write(Moves), halt",
        )
    except PrologError:
        return []

    if not out or out == "[]":
        return []

    inner = out.strip()[1:-1]  # strip [ and ]
    return _split_top_level(inner)


def apply_move(pl_file: str, state: str, move: str) -> str | None:
    try:
        out = _goal(
            pl_file,
            f"(apply_move({state}, {move}, New) -> write(New) ; true), halt",
        )
        return out if out else None
    except PrologError:
        return None


def check_game_over(pl_file: str, state: str) -> str | None:
    try:
        out = _goal(
            pl_file,
            f"(game_over({state}, W) -> write(W) ; true), halt",
        )
        return out if out else None
    except PrologError:
        return None


def render_state(pl_file: str, state: str) -> str:
    try:
        result = _run_goal(pl_file, f"render_state({state}), halt")
        return result.stdout.strip()
    except PrologError as e:
        return f"[render error: {e}]"