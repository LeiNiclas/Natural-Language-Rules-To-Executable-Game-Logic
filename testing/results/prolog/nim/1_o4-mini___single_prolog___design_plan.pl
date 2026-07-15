:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper: set_nth1 for flat list updates
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% valid_heap_index(Index) succeeds if Index is 1,2, or 3
valid_heap_index(1).
valid_heap_index(2).
valid_heap_index(3).

% heap_count(Heaps, Index, Count) retrieves the Count at position Index
heap_count(Heaps, Index, Count) :-
    nth1(Index, Heaps, Count).

% update_heap(Heaps, Index, NewCount, NewHeaps) replaces element at Index
update_heap(Heaps, Index, NewCount, NewHeaps) :-
    set_nth1(Index, Heaps, NewCount, NewHeaps).

% other_player(Current, Other) alternates players
other_player(player1, player2).
other_player(player2, player1).

% all_zero(Heaps) succeeds if every element of Heaps is zero
all_zero(Heaps) :-
    \+ ( member(X, Heaps), X \= 0 ).

% initial_state(State) one solution; starting state
initial_state(state([10,6,3], player1)).

% current_player(State, P) P to move in State
current_player(state(_, P), P).

% legal_move(State, Move) generates all legal moves
legal_move(state(Heaps, _), move(Index, Count)) :-
    valid_heap_index(Index),
    heap_count(Heaps, Index, Max),
    Max > 0,
    between(1, Max, Count).

% apply_move(State, Move, NewState) applies Move; fails if illegal
apply_move(state(Heaps, Player), move(Index, Count), state(NewHeaps, Next)) :-
    heap_count(Heaps, Index, OldCount),
    Count >= 1,
    Count =< OldCount,
    NewCount is OldCount - Count,
    update_heap(Heaps, Index, NewCount, NewHeaps),
    other_player(Player, Next).

% game_over(State, Winner) succeeds if all heaps zero; Winner made last move
game_over(state(Heaps, Player), Winner) :-
    all_zero(Heaps),
    other_player(Player, Winner).

% render_state(State) prints a human-readable representation
render_state(state([H1,H2,H3], Player)) :-
    format("Heaps: ~w ~w ~w~n", [H1, H2, H3]),
    ( Player = player1 -> Abbrev = "P1" ; Abbrev = "P2" ),
    format("Player: ~s~n", [Abbrev]).