:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

current_player(state(_, P), P).

legal_move(state(Board, Player), place(Player, Position)) :-
    nth1(Position, Board, empty).

apply_move(state(Board, Player), place(Player, Position), state(NewBoard, NextPlayer)) :-
    integer(Position), Position >= 1, Position =< 9,
    nth1(Position, Board, empty),
    set_nth1(Position, Board, Player, NewBoard),
    ( Player == x -> NextPlayer = o ; NextPlayer = x ).

winner(Board, X) :- nth1(1,Board,X), nth1(2,Board,X), nth1(3,Board,X), X \= empty.
winner(Board, X) :- nth1(4,Board,X), nth1(5,Board,X), nth1(6,Board,X), X \= empty.
winner(Board, X) :- nth1(7,Board,X), nth1(8,Board,X), nth1(9,Board,X), X \= empty.
winner(Board, X) :- nth1(1,Board,X), nth1(4,Board,X), nth1(7,Board,X), X \= empty.
winner(Board, X) :- nth1(2,Board,X), nth1(5,Board,X), nth1(8,Board,X), X \= empty.
winner(Board, X) :- nth1(3,Board,X), nth1(6,Board,X), nth1(9,Board,X), X \= empty.
winner(Board, X) :- nth1(1,Board,X), nth1(5,Board,X), nth1(9,Board,X), X \= empty.
winner(Board, X) :- nth1(3,Board,X), nth1(5,Board,X), nth1(7,Board,X), X \= empty.

game_over(state(Board,_), X) :- winner(Board, X).
game_over(state(Board,_), draw) :- \+ winner(Board,_), \+ member(empty,Board).

% render_state prints the board with indices and the current player
render_state(state(Board, Player)) :-
    render_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

cell_symbol(empty, '.').
cell_symbol(X, X) :- X \= empty.

render_rows(_, Start) :- Start > 9, !.
render_rows(Board, Start) :-
    I2 is Start + 1,
    I3 is Start + 2,
    nth1(Start,  Board, C1),
    nth1(I2,     Board, C2),
    nth1(I3,     Board, C3),
    cell_symbol(C1, S1),
    cell_symbol(C2, S2),
    cell_symbol(C3, S3),
    format('~w:~w ~w:~w ~w:~w~n', [Start, S1, I2, S2, I3, S3]),
    Next is Start + 3,
    render_rows(Board, Next).