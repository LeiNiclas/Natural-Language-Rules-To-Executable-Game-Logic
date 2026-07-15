:- use_module(library(lists)).

% State representation: state(Heaps, CurrentPlayer)
% Heaps is list of three non-negative integers; CurrentPlayer is player1 or player2.

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

initial_state(state([10,6,3], player1)).

current_player(state(_, P), P).

valid_heap_index(Index) :-
    between(1, 3, Index).

heap_count(Heaps, Index, Count) :-
    nth1(Index, Heaps, Count).

update_heap(Heaps, Index, NewCount, NewHeaps) :-
    set_nth1(Index, Heaps, NewCount, NewHeaps).

legal_move(state(Heaps, _), move(Index, Count)) :-
    valid_heap_index(Index),
    heap_count(Heaps, Index, HCount),
    HCount > 0,
    between(1, HCount, Count).

other_player(player1, player2).
other_player(player2, player1).

apply_move(state(Heaps, P), move(Index, Count), state(NewHeaps, NextP)) :-
    valid_heap_index(Index),
    heap_count(Heaps, Index, HCount),
    Count >= 1,
    Count =< HCount,
    NewCount is HCount - Count,
    update_heap(Heaps, Index, NewCount, NewHeaps),
    other_player(P, NextP).

game_over(state([0,0,0], P), Winner) :-
    other_player(P, Winner).

render_state(state(Heaps, P)) :-
    ( P = player1 -> format("Player: P1~n") ; format("Player: P2~n") ),
    nth1(1, Heaps, H1),
    nth1(2, Heaps, H2),
    nth1(3, Heaps, H3),
    format("Heaps: ~w ~w ~w~n", [H1, H2, H3]).