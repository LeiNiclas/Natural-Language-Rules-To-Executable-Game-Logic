:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

initial_state(state([10,6,3], player1)).
current_player(state(_, P), P).

legal_move(state(Heaps, Player), take(Player, pile(Heap), Count)) :-
    nth1(Heap, Heaps, HeapCount),
    numlist(1, HeapCount, Counts),
    member(Count, Counts).

apply_move(state(Heaps, Player), take(Player, pile(Heap), Count), state(NewHeaps, NextPlayer)) :-
    nth1(Heap, Heaps, OldCount),
    Count >= 1,
    OldCount >= Count,
    NewCount is OldCount - Count,
    set_nth1(Heap, Heaps, NewCount, NewHeaps),
    ( Player = player1 -> NextPlayer = player2 ; Player = player2 -> NextPlayer = player1 ).

game_over(state([0,0,0], player1), player2).
game_over(state([0,0,0], player2), player1).

% render_state prints the heaps and current player
render_state(state(Heaps, Player)) :-
    forall(nth1(I, Heaps, C),
           format('Heap ~w: ~w~n', [I, C])),
    format('Current player: ~w~n', [Player]).