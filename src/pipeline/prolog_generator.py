"""
prolog_generator.py
-------------------
LLM-driven Prolog code generation from structured XML, with validation
and automatic retry/repair via a true multi-turn conversation.

Key design decisions
--------------------
- The repair loop builds a genuine multi-turn message history so the model
  sees every prior attempt and its specific errors. This prevents it from
  repeating the same mistake across retries.
- A lightweight "diagnose" step runs before each repair turn: it asks the
  model to reason about WHY the errors occurred before writing new code.
  This forces a chain-of-thought pass that significantly reduces relapses.
- The Ollama client is a module-level singleton (created once).
- Temp files are always cleaned up via try/finally.
"""

import config
import os
import subprocess

from ollama import Client
from tempfile import NamedTemporaryFile

# Module-level client singleton
_ollama_client: Client | None = None


def _get_client() -> Client:
    global _ollama_client
    if _ollama_client is None:
        _ollama_client = Client()
    return _ollama_client


# ================================================================
# System prompts
# ================================================================
SYSTEM_PROLOG_GENERATOR = r"""\
You are an expert SWI-Prolog developer. You implement games in SWI-Prolog from structured XML.

OUTPUT FORMAT:
- Pure SWI-Prolog code only. No markdown, no fenced blocks, no prose.
- Comments between clauses only, never inside a clause body.

REQUIRED PREDICATES (exact signatures, do not rename or change arity):
  initial_state(State)          % one solution; the starting game state
  current_player(State, P)      % P is the player to move in State
  legal_move(State, Move)       % generative: backtracks over all legal moves
  apply_move(State, Move, New)  % New is State after Move; fail if Move is illegal
  game_over(State, Winner)      % Winner is a player atom or 'draw'; fail if ongoing
  render_state(State)           % print a human-readable board to stdout

SAFE IMPORTS ONLY: library(lists), library(apply). No other libraries.

PROLOG SEMANTICS - these mistakes cause silent failures:
  1. No return values. Predicates bind variables through unification.
     RIGHT: next_player(P, Next)    WRONG: Next = next_player(P)
  2. A variable is bound once. Never pre-unify before passing to a predicate.
     RIGHT: set_nth1(N, Board, V, New)    WRONG: New = Board, set_nth1(N, Board, V, New)
  3. Every variable in a clause head must be used in the body. Use _ if unused.
  4. Goals succeed or fail. They do not return values.
     RIGHT: nth1(N, Board, empty)    WRONG: (nth1(N, Board, empty)) = 1
  5. Atoms start lowercase; variables start uppercase.
     x, o, empty, player1 are atoms.    X, Board, Player are variables.
     RIGHT: initial_state(state(Board, player1))    WRONG: initial_state(state(Board, Player))
  6. When apply_move updates the state, ALL changed fields must appear in NewState.
     RIGHT: set_nth1(Pos, Board, P, NewBoard), next_player(P, Next), NewState = state(NewBoard, Next).

STATE AND BOARD REPRESENTATION:
  Flat list - use for simple grids (Tic-Tac-Toe, Othello):
    Board = [empty, empty, ...] of length rows*cols.
    Helper (include verbatim if used):
      set_nth1(1, [_|T], V, [V|T]).
      set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

  2D list - use when rows are natural units (Connect Four, Checkers):
    Board = [[empty,...], [empty,...], ...] one sublist per row, top to bottom.
    Write helper (include verbatim if used):
      set_cell(Row, Col, Board, Value, NewBoard) :-
          nth1(Row, Board, OldRow),
          set_nth1(Col, OldRow, Value, NewRow),
          set_nth1(Row, Board, NewRow, NewBoard).
      set_nth1(1, [_|T], V, [V|T]).
      set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).
    NEVER use set_nth1 directly on a 2D board.

WIN CONDITIONS:
  - Always check that the winning value is not the neutral/empty atom.
    RIGHT: nth1(I, Board, P), P \= empty

RENDER STATE:
  - Print the neutral/empty atom as '.'. NEVER print the word 'empty'.
    RIGHT: (C = empty -> format('.') ; format('~w', [C]))
  - NEVER wrap atoms in a functor like symbol/1 or cell/1.
"""

FEW_SHOT_PROLOG = """\
REFERENCE IMPLEMENTATION - War (simple card game).
Study structure and signatures. You will implement a DIFFERENT game.

:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(DeckP1, DeckP2, CurrentPlayer)
initial_state(state([c2,c4,c6,c8,c10], [c3,c5,c7,c9,jack], player1)).

current_player(state(_, _, P), P).

legal_move(state([Card|_], _, player1), play(player1, Card)).
legal_move(state(_, [Card|_], player2), play(player2, Card)).

card_value(c2,2). card_value(c3,3). card_value(c4,4). card_value(c5,5).
card_value(c6,6). card_value(c7,7). card_value(c8,8). card_value(c9,9).
card_value(c10,10). card_value(jack,11). card_value(queen,12).
card_value(king,13). card_value(ace,14).

apply_move(state([C1|R1], [C2|R2], player1), play(player1, C1),
           state(NewD1, R2, player2)) :-
    card_value(C1, V1), card_value(C2, V2), V1 > V2,
    append(R1, [C1,C2], NewD1).
apply_move(state([C1|R1], [C2|R2], player1), play(player1, C1),
           state(R1, NewD2, player2)) :-
    card_value(C1, V1), card_value(C2, V2), V2 > V1,
    append(R2, [C2,C1], NewD2).

next_player(player1, player2).
next_player(player2, player1).

game_over(state([], _, _), player2).
game_over(state(_, [], _), player1).

render_state(state(D1, D2, P)) :-
    length(D1, L1), length(D2, L2),
    format("Player: ~w | P1 cards: ~w | P2 cards: ~w~n", [P, L1, L2]).
"""

# Injected into the conversation after each failed attempt, before asking
# for a rewrite. Forces the model to reason about root causes before coding.
_DIAGNOSE_PROMPT = """\
Before writing the corrected code, reason step-by-step about each error:
1. What is the exact root cause (not just a restatement of the error)?
2. Which specific line(s) or clause(s) in your previous code caused it?
3. What is the minimal, correct fix?

Write your diagnosis as plain text. Do NOT write any Prolog yet.
"""

_REWRITE_PROMPT = """\
Now, using your diagnosis above, write the complete corrected SWI-Prolog file.
Pure code only — no markdown, no prose, no fences.
"""


# ================================================================
# Internal helpers
# ================================================================
def _strip_fences(code: str) -> str:
    """Remove markdown code fences the model may have added."""
    s = code.strip()
    if s.startswith("```"):
        lines = s.splitlines()
        start = 1
        end = len(lines) - 1 if lines[-1].strip() == "```" else len(lines)
        s = "\n".join(lines[start:end])
    return s.strip()


def _validate_prolog(prolog_code: str) -> tuple[bool, list[str]]:
    """
    Write *prolog_code* to a temp file and run a battery of swipl checks.
    Returns (all_passed, list_of_error_strings).
    The temp file is always cleaned up via try/finally.
    """
    errors: list[str] = []

    with NamedTemporaryFile(suffix=".pl", mode="w", delete=False, encoding="utf-8") as f:
        f.write(prolog_code)
        tmp = f.name

    def run(goal: str, timeout: int = config.SWIPL_TIMEOUT) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["swipl", "-g", goal, "-t", "halt(1)", tmp],
            capture_output=True,
            text=True,
            timeout=timeout,
        )

    try:
        # Check 1: file loads cleanly
        print("  - Checking file load...")
        r = run("halt", timeout=30)
        if r.returncode != 0:
            errors.append(f"[Load error]\n{r.stderr.strip()}")
            return False, errors  # no point continuing

        # Check 2: initial_state/1
        print("  - Checking initial_state/1...")
        try:
            r = run("(initial_state(_) -> halt(0) ; halt(1))", timeout=30)
            if r.returncode != 0:
                errors.append("[initial_state/1] Did not succeed.")
        except subprocess.TimeoutExpired:
            errors.append("[initial_state/1] Timed out.")

        # Check 3: legal_move/2
        print("  - Checking legal_move/2...")
        try:
            r = run(
                "(initial_state(S), legal_move(S, _) -> halt(0) ; halt(1))",
                timeout=config.SWIPL_TIMEOUT,
            )
            if r.returncode != 0:
                errors.append("[legal_move/2] No legal moves from initial state.")
        except subprocess.TimeoutExpired:
            errors.append("[legal_move/2] Timed out.")

        # Check 4: apply_move/3
        print("  - Checking apply_move/3...")
        try:
            r = run(
                "(initial_state(S), legal_move(S, M), apply_move(S, M, _) -> halt(0) ; halt(1))",
                timeout=30,
            )
            if r.returncode != 0:
                errors.append("[apply_move/3] Failed on first legal move from initial state.")
        except subprocess.TimeoutExpired:
            errors.append("[apply_move/3] Timed out.")

    finally:
        try:
            os.unlink(tmp)
        except OSError:
            pass

    if errors:
        print(f"  Validation found {len(errors)} error(s).")
    else:
        print("  Validation passed!")

    return len(errors) == 0, errors


def _format_errors(errors: list[str]) -> str:
    return "\n".join(f"  - {e}" for e in errors)


# ================================================================
# Public endpoints
# ================================================================
def generate_prolog(xml_str: str) -> tuple[str | None, list[dict]]:
    """
    Generate and validate SWI-Prolog code from *xml_str*.

    Uses a multi-turn conversation so the model sees every prior attempt
    and its errors. A diagnosis step before each rewrite forces the model
    to reason about root causes before producing new code.

    Returns:
        (code, attempts)
        - code     : validated Prolog string, or None if all attempts failed
        - attempts : list of dicts {attempt, code, errors, passed}
                     for display in the UI
    """
    client = _get_client()
    system_msg = {
        "role": "system",
        "content": SYSTEM_PROLOG_GENERATOR + "\n\n" + FEW_SHOT_PROLOG,
    }

    # The conversation history grows with every turn so the model has full context
    history: list[dict] = [system_msg]
    attempt_log: list[dict] = []
    code: str = ""

    for attempt in range(1, config.PROLOG_MAX_RETRIES + 1):
        print(f"  [Prolog gen] attempt {attempt}/{config.PROLOG_MAX_RETRIES}")

        if attempt == 1:
            history.append({
                "role": "user",
                "content": (
                    "Implement the following game in SWI-Prolog. "
                    "Follow every rule in the system prompt exactly.\n\n"
                    + xml_str
                ),
            })
        else:
            # Tell the model what went wrong with its last attempt
            history.append({
                "role": "user",
                "content": (
                    f"Your code failed validation with these errors:\n"
                    f"{_format_errors(errors)}\n\n"
                    f"{_DIAGNOSE_PROMPT}"
                ),
            })
            # Get the diagnosis (plain text, no code yet)
            diagnosis_resp = client.chat(
                config.MODEL_PROLOG_GENERATOR, messages=history
            ).message.content
            history.append({"role": "assistant", "content": diagnosis_resp})

            # Now ask for the actual rewrite
            history.append({"role": "user", "content": _REWRITE_PROMPT})

        raw = client.chat(
            config.MODEL_PROLOG_GENERATOR, messages=history
        ).message.content
        history.append({"role": "assistant", "content": raw})

        code = _strip_fences(raw)
        valid, errors = _validate_prolog(code)

        attempt_log.append({
            "attempt": attempt,
            "code":    code,
            "errors":  errors,
            "passed":  valid,
        })

        if valid:
            return code, attempt_log

    return None, attempt_log


def save_prolog(code: str, game_name: str) -> str:
    """Write *code* to <PROLOG_DIRECTORY>/<safe_game_name>.pl and return the path."""
    os.makedirs(config.PROLOG_DIRECTORY, exist_ok=True)
    safe_name = game_name.lower().replace(" ", "_")
    filepath = os.path.join(config.PROLOG_DIRECTORY, f"{safe_name}.pl")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(code)
    return filepath