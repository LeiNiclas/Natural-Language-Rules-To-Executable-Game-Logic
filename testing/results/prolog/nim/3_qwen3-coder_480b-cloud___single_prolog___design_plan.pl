:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Heaps, CurrentPlayer)
% Heaps = list of 3 integers representing counters in each heap
% CurrentPlayer = player1 | player2

initial_state(state([10, 6, 3], player1)).

current_player(state(_, P), P).

% Helper to check if a move is legal
is_legal_move(Heaps, Heap, Count) :-
    between(1, 3, Heap),
    nth1(Heap, Heaps, HeapCount),
    Count >= 1,
    Count =< HeapCount.

% Generate all legal moves
legal_move(state(Heaps, _), move(Heap, Count)) :-
    between(1, 3, Heap),
    nth1(Heap, Heaps, HeapCount),
    between(1, HeapCount, Count).

% Helper to update a heap
update_heap(Heaps, HeapIndex, CountToRemove, NewHeaps) :-
    nth1(HeapIndex, Heaps, OldCount, Rest),
    NewCount is OldCount - CountToRemove,
    nth1(HeapIndex, NewHeaps, NewCount, Rest).

% Helper to switch player
switch_player(player1, player2).
switch_player(player2, player1).

% Apply a legal move
apply_move(state(Heaps, CurrentPlayer), move(Heap, Count), state(NewHeaps, NextPlayer)) :-
    is_legal_move(Heaps, Heap, Count),
    update_heap(Heaps, Heap, Count, NewHeaps),
    switch_player(CurrentPlayer, NextPlayer).

% Check if game is over
is_game_over([0, 0, 0]).

% Game over when all heaps are empty
game_over(state([0, 0, 0], Player), Player).

% Render the current state
render_state(state(Heaps, Player)) :-
    format('Heaps: '),
    maplist(render_heap, Heaps),
    format('~nCurrent player: ~w~n', [Player]).

render_heap(Count) :-
    format('~w ', [Count]).