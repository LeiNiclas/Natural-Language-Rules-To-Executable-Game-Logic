:- use_module(library(lists)).

% state(Heaps, CurrentPlayer)
% Heaps = [H1,H2,H3] counts of counters in each of the three heaps
initial_state(state([10,6,3], player1)).

current_player(state(_, P), P).

legal_move(state(Heaps, _), move(Heap, Count)) :-
    nth1(Heap, Heaps, HeapCount),
    HeapCount > 0,
    between(1, HeapCount, Count).

apply_move(state(Heaps, Player), move(Heap, Count), state(NewHeaps, NextPlayer)) :-
    nth1(Heap, Heaps, OldCount, RestHeaps),
    OldCount >= Count,
    NewCount is OldCount - Count,
    nth1(Heap, NewHeaps, NewCount, RestHeaps),
    next_player(Player, NextPlayer).

% alternate players
next_player(player1, player2).
next_player(player2, player1).

% game over when all heaps empty; winner is the one who moved last
game_over(state([0,0,0], Current), Winner) :-
    next_player(Current, Winner).

render_state(state([H1,H2,H3], _)) :-
    format("~w ~w ~w~n", [H1, H2, H3]).