:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Heaps, CurrentPlayer)
initial_state(state([10, 6, 3], player1)).
current_player(state(_, P), P).

% Legal moves in Nim: move(Heap, Count)
% Heap is 1-3, Count >= 1, Count <= current heap size
legal_move(state(Heaps, _), move(Heap, Count)) :-
    between(1, 3, Heap),
    nth1(Heap, Heaps, HeapCount),
    between(1, HeapCount, Count).

% Apply a move to a state, producing a new state
apply_move(state(Heaps, CurrentPlayer), move(Heap, Count), state(NewHeaps, NextPlayer)) :-
    legal_move(state(Heaps, CurrentPlayer), move(Heap, Count)),
    nth1(Heap, Heaps, OldCount),
    NewCount is OldCount - Count,
    set_nth1(Heap, Heaps, NewCount, NewHeaps),
    switch_player(CurrentPlayer, NextPlayer).

% Switch between players
switch_player(player1, player2).
switch_player(player2, player1).

% Game over conditions
game_over(state([0, 0, 0], Player), Player).

% Render the current state
render_state(state(Heaps, CurrentPlayer)) :-
    format('Heaps:~n'),
    forall(between(1, 3, I),
           (   nth1(I, Heaps, Count),
               format('  ~w: ~w~n', [I, Count])
           )),
    format('Current player: ~w~n', [CurrentPlayer]).