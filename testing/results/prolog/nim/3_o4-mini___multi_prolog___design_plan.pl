:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(+Index, +List, +Value, -NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% initial_state(-State)
initial_state(state([10,6,3], player1)).

% current_player(+State, -Player)
current_player(state(_, P), P).

% legal_move(+State, -Move)
% Generate all legal moves: remove Count counters (≥1) from heap at index HeapIndex
legal_move(state(Heaps, _), move(HeapIndex, Count)) :-
    nth1(HeapIndex, Heaps, HeapCount),
    HeapCount > 0,
    between(1, HeapCount, Count).

% apply_move(+State, +Move, -NewState)
% Remove Count counters from heap at Index and switch player; fail if illegal
apply_move(state(Heaps, player1), move(Index, Count), state(NewHeaps, player2)) :-
    nth1(Index, Heaps, HeapCount),
    Count >= 1,
    Count =< HeapCount,
    NewCount is HeapCount - Count,
    set_nth1(Index, Heaps, NewCount, NewHeaps).
apply_move(state(Heaps, player2), move(Index, Count), state(NewHeaps, player1)) :-
    nth1(Index, Heaps, HeapCount),
    Count >= 1,
    Count =< HeapCount,
    NewCount is HeapCount - Count,
    set_nth1(Index, Heaps, NewCount, NewHeaps).

% game_over(+State, -Winner)
% True when all heaps are empty; Winner is the player who made the last move
game_over(state([0,0,0], player1), player2).
game_over(state([0,0,0], player2), player1).

% render_state(+State)
% Print heap sizes and current player
render_state(state(Heaps, Player)) :-
    format('Heaps: '),
    print_heaps(Heaps, 1),
    format('~nCurrent player: ~w~n', [Player]).

% print_heaps(+Heaps, +Index)
% Helper to print each heap as Index:Value
print_heaps([], _) :- !.
print_heaps([H|T], I) :-
    format('~w:~w', [I, H]),
    ( T \= [] -> format(' ') ; true ),
    I1 is I + 1,
    print_heaps(T, I1).