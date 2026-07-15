:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper to set Nth element in a list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% Helper to set a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% State is state(Board, CurrentPlayer).
% Board: list of 6 rows (top to bottom), each row is list of 7 cells (left to right).
%       Each cell is one of the atoms empty, red, or yellow.
% CurrentPlayer: atom red or yellow indicating whose turn it is.

initial_state(state(
    [[empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty]],
    red)).

current_player(state(_, P), P).

legal_move(state(Board,_), move(Column)) :-
    column_valid(Column),
    top_empty(Board, Column).

apply_move(state(Board, Current), move(Column), state(NewBoard, Next)) :-
    column_valid(Column),
    top_empty(Board, Column),
    find_drop_row(Board, Column, Row),
    set_cell(Row, Column, Board, Current, NewBoard),
    switch_player(Current, Next).

game_over(state(Board,_), red) :-
    four_in_a_row(Board, red).
game_over(state(Board,_), yellow) :-
    four_in_a_row(Board, yellow).
game_over(state(Board,_), draw) :-
    board_full(Board),
    \+ four_in_a_row(Board, red),
    \+ four_in_a_row(Board, yellow).

render_state(state(Board,_)) :-
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(C) :-
    ( C = empty  -> format(". ")
    ; C = red    -> format("R ")
    ; C = yellow -> format("Y ")
    ).

% Valid column indices from 1 to 7
column_valid(Column) :-
    between(1, 7, Column).

% Column is not full if top cell is empty
top_empty(Board, Col) :-
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

% Find the lowest available row (highest index) in a column
find_drop_row(Board, Col, Row) :-
    find_drop_row(6, Board, Col, Row).

find_drop_row(Idx, Board, Col, Idx) :-
    Idx >= 1,
    nth1(Idx, Board, RowList),
    nth1(Col, RowList, empty), !.
find_drop_row(Idx, Board, Col, Row) :-
    Idx > 1,
    Idx1 is Idx - 1,
    find_drop_row(Idx1, Board, Col, Row).

% Switch turns between players
switch_player(red, yellow).
switch_player(yellow, red).

% Check for any four-in-a-row for Player
four_in_a_row(Board, Player) :-
    horizontal(Board, Player)
    ; vertical(Board, Player)
    ; diagonal_dr(Board, Player)
    ; diagonal_ur(Board, Player).

horizontal(Board, Player) :-
    between(1, 6, Row),
    nth1(Row, Board, RowList),
    between(1, 4, Col),
    nth1(Col, RowList, Player),
    C1 is Col+1, nth1(C1, RowList, Player),
    C2 is Col+2, nth1(C2, RowList, Player),
    C3 is Col+3, nth1(C3, RowList, Player).

vertical(Board, Player) :-
    between(1, 7, Col),
    between(1, 3, Row),
    nth1(Row, Board, R0), nth1(Col, R0, Player),
    R1 is Row+1, nth1(R1, Board, Rl1), nth1(Col, Rl1, Player),
    R2 is Row+2, nth1(R2, Board, Rl2), nth1(Col, Rl2, Player),
    R3 is Row+3, nth1(R3, Board, Rl3), nth1(Col, Rl3, Player).

diagonal_dr(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    nth1(Row, Board, R0), nth1(Col, R0, Player),
    R1 is Row+1, C1 is Col+1, nth1(R1, Board, Rl1), nth1(C1, Rl1, Player),
    R2 is Row+2, C2 is Col+2, nth1(R2, Board, Rl2), nth1(C2, Rl2, Player),
    R3 is Row+3, C3 is Col+3, nth1(R3, Board, Rl3), nth1(C3, Rl3, Player).

diagonal_ur(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, R0), nth1(Col, R0, Player),
    R1 is Row-1, C1 is Col+1, nth1(R1, Board, Rl1), nth1(C1, Rl1, Player),
    R2 is Row-2, C2 is Col+2, nth1(R2, Board, Rl2), nth1(C2, Rl2, Player),
    R3 is Row-3, C3 is Col+3, nth1(R3, Board, Rl3), nth1(C3, Rl3, Player).

% True if no cell is empty
board_full(Board) :-
    \+ ( member(Row, Board), member(empty, Row) ).