:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Heaps, CurrentPlayer)
initial_state(state([10, 6, 3], player1)).
current_player(state(_, P), P).

% legal_move(State, Move)
% Move = move(Heap, Count) where Heap is 1-3 and Count >= 1
legal_move(state(Heaps, _), move(Heap, Count)) :-
    between(1, 3, Heap),
    nth1(Heap, Heaps, HeapCount),
    between(1, HeapCount, Count).

% apply_move(State, Move, NewState)
% NewState is State after applying Move
apply_move(state(Heaps, player1), move(Heap, Count), state(NewHeaps, player2)) :-
    nth1(Heap, Heaps, OldCount),
    OldCount >= Count,
    NewCount is OldCount - Count,
    set_nth1(Heap, Heaps, NewCount, NewHeaps).

apply_move(state(Heaps, player2), move(Heap, Count), state(NewHeaps, player1)) :-
    nth1(Heap, Heaps, OldCount),
    OldCount >= Count,
    NewCount is OldCount - Count,
    set_nth1(Heap, Heaps, NewCount, NewHeaps).

% game_over(State, Winner)
% Winner is either a player atom or 'draw'
% Fails if game is not over yet
game_over(state([0, 0, 0], player1), player2).
game_over(state([0, 0, 0], player2), player1).

% render_state(State)
% Prints a human-readable representation of the game state
render_state(state(Heaps, CurrentPlayer)) :-
    write('Heaps:'), nl,
    forall(between(1, 3, I),
           (nth1(I, Heaps, Count),
            format('  ~w: ~w~n', [I, Count]))),
    format('Current player: ~w~n', [CurrentPlayer]).