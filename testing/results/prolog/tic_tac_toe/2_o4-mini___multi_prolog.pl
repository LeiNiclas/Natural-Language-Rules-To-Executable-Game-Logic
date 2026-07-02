:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

current_player(state(_, P), P).

% legal_move(State, Move) - backtracks over all legal moves: placing the current player's mark on an empty square
legal_move(state(Board, Player), place(Player, Position)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty).

% apply_move(State, Move, NewState) - applies a legal move to produce NewState
apply_move(state(Board, Player), place(Player, Position), state(NewBoard, NextPlayer)) :-
    integer(Position), Position >= 1, Position =< 9,
    nth1(Position, Board, empty),
    set_nth1(Position, Board, Player, NewBoard),
    (Player = x -> NextPlayer = o ; NextPlayer = x).

% game_over(State, Winner) - succeeds if the game is over with Winner = x, o, or draw

game_over(state(Board,_), X) :-
    nth1(1, Board, X), X \= empty,
    nth1(2, Board, X),
    nth1(3, Board, X).

game_over(state(Board,_), X) :-
    nth1(4, Board, X), X \= empty,
    nth1(5, Board, X),
    nth1(6, Board, X).

game_over(state(Board,_), X) :-
    nth1(7, Board, X), X \= empty,
    nth1(8, Board, X),
    nth1(9, Board, X).

game_over(state(Board,_), X) :-
    nth1(1, Board, X), X \= empty,
    nth1(4, Board, X),
    nth1(7, Board, X).

game_over(state(Board,_), X) :-
    nth1(2, Board, X), X \= empty,
    nth1(5, Board, X),
    nth1(8, Board, X).

game_over(state(Board,_), X) :-
    nth1(3, Board, X), X \= empty,
    nth1(6, Board, X),
    nth1(9, Board, X).

game_over(state(Board,_), X) :-
    nth1(1, Board, X), X \= empty,
    nth1(5, Board, X),
    nth1(9, Board, X).

game_over(state(Board,_), X) :-
    nth1(3, Board, X), X \= empty,
    nth1(5, Board, X),
    nth1(7, Board, X).

% draw if no empty squares remain and no winner
game_over(state(Board,_), draw) :-
    \+ member(empty, Board).

% render_state(State) - print a human-readable board and current player
render_state(state(Board, Player)) :-
    print_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

% print_rows(Board, Start) - print rows of three cells each
print_rows(_, Start) :-
    Start > 9, !.
print_rows(Board, Start) :-
    End is Start + 2,
    print_row(Board, Start, End),
    Next is Start + 3,
    print_rows(Board, Next).

% print_row(Board, I, J) - prints cells I to J in one row
print_row(Board, I, J) :-
    print_cells(Board, I, J),
    nl.

% print_cells(Board, K, J) - helper to print indexed cells
print_cells(_, K, J) :-
    K > J, !.
print_cells(Board, K, J) :-
    nth1(K, Board, Cell),
    symbol_char(Cell, Symbol),
    format('~d:~w', [K, Symbol]),
    ( K < J -> write(' ') ; true ),
    K1 is K + 1,
    print_cells(Board, K1, J).

% symbol_char(Cell, Symbol) - map empty to '.', others as themselves
symbol_char(empty, '.') :- !.
symbol_char(X, X).
