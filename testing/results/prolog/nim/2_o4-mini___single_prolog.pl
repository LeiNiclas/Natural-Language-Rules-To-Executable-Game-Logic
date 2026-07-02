:- use_module(library(lists)).

% State representation: state(Heaps, Player)
% Heaps is list of 3 non-negative integers. Player is player1 or player2.

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% between(Low, High, X) succeeds for X in Low..High
between(Low, High, Low) :-
    Low =< High.
between(Low, High, X) :-
    Low < High,
    L1 is Low + 1,
    between(L1, High, X).

initial_state(state([10,6,3], player1)).

current_player(state(_, P), P).

legal_move(state(Heaps, _), move(Heap, Count)) :-
    nth1(Heap, Heaps, OldCount),
    OldCount > 0,
    between(1, OldCount, Count).

apply_move(state(Heaps, P), move(Heap, Count), state(NewHeaps, NextP)) :-
    nth1(Heap, Heaps, OldCount),
    Count >= 1,
    Count =< OldCount,
    NewCount is OldCount - Count,
    set_nth1(Heap, Heaps, NewCount, NewHeaps),
    next_player(P, NextP).

game_over(state([0,0,0], P), Winner) :-
    next_player(P, Winner).

render_state(state([H1,H2,H3], _)) :-
    format("~w ~w ~w~n", [H1, H2, H3]).

next_player(player1, player2).
next_player(player2, player1).