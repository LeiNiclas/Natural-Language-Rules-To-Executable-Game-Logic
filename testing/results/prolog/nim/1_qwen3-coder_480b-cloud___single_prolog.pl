:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Heaps, CurrentPlayer)
% Heaps = list of 3 integers (number of counters in each heap)
% CurrentPlayer = player1 | player2

initial_state(state([10, 6, 3], player1)).

current_player(state(_, P), P).

legal_move(state(Heaps, _), take(Heap, Count)) :-
    between(1, 3, Heap),
    nth1(Heap, Heaps, HeapCount),
    Count >= 1,
    Count =< HeapCount.

apply_move(state(Heaps, Player), take(Heap, Count), state(NewHeaps, NextPlayer)) :-
    nth1(Heap, Heaps, OldCount),
    Count >= 1,
    Count =< OldCount,
    NewCount is OldCount - Count,
    set_nth1(Heap, Heaps, NewCount, NewHeaps),
    (Player = player1 -> NextPlayer = player2 ; NextPlayer = player1).

set_nth1(1, [X|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

game_over(state([0,0,0], _), Winner) :-
    (Winner = player2 ; Winner = player1).

render_state(state(Heaps, Player)) :-
    format("Heaps: ~w | Current player: ~w~n", [Heaps, Player]).