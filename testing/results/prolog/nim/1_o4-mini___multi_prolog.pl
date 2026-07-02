:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

initial_state(state([10,6,3], player1)).
current_player(state(_, P), P).

legal_move(state(Heaps, Player), take(Player, pile(HeapIndex), Count)) :-
    nth1(HeapIndex, Heaps, HeapCount),
    HeapCount > 0,
    between(1, HeapCount, Count).

next_player(player1, player2).
next_player(player2, player1).

apply_move(state(Heaps, Player), take(Player, pile(Index), Count), state(NewHeaps, NextPlayer)) :-
    nth1(Index, Heaps, OldCount),
    Count >= 1,
    Count =< OldCount,
    NewCount is OldCount - Count,
    set_nth1(Index, Heaps, NewCount, NewHeaps),
    next_player(Player, NextPlayer).

game_over(state([0,0,0], NextPlayer), Winner) :-
    next_player(Winner, NextPlayer).

% render_state prints the heap sizes and current player
render_state(state(Heaps, Player)) :-
    print_heaps(1, Heaps),
    format('Current player: ~w\n', [Player]).

% print_heaps(Index, Heaps) prints each heap with its index
print_heaps(_, []).
print_heaps(Index, [H|T]) :-
    format('Heap ~w: ~w\n', [Index, H]),
    NextIndex is Index + 1,
    print_heaps(NextIndex, T).