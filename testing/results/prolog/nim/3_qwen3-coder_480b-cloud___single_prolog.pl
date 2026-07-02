:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Heaps, CurrentPlayer)
% Heaps = list of 3 integers, each >= 0
% CurrentPlayer = player1 | player2

initial_state(state([10, 6, 3], player1)).

current_player(state(_, P), P).

legal_move(state(Heaps, _), take(Heap, Count)) :-
    between(1, 3, Heap),
    nth1(Heap, Heaps, HeapCount),
    Count >= 1,
    Count =< HeapCount.

% Helper to replace an element at a given position in a list
replace_nth1(1, [_|T], V, [V|T]).
replace_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, replace_nth1(N1, T, V, R).

apply_move(state(Heaps, Player), take(Heap, Count), state(NewHeaps, NextPlayer)) :-
    nth1(Heap, Heaps, OldCount),
    OldCount >= Count,
    NewCount is OldCount - Count,
    replace_nth1(Heap, Heaps, NewCount, NewHeaps),
    next_player(Player, NextPlayer).

next_player(player1, player2).
next_player(player2, player1).

game_over(state([0, 0, 0], _), Winner) :-
    (Winner = player1 ; Winner = player2).

render_state(state(Heaps, Player)) :-
    format("Heaps: ~w | Player: ~w~n", [Heaps, Player]).