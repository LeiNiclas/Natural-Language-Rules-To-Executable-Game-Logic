:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% initial_state(State) - starting heaps and player
initial_state(state([10,6,3], player1)).

% current_player(State, Player) - whose turn it is
current_player(state(_, P), P).

% legal_move(State, Move) - backtracks over all legal Nim moves: remove Count counters from heap HeapIndex
legal_move(state(Heaps, _), move(HeapIndex, Count)) :-
    nth1(HeapIndex, Heaps, HeapCount),
    HeapCount > 0,
    between(1, HeapCount, Count).

% apply_move(State, Move, NewState) - NewState is state after Move; fail if illegal
apply_move(state(Heaps, CurrentPlayer), move(Index, Count), state(NewHeaps, NextPlayer)) :-
    legal_move(state(Heaps, CurrentPlayer), move(Index, Count)),
    nth1(Index, Heaps, OldCount),
    NewCount is OldCount - Count,
    set_nth1(Index, Heaps, NewCount, NewHeaps),
    switch_player(CurrentPlayer, NextPlayer).

% switch_player(Current, Next)
switch_player(player1, player2).
switch_player(player2, player1).

% all_zero(Heaps) - succeeds when every heap count is zero
all_zero([]).
all_zero([0|T]) :-
    all_zero(T).

% game_over(State, Winner) - Winner is the player who made the last move; fail if game ongoing
game_over(state(Heaps, CurrentPlayer), Winner) :-
    all_zero(Heaps),
    switch_player(Winner, CurrentPlayer).

% render_state(State) - print a human-readable Nim heaps state
render_state(state(Heaps, CurrentPlayer)) :-
    Heaps = [H1,H2,H3],
    format('Heap 1: ~w~n', [H1]),
    format('Heap 2: ~w~n', [H2]),
    format('Heap 3: ~w~n', [H3]),
    abbreviate_player(CurrentPlayer, Abbrev),
    format('Current player: ~w~n', [Abbrev]).

% abbreviate_player(Current, Abbrev) - map full player name to short form
abbreviate_player(player1, p1).
abbreviate_player(player2, p2).