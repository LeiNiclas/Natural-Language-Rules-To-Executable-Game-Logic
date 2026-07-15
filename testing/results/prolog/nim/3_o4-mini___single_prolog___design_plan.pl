:- use_module(library(lists)).
:- use_module(library(apply)).

% State representation: state(Heaps, CurrentPlayer)
% Heaps is a list [H1,H2,H3] of non-negative integers.
% CurrentPlayer is player1 or player2.

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% update_heap(Heaps, Index, NewCount, NewHeaps)
update_heap(Heaps, Index, NewCount, NewHeaps) :-
    set_nth1(Index, Heaps, NewCount, NewHeaps).

% heap_count(Heaps, Index, Count)
heap_count(Heaps, Index, Count) :-
    nth1(Index, Heaps, Count).

% switch_player(Current, Next)
switch_player(player1, player2).
switch_player(player2, player1).

% all_heaps_empty(Heaps)
all_heaps_empty(Heaps) :-
    maplist(==(0), Heaps).

% valid_index(Index)
valid_index(Index) :-
    between(1, 3, Index).

initial_state(state([10, 6, 3], player1)).

current_player(state(_, Player), Player).

legal_move(state(Heaps, _), move(Index, Count)) :-
    valid_index(Index),
    heap_count(Heaps, Index, HeapCount),
    between(1, HeapCount, Count).

apply_move(state(Heaps, Player), move(Index, Count), state(NewHeaps, NextPlayer)) :-
    valid_index(Index),
    heap_count(Heaps, Index, OldCount),
    Count >= 1,
    Count =< OldCount,
    NewCount is OldCount - Count,
    update_heap(Heaps, Index, NewCount, NewHeaps),
    switch_player(Player, NextPlayer).

game_over(state(Heaps, CurrentPlayer), Winner) :-
    all_heaps_empty(Heaps),
    switch_player(CurrentPlayer, Winner).

render_state(state(Heaps, Player)) :-
    nth1(1, Heaps, H1),
    nth1(2, Heaps, H2),
    nth1(3, Heaps, H3),
    format("Heaps: ~d ~d ~d~n", [H1, H2, H3]),
    (Player = player1 ->
        format("P1 to move~n")
    ;
        format("P2 to move~n")
    ).