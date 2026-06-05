import config
import json
import os
import subprocess

from llm_client import chat
from tempfile import NamedTemporaryFile


# ================================================================
# Constraints & Restrictions
# ================================================================
SYSTEM_PROLOG_GENERATOR = """\
You are an expert SWI-Prolog developer. You implement games in SWI-Prolog from structured JSON.

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
  Choose the representation that best fits the game. Document your choice in a comment.

  Flat list - use for simple grids (Tic-Tac-Toe, Othello):
    Board = [empty, empty, ...] of length rows*cols.
    Read:  nth1(Index, Board, Value)
    Write: set_nth1(Index, Board, Value, NewBoard)
    Index from row/col: Index is (Row-1)*NumCols + Col.
    Helper (include verbatim if used):
      set_nth1(1, [_|T], V, [V|T]).
      set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

  2D list - use when rows are natural units (Connect Four, Checkers):
    Board = [[empty,...], [empty,...], ...] one sublist per row, top to bottom.
    Read:  nth1(Row, Board, RowList), nth1(Col, RowList, Value)
    Write: ALWAYS use this exact helper, include it verbatim:
      set_cell(Row, Col, Board, Value, NewBoard) :-
          nth1(Row, Board, OldRow),
          set_nth1(Col, OldRow, Value, NewRow),
          set_nth1(Row, Board, NewRow, NewBoard).
      set_nth1(1, [_|T], V, [V|T]).
      set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).
    NEVER use set_nth1 directly on a 2D board - always go through set_cell.

  Other - card lists, pile counts, etc. Choose whatever is natural.

WIN CONDITIONS:
  - Always check that the winning value is not the neutral/empty atom.
    RIGHT: nth1(I, Board, P), P \= empty
    WRONG: nth1(I, Board, P)

RENDER STATE:
  - Print the neutral/empty atom as a visible placeholder, e.g. '.' or '_'.
    RIGHT: (C = empty -> format('.') ; format('~w', [C]))
  - NEVER print the word 'empty' on the board.
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
% DeckP1, DeckP2 = lists of card atoms
% CurrentPlayer  = player1 | player2

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

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, play(player1,c2), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).

% --- KEY PATTERNS for grid/board games (not used in War, shown for reference) ---
% Win-line check - use nth1 directly, never write row/col extractor predicates:
%   check_line(Board, I1, I2, I3, Player) :-
%       nth1(I1, Board, Player), nth1(I2, Board, Player), nth1(I3, Board, Player),
%       Player \\= empty.
% Draw - board is full:
%   \\+ member(empty, Board)
"""
# ================================================================

# ================================================================
# Internal functions
# ================================================================
def _build_prolog_prompt(structured_json : dict) -> str:
    return (
        "Implement the following game in SWI-Prolog. "
        + "Follow every rule in the system prompt exactly.\n\n"
        + json.dumps(structured_json, indent=2)
    )

def _build_prolog_fix_prompt(structured_json : dict, broken_code : str, errors: list) -> str:
    error_block  = "\n".join(f"  - {e}" for e in errors)
    
    return (
        "The Prolog file you generated failed validation with these errors:\n"
        + error_block + "\n\n"
        + "Here is the broken code:\n" + broken_code + "\n\n"
        + "Fix all errors and return the complete corrected file. "
        + "Follow every rule in the system prompt exactly.\n\n"
        + "Game spec for reference:\n"
        + json.dumps(structured_json, indent=2)
    )

def _validate_prolog(prolog_code : str) -> tuple[bool, list[str]]:
    errors = []
    
    with NamedTemporaryFile(suffix=".pl", mode="w", delete=False, encoding="utf-8") as f:
        f.write(prolog_code)
        tmp = f.name
    
    def run(goal : str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["swipl", "-g", goal, "-t", "halt(1)", tmp],
            capture_output=True, text=True, timeout=config.SWIPL_TIMEOUT
        )
    
    # Check 1: Load
    r = run("halt")
    
    if r.returncode != 0:
        errors.append(f"[Load error]\n{r.stderr.strip()}")
        os.unlink(tmp)
        return False, errors
    
    # Check 2: initial_state/1
    r = run("(initial_state(_) -> halt(0) ; halt(1))")
    
    if r.returncode != 0:
        errors.append("[initial_state/1] Did not succeed.")
    
    # Check 3: legal_move/2
    r = run("(initial_state(S), legal_move(S, _) -> halt(0) ; halt(1))")
    
    if r.returncode != 0:
        errors.append("[legal_move/2] No legal moves from initial state.")
    
    # Check 4: apply_move/3
    r = run("(initial_state(S), legal_move(S, M), apply_move(S, M, _) -> halt(0) ; halt(1))")
    
    if r.returncode != 0:
        errors.append("[apply_move/3] Failed on first legal move from initial state.")
    
    os.unlink(tmp)
    return len(errors) == 0, errors
# ================================================================

# ================================================================
# Public endpoints
# ================================================================
def generate_prolog(structured_json : dict) -> str:
    system_msg = SYSTEM_PROLOG_GENERATOR + "\n\n" + FEW_SHOT_PROLOG
    code = None
    errors = None
    
    for attempt in range(1, config.PROLOG_MAX_RETRIES + 1):
        if attempt == 1:
            user_msg = _build_prolog_prompt(structured_json)
        else:
            user_msg = _build_prolog_fix_prompt(structured_json, code, errors)
        
        code = chat(config.BACKEND_PROLOG_GENERATOR, config.MODEL_PROLOG_GENERATOR, messages=[system_msg, user_msg])
        
        if code.strip().startswith("```"):
            lines = code.strip().splitlines()
            code = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
        
        valid, errors = _validate_prolog(code)
        
        if valid:
            return code
        else:
            if attempt == config.PROLOG_MAX_RETRIES:
                return None


def save_prolog(code : str, game_name : str) -> str:
    os.makedirs(config.PROLOG_DIRECTORY, exist_ok=True)
    safe_name = game_name.lower().replace(" ", "_")
    filepath = os.path.join(config.PROLOG_DIRECTORY, f"{safe_name}.pl")
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(code)
    
    return filepath
# ================================================================
