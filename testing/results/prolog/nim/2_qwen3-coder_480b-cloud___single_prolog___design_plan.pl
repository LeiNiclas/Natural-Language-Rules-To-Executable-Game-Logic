:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Heaps, CurrentPlayer)
% Heaps = list of 3 integers representing counters in each heap
% CurrentPlayer = player1 | player2

initial_state(state([10, 6, 3], player1)).

current_player(state(_, P), P).

legal_move(state(Heaps, _), move(Heap, Count)) :-
    between(1, 3, Heap),
    nth1(Heap, Heaps, HeapCount),
    Count >= 1,
    Count =< HeapCount.

apply_move(state(Heaps, Player), move(Heap, Count), state(NewHeaps, NextPlayer)) :-
    legal_move(state(Heaps, Player), move(Heap, Count)),
    update_heap(Heaps, Heap, Count, NewHeaps),
    next_player(Player, NextPlayer).

update_heap(Heaps, HeapIndex, Count, NewHeaps) :-
    nth1(HeapIndex, Heaps, OldCount, RestHeaps),
    NewCount is OldCount - Count,
    nth1(HeapIndex, NewHeaps, NewCount, RestHeaps).

next_player(player1, player2).
next_player(player2, player1).

game_over(state([0, 0, 0], Player), Winner) :-
    next_player(Player, Winner).

render_state(state(Heaps, Player)) :-
    format("Heaps: ~w | Player: ~w~n", [Heaps, Player]).