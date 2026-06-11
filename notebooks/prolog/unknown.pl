:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, Player)
% Board: list of atoms ([] = start, [_] = end with winner)
% Player: player1 or player2 (current player; only valid in non-terminal states)

initial_state(state([], player1)).

current_player(state([], P), P).

legal_move(state([], player1), end).

apply_move(state([], player1), end, state([player1], player1)).

game_over(state([W], _), W) :- W = player1 ; W = player2.

render_state(state([], P)) :- format("Game starting. Player ~w to move.~n", [P]).
render_state(state([W], _)) :- format("Game over. Winner: ~w.~n", [W]).

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, M, S2), render_state(S2).
% ?- initial_state(S), apply_move(S, M, S2), game_over(S2, W).