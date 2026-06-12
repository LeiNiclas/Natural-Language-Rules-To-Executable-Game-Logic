import config
import json
import os
import subprocess

from src.llm_client import chat
from tempfile import NamedTemporaryFile


# ================================================================
# Constraints & Restrictions
# ================================================================
SYSTEM_BASE = """\
You are an expert SWI-Prolog developer implementing a board or card game.

OUTPUT FORMAT:
- Pure SWI-Prolog code only. No markdown, no fenced blocks, no prose.
- Comments between clauses only, never inside a clause body.

SAFE IMPORTS ONLY: library(lists), library(apply). No other libraries.

PROLOG SEMANTICS - these mistakes cause silent failures:
  1. No return values. Predicates bind variables through unification.
     RIGHT: next_player(P, Next)    WRONG: Next = next_player(P)
  2. A variable is bound once. Never pre-unify before passing to a predicate.
     RIGHT: set_nth1(N, Board, V, New)    WRONG: New = Board, set_nth1(N, Board, V, New)
  3. Every variable in a clause head must be used in the body. Use _ if unused.
  4. Goals succeed or fail. They do not return values.
  5. Atoms start lowercase; variables start uppercase.
     x, o, empty, player1 are atoms. X, Board, Player are variables.
  6. Use explicit list literals to initialize boards, never maplist/length.
     RIGHT: Board = [empty,empty,empty,empty,empty,empty,empty,empty,empty]
     WRONG: length(Board, 9), maplist(=(empty), Board)
"""

SYSTEM_STAGE1 = SYSTEM_BASE + """
YOUR TASK - Stage 1 of 5:
Implement ONLY these predicates:
  1. Module imports: :- use_module(library(lists)). :- use_module(library(apply)).
  2. Helper predicates: set_nth1/4 and set_cell/5 if needed.
  3. initial_state(State)   - the fully ground starting state
  4. current_player(State, P) - P is the player to move

STATE REPRESENTATION:
  Flat list - for simple grids (Tic-Tac-Toe):
    Board = [empty,empty,...] explicit literal, exact length.
    Helper: set_nth1(1,[_|T],V,[V|T]). set_nth1(N,[H|T],V,[H|R]):-N>1,N1 is N-1,set_nth1(N1,T,V,R).

  2D list - for column/row games (Connect Four):
    Board = [[empty,...],[empty,...],...] explicit literal.
    Helper: set_cell + set_nth1 (include both verbatim).

  Other - card lists, counters: whatever is natural.

CRITICAL: initial_state must produce a fully ground term.
ground(State) must succeed after initial_state(State).
Do NOT use variables or maplist to initialize lists.

Output ONLY the Stage 1 predicates. Do not implement legal_move, apply_move, game_over, or render_state.
"""

SYSTEM_STAGE2 = SYSTEM_BASE + """
YOUR TASK - Stage 2 of 5:
You will receive existing Stage 1 code. Add ONLY:
  legal_move(State, Move)  - generative, backtracks over all legal moves

MOVE TERM DESIGN:
Move terms must be self-describing and human-readable.
A person reading the move term alone must understand what it does.
Choose the structure that best fits the game — there is no single correct format.

Examples from different game types:

  Chess / checkers (piece movement):
    move(pawn, e2, e4)          % piece + from + to
    move(knight, g1, f3)
    capture(bishop, c1, f4)
    castle(kingside)
    promote(pawn, e7, e8, queen)

  Tic-Tac-Toe / Gomoku (placement):
    place(x, 5)                 % mark + position
    place(o, row(2), col(3))    % mark + row + col

  Connect Four (column drop):
    drop(red, 4)                % piece + column

  Card games (play or draw):
    play(player1, ace_of_spades)
    draw(player2, deck)
    play_card(player1, seven, hearts)

  Nine Men's Morris (place / move / remove):
    place(white, 7)
    move(black, 3, 11)
    remove(white, 5)

  Nim (take stones):
    take(player1, pile(2), 3)   % player + pile + amount

WRONG in all cases:
  move(4, 13)                   % raw indices only — unreadable
  m(k, 28)                      % cryptic abbreviations
  move(e2, e4)                  % missing piece type for chess

Output the COMPLETE file so far: Stage 1 code + new legal_move clauses.
Do NOT implement apply_move, game_over, or render_state yet.
"""

SYSTEM_STAGE3 = SYSTEM_BASE + """
YOUR TASK - Stage 3 of 5:
You will receive existing Stage 1+2 code. Add ONLY:
  apply_move(State, Move, NewState) - NewState is State after Move; fail if illegal

CRITICAL for apply_move:
  - ALL changed fields must appear in NewState. Never leave fields unbound.
  - Never pre-unify: WRONG: NewState = State, set_nth1(...)
  - Use set_nth1 for flat lists, set_cell for 2D lists.
  - After apply_move, ground(NewState) must succeed.

WIN CONDITIONS hint: do not implement game_over here, but design apply_move
so the full state is always accessible for win-checking later.

Output the COMPLETE file so far: Stage 1+2 code + new apply_move clauses.
Do NOT implement game_over or render_state yet.
"""

SYSTEM_STAGE4 = SYSTEM_BASE + """
YOUR TASK - Stage 4 of 5:
You will receive existing Stage 1+2+3 code. Add ONLY:
  game_over(State, Winner) - Winner is a player atom or 'draw'; fail if game ongoing

WIN CONDITIONS:
  - Always check the winning value is not the empty atom.
    RIGHT: nth1(I, Board, P), P \\= empty
    WRONG: nth1(I, Board, P)
  - game_over should FAIL if the game is still ongoing.
  - Winner can be a player atom (player1, x, white...) or the atom 'draw'.

Output the COMPLETE file so far: Stage 1+2+3 code + new game_over clauses.
Do NOT implement render_state yet.
"""

SYSTEM_STAGE5 = SYSTEM_BASE + """
YOUR TASK - Stage 5 of 5:
You will receive existing Stage 1+2+3+4 code. Add ONLY:
  render_state(State) - print a human-readable board to stdout

RENDER RULES:
  - Print the empty atom as a visible placeholder: '.' or '_'
    RIGHT: (C = empty -> format('.') ; format('~w', [C]))
  - NEVER print the word 'empty'.
  - NEVER wrap atoms in a functor like symbol/1.
  - Use short abbreviations for players: p1/p2, w/b, r/y etc.

COORDINATE SYSTEM:
  Grid games (Chess, Checkers, Gomoku, Tic-Tac-Toe on a grid):
    - Show column labels top or bottom, row numbers left or right.
    - Each row on its own line.
    - Coordinates must match exactly what appears in the move terms.
    - Example:
        8 | r n b q k b n r
        7 | p p p p p p p p
        ...
        1 | R N B Q K B N R
            a b c d e f g h

  Flat list games (Tic-Tac-Toe with index, Nine Men's Morris):
    - Show position index next to each cell, each row on its own line.
    - Example:
        1:. 2:. 3:.
        4:. 5:x 6:.
        7:. 8:. 9:.

  Column games (Connect Four):
    - Show column numbers below the board.
    - Example:
        . . . . . . .
        . . . . . . .
        1 2 3 4 5 6 7

  Card / abstract games:
    - Show hand sizes, scores, current player clearly. No grid needed.

After the board, print on a new line:
  Current player: <player>
"""

FEW_SHOT_STAGE1 = """
REFERENCE - Stage 1 example (War card game):

:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(DeckP1, DeckP2, CurrentPlayer)
initial_state(state([c2,c4,c6,c8,c10], [c3,c5,c7,c9,jack], player1)).
current_player(state(_, _, P), P).
"""
# ================================================================

# ================================================================
# Internal functions
# ================================================================
def _make_runner(tmp: str):
    def run(goal: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["swipl", "-g", goal, "-t", "halt(1)", tmp],
            capture_output=True, text=True, timeout=config.SWIPL_TIMEOUT
        )
    return run


def _validate_stage(stage: int, code: str) -> tuple[bool, list[str]]:
    errors = []

    with NamedTemporaryFile(suffix=".pl", mode="w", delete=False, encoding="utf-8") as f:
        f.write(code)
        tmp = f.name

    run = _make_runner(tmp)

    # All stages: must load
    r = run("halt")
    if r.returncode != 0:
        errors.append(f"[Load error]\n{r.stderr.strip()}")
        os.unlink(tmp)
        return False, errors

    if stage >= 1:
        r = run("(initial_state(_) -> halt(0) ; halt(1))")
        if r.returncode != 0:
            errors.append("[initial_state/1] Did not succeed.")
            os.unlink(tmp)
            return False, errors

        r = run("(initial_state(S), ground(S) -> halt(0) ; halt(1))")
        if r.returncode != 0:
            errors.append(
                "[initial_state/1] State contains unbound variables. "
                "Use explicit list literals, not maplist/length."
            )
            os.unlink(tmp)
            return False, errors

    if stage >= 2:
        r = run("(initial_state(S), legal_move(S, _) -> halt(0) ; halt(1))")
        if r.returncode != 0:
            errors.append("[legal_move/2] No legal moves from initial state.")

    if stage >= 3:
        r = run("(initial_state(S), legal_move(S, M), apply_move(S, M, _) -> halt(0) ; halt(1))")
        if r.returncode != 0:
            errors.append("[apply_move/3] Failed on first legal move.")

        r = run("(initial_state(S), legal_move(S, M), apply_move(S, M, S2), ground(S2) -> halt(0) ; halt(1))")
        if r.returncode != 0:
            errors.append("[apply_move/3] NewState contains unbound variables.")

        multi = (
            "initial_state(S0), "
            "(legal_move(S0,M0)->apply_move(S0,M0,S1);S1=S0), "
            "(legal_move(S1,M1)->apply_move(S1,M1,S2);S2=S1), "
            "(legal_move(S2,M2)->apply_move(S2,M2,_);true), "
            "halt(0)"
        )
        r = run(multi)
        if r.returncode != 0:
            errors.append("[apply_move/3] Failed when chaining multiple moves.")

    if stage >= 4:
        r = run("(clause(game_over(_,_),_) -> halt(0) ; halt(1))")
        if r.returncode != 0:
            errors.append("[game_over/2] Predicate is not defined.")

    if stage >= 5:
        r = run("(initial_state(S), render_state(S), halt(0))")
        if r.returncode != 0:
            errors.append("[render_state/1] Crashed or failed on initial state.")
        else:
            if "_G" in r.stdout or "_A" in r.stdout:
                errors.append("[render_state/1] Output contains unbound variables.")

    os.unlink(tmp)
    return len(errors) == 0, errors


STAGE_SYSTEM_PROMPTS = {
    1: SYSTEM_STAGE1,
    2: SYSTEM_STAGE2,
    3: SYSTEM_STAGE3,
    4: SYSTEM_STAGE4,
    5: SYSTEM_STAGE5,
}

STAGE_NAMES = {
    1: "initial_state + current_player",
    2: "legal_move",
    3: "apply_move",
    4: "game_over",
    5: "render_state",
}


def _build_stage_prompt(
    stage: int,
    structured_json: dict,
    accumulated_code: str | None,
    design_plan: str | None,
    errors: list | None = None,
    broken_code: str | None = None,
) -> str:
    parts = []

    if design_plan:
        parts.append(f"Implementation plan:\n{design_plan}\n")

    parts.append(f"Game specification:\n{json.dumps(structured_json, indent=2)}\n")

    if accumulated_code:
        parts.append(f"Existing validated code (do not modify):\n{accumulated_code}\n")

    if errors and broken_code:
        error_block = "\n".join(f"  - {e}" for e in errors)
        parts.append(
            f"Your previous attempt for Stage {stage} failed with these errors:\n"
            f"{error_block}\n\n"
            f"Broken code from your previous attempt:\n{broken_code}\n\n"
            f"Fix all errors. Return the complete corrected file."
        )
    else:
        parts.append(
            f"Now implement Stage {stage}: {STAGE_NAMES[stage]}.\n"
            f"Return the complete file including all previous stages."
        )

    return "\n\n".join(parts)


def _strip_fences(code: str) -> str:
    if code.strip().startswith("```"):
        lines = code.strip().splitlines()
        return "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
    return code


def _generate_stage(
    stage: int,
    structured_json: dict,
    accumulated_code: str | None,
    design_plan: str | None,
) -> str | None:
    system = STAGE_SYSTEM_PROMPTS[stage]
    if stage == 1:
        system += "\n\n" + FEW_SHOT_STAGE1

    broken_code = None
    errors = None

    for attempt in range(1, config.PROLOG_MAX_RETRIES + 1):
        user_msg = _build_stage_prompt(
            stage, structured_json, accumulated_code, design_plan,
            errors=errors if attempt > 1 else None,
            broken_code=broken_code if attempt > 1 else None,
        )

        code = chat(
            config.BACKEND_PROLOG_GENERATOR,
            config.MODEL_PROLOG_GENERATOR,
            messages=[system, user_msg]
        )
        code = _strip_fences(code)

        valid, errors = _validate_stage(stage, code)

        if valid:
            return code

        broken_code = code

    return None
# ================================================================

# ================================================================
# Public endpoints
# ================================================================
def generate_prolog(structured_json: dict) -> tuple[str | None, str | None]:
    design_plan = None
    if config.PROLOG_USE_DESIGN_PLAN:
        from src.pipeline.prolog_generator import SYSTEM_DESIGN_PLANNER
        user_msg = (
            "Create an implementation plan for this game:\n\n"
            + json.dumps(structured_json, indent=2)
        )
        design_plan = chat(
            config.BACKEND_PROLOG_GENERATOR,
            config.MODEL_PROLOG_GENERATOR,
            messages=[SYSTEM_DESIGN_PLANNER, user_msg]
        )

    accumulated_code = None

    for stage in range(1, 6):
        result = _generate_stage(stage, structured_json, accumulated_code, design_plan)

        if result is None:
            return None, design_plan

        accumulated_code = result

    return accumulated_code, design_plan
# ================================================================
