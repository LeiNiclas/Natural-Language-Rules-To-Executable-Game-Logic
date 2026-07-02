:- use_module(library(lists)).

% state(Heaps, CurrentPlayer)
% Heaps = [H1,H2,H3], each integer ≥ 0, counters in each heap
initial_state(state([10,6,3], player1)).

current_player(state(_, P), P).

legal_move(state(Heaps, _), move(Heap, Count)) :-
    nth1(Heap, Heaps, HeapCount),
    HeapCount > 0,
    between(1, HeapCount, Count).

apply_move(state(Heaps, P), move(Heap, Count), state(NewHeaps, NextP)) :-
    nth1(Heap, Heaps, OldCount, RestHeaps),
    Count >= 1,
    Count =< OldCount,
    NewCount is OldCount - Count,
    nth1(Heap, NewHeaps, NewCount, RestHeaps),
    next_player(P, NextP).

next_player(player1, player2).
next_player(player2, player1).

game_over(state([0,0,0], P), Winner) :-
    next_player(P, Winner).

render_state(state([H1,H2,H3], P)) :-
    (P = player1 -> format('P1') ; format('P2')),
    format(' | Heaps: ~d ~d ~d~n', [H1,H2,H3]).