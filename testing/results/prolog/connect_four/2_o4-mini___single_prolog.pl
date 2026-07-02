% Board is a 6x7 list of lists, each cell empty|red|yellow. state(Board, CurrentPlayer).
:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state([
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty]
], red)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Col)) :-
    between(1, 7, Col),
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

apply_move(state(Board, Player), move(Col), state(NewBoard, Next)) :-
    find_drop_row(Board, Col, Row),
    set_cell(Row, Col, Board, Player, TempBoard),
    next_player(Player, Next),
    NewBoard = TempBoard.

find_drop_row(Board, Col, Row) :-
    find_drop_row(6, Board, Col, Row).

find_drop_row(R, Board, Col, R) :-
    nth1(R, Board, RowList),
    nth1(Col, RowList, empty), !.
find_drop_row(R, Board, Col, Row) :-
    R > 1,
    R1 is R - 1,
    find_drop_row(R1, Board, Col, Row).

next_player(red, yellow).
next_player(yellow, red).

game_over(state(Board, _), Winner) :-
    ( horizontal_win(Board, P)
    ; vertical_win(Board, P)
    ; diagonal_win1(Board, P)
    ; diagonal_win2(Board, P)
    ),
    Winner = P, !.
game_over(state(Board, _), draw) :-
    \+ ( nth1(R, Board, Row), nth1(C, Row, empty) ).

horizontal_win(Board, P) :-
    between(1, 6, Row),
    between(1, 4, Col),
    cell_at(Board, Row, Col, P),
    C2 is Col+1, cell_at(Board, Row, C2, P),
    C3 is Col+2, cell_at(Board, Row, C3, P),
    C4 is Col+3, cell_at(Board, Row, C4, P).

vertical_win(Board, P) :-
    between(1, 6, Row),
    between(1, 7, Col),
    Row =< 3,
    cell_at(Board, Row, Col, P),
    R2 is Row+1, cell_at(Board, R2, Col, P),
    R3 is Row+2, cell_at(Board, R3, Col, P),
    R4 is Row+3, cell_at(Board, R4, Col, P).

diagonal_win1(Board, P) :-
    between(1, 3, Row),
    between(1, 4, Col),
    cell_at(Board, Row, Col, P),
    R2 is Row+1, C2 is Col+1, cell_at(Board, R2, C2, P),
    R3 is Row+2, C3 is Col+2, cell_at(Board, R3, C3, P),
    R4 is Row+3, C4 is Col+3, cell_at(Board, R4, C4, P).

diagonal_win2(Board, P) :-
    between(4, 6, Row),
    between(1, 4, Col),
    cell_at(Board, Row, Col, P),
    R2 is Row-1, C2 is Col+1, cell_at(Board, R2, C2, P),
    R3 is Row-2, C3 is Col+2, cell_at(Board, R3, C3, P),
    R4 is Row-3, C4 is Col+3, cell_at(Board, R4, C4, P).

cell_at(Board, Row, Col, Cell) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell).

render_state(state(Board, _)) :-
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(Cell) :-
    ( Cell = empty -> write('.')
    ; Cell = red   -> write('R')
    ; Cell = yellow-> write('Y') ),
    write(' ').