:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N - 1, set_nth1(N1, T, V, R).

initial_state(state([10,6,3], player1)).
current_player(state(_, P), P).

between(Low, High, Low) :- Low =< High.
between(Low, High, N) :-
    Low < High,
    Next is Low + 1,
    between(Next, High, N).

legal_move(State, take(Player, heap(Heap), Count)) :-
    current_player(State, Player),
    State = state(Heaps, _),
    nth1(Heap, Heaps, HeapCount),
    between(1, HeapCount, Count).

apply_move(State, take(Player, heap(Heap), Count), state(NewHeaps, Next)) :-
    legal_move(State, take(Player, heap(Heap), Count)),
    State = state(Heaps, Player),
    nth1(Heap, Heaps, OldCount, RestHeaps),
    NewCount is OldCount - Count,
    nth1(Heap, NewHeaps, NewCount, RestHeaps),
    ( Player = player1 -> Next = player2
    ; Player = player2 -> Next = player1 ).

other(player1, player2).
other(player2, player1).

game_over(state([0,0,0], Current), Winner) :-
    other(Current, Winner).

% render_state(State) prints heaps and current player
render_state(State) :-
    State = state(Heaps, Player),
    print_heaps(Heaps),
    player_abbr(Player, Abbr),
    format('Current player: ~w~n', [Abbr]).

% print_heaps(Heaps) prints each heap index and count on one line
print_heaps(Heaps) :-
    print_heaps(Heaps, 1).

print_heaps([], _) :-
    nl.
print_heaps([H|T], I) :-
    format('~w:~w', [I, H]),
    ( T = [] -> nl ; format(' ', []) ),
    I1 is I + 1,
    print_heaps(T, I1).

% player_abbr(Player, Abbr) maps full player atom to abbreviation
player_abbr(player1, p1).
player_abbr(player2, p2).