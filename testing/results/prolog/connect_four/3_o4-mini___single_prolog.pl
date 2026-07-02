:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 6 rows, each a list of 7 atoms (empty, red, yellow); row 1 is top.
% Game state: state(Board, CurrentPlayer).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

other_player(red, yellow).
other_player(yellow, red).

initial_state(state([
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty]
], red)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

apply_move(state(Board, P), move(Column), state(NewBoard, Next)) :-
    findall(R, (nth1(R, Board, RowList), nth1(Column, RowList, empty)), Rs),
    last(Rs, Row),
    set_cell(Row, Column, Board, P, NewBoard),
    other_player(P, Next).

has_win(Board, Player) :-
    horizontal(Board, Player);
    vertical(Board, Player);
    diagonal_down(Board, Player);
    diagonal_up(Board, Player).

horizontal(Board, Player) :-
    between(1, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, RowList),
    C2 is Col + 1,
    C3 is Col + 2,
    C4 is Col + 3,
    nth1(Col, RowList, Player),
    nth1(C2, RowList, Player),
    nth1(C3, RowList, Player),
    nth1(C4, RowList, Player).

vertical(Board, Player) :-
    between(1, 3, Row),
    between(1, 7, Col),
    nth1(Row, Board, Row1),
    nth1(Col, Row1, Player),
    R2 is Row + 1,
    nth1(R2, Board, Row2),
    nth1(Col, Row2, Player),
    R3 is Row + 2,
    nth1(R3, Board, Row3),
    nth1(Col, Row3, Player),
    R4 is Row + 3,
    nth1(R4, Board, Row4),
    nth1(Col, Row4, Player).

diagonal_down(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    nth1(Row, Board, Row1),
    nth1(Col, Row1, Player),
    R2 is Row + 1, C2 is Col + 1,
    nth1(R2, Board, Row2),
    nth1(C2, Row2, Player),
    R3 is Row + 2, C3 is Col + 2,
    nth1(R3, Board, Row3),
    nth1(C3, Row3, Player),
    R4 is Row + 3, C4 is Col + 3,
    nth1(R4, Board, Row4),
    nth1(C4, Row4, Player).

diagonal_up(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, Row1),
    nth1(Col, Row1, Player),
    R2 is Row - 1, C2 is Col + 1,
    nth1(R2, Board, Row2),
    nth1(C2, Row2, Player),
    R3 is Row - 2, C3 is Col + 2,
    nth1(R3, Board, Row3),
    nth1(C3, Row3, Player),
    R4 is Row - 3, C4 is Col + 3,
    nth1(R4, Board, Row4),
    nth1(C4, Row4, Player).

game_over(state(Board, Current), Winner) :-
    other_player(Winner, Current),
    has_win(Board, Winner).
game_over(state(Board, _), draw) :-
    \+ has_win(Board, red),
    \+ has_win(Board, yellow),
    \+ (member(Row, Board), member(empty, Row)).

render_state(state(Board, _)) :-
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(Cell) :-
    (Cell = empty   -> format(".")
    ; Cell = red     -> format("R")
    ; Cell = yellow  -> format("Y")),
    format(" ").
