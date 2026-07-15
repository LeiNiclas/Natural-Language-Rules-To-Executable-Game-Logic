:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% initial state: heaps [10,6,3], player1 to move
initial_state(state([10,6,3], player1)).

% current player is the player to move in the state
current_player(state(_, P), P).

% legal_move(State, Move) generative over all legal moves
legal_move(state(Heaps, _), move(HeapIndex, Count)) :-
    between(1, 3, HeapIndex),
    nth1(HeapIndex, Heaps, HeapCount),
    between(1, HeapCount, Count).

% other_player relates each player to their opponent
other_player(player1, player2).
other_player(player2, player1).

% apply_move(State, Move, NewState) - apply legal move, update heaps and switch player
apply_move(state(Heaps, Player), move(HeapIndex, Count), state(NewHeaps, OtherPlayer)) :-
    legal_move(state(Heaps, Player), move(HeapIndex, Count)),
    nth1(HeapIndex, Heaps, OldCount),
    NewCount is OldCount - Count,
    set_nth1(HeapIndex, Heaps, NewCount, NewHeaps),
    other_player(Player, OtherPlayer).

% all_zero succeeds if every heap has zero counters
all_zero([]).
all_zero([H|T]) :-
    H = 0,
    all_zero(T).

% game_over(State, Winner) succeeds when heaps all zero, Winner is player who made last move
game_over(state(Heaps, CurrentPlayer), Winner) :-
    all_zero(Heaps),
    other_player(CurrentPlayer, Winner).

% render_state prints a human-readable representation of the game state
render_state(state([H1,H2,H3], Player)) :-
    format('1:~w 2:~w 3:~w~n', [H1,H2,H3]),
    ( Player = player1 ->
        format('Current player: p1~n', [])
    ;
        format('Current player: p2~n', [])
    ).