:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

initial_state(state).

current_player(state, none).

legal_move(state, pass).

apply_move(state, pass, state).

game_over(_, _) :- fail.

render_state(state) :- format("Null Game: no state.~n").

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, M, S2).
% ?- initial_state(S), game_over(S, W).
% ?- initial_state(S), render_state(S).