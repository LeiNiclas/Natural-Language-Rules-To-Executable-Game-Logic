:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Heaps, CurrentPlayer)
% Heaps = list of 3 integers, each >= 0, number of counters in heap i (1-3)
% CurrentPlayer = player1 | player2

initial_state(state([10, 6, 3], player1)).

current_player(state(_, P), P).

% Helper to check if heap index is valid
valid_heap_index(Heap) :-
    between(1, 3, Heap).

% Helper to get heap count
get_heap_count(Heaps, HeapIndex, Count) :-
    nth1(HeapIndex, Heaps, Count).

% Helper to update heap count
update_heap(Heaps, HeapIndex, NewCount, NewHeaps) :-
    nth1(HeapIndex, Heaps, _, Temp),
    nth1(HeapIndex, NewHeaps, NewCount, Temp).

% Legal move: move(Heap, Count)
% Heap must be between 1 and 3
% Count must be >= 1 and =< heap count
legal_move(state(Heaps, _), move(Heap, Count)) :-
    valid_heap_index(Heap),
    get_heap_count(Heaps, Heap, HeapCount),
    between(1, HeapCount, Count).

% Apply move: reduce the count in specified heap
apply_move(state(Heaps, Player), move(Heap, Count), state(NewHeaps, NextPlayer)) :-
    get_heap_count(Heaps, Heap, OldCount),
    Count =< OldCount,
    NewCount is OldCount - Count,
    update_heap(Heaps, Heap, NewCount, NewHeaps),
    (Player = player1 -> NextPlayer = player2 ; NextPlayer = player1).

% Game over when all heaps are zero
game_over(state([0, 0, 0], Winner), Winner).

% Render state: show heaps and current player
render_state(state(Heaps, Player)) :-
    format('Heaps: ~w | Player: ~w~n', [Heaps, Player]).