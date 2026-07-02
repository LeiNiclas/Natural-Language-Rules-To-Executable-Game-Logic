:- use_module(library(lists)).
:- use_module(library(apply)).

% 2D board: list of 6 rows, each list of 7 cells: empty|red|yellow
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

legal_move(state(Board, _), drop(C)) :-
    between(1, 7, C),
    nth1(1, Board, TopRow),
    nth1(C, TopRow, empty).

find_row(C, Board, Row) :-
    between(1, 6, N),
    Row is 7-N,
    nth1(Row, Board, RowList),
    nth1(C, RowList, empty),
    !.

apply_move(state(Board, P), drop(C), state(NewBoard, Next)) :-
    find_row(C, Board, Row),
    set_cell(Row, C, Board, P, NewBoard),
    next_player(P, Next).

next_player(red, yellow).
next_player(yellow, red).

cell_at(Board, R, C, P) :-
    nth1(R, Board, Row),
    nth1(C, Row, P).

horizontal(Board, P) :-
    P \= empty,
    between(1, 6, R),
    between(1, 4, C),
    cell_at(Board, R, C, P),
    C1 is C+1, cell_at(Board, R, C1, P),
    C2 is C+2, cell_at(Board, R, C2, P),
    C3 is C+3, cell_at(Board, R, C3, P).

vertical(Board, P) :-
    P \= empty,
    between(1, 3, R),
    between(1, 7, C),
    cell_at(Board, R, C, P),
    R1 is R+1, cell_at(Board, R1, C, P),
    R2 is R+2, cell_at(Board, R2, C, P),
    R3 is R+3, cell_at(Board, R3, C, P).

diag_down(Board, P) :-
    P \= empty,
    between(1, 3, R),
    between(1, 4, C),
    cell_at(Board, R, C, P),
    R1 is R+1, C1 is C+1, cell_at(Board, R1, C1, P),
    R2 is R+2, C2 is C+2, cell_at(Board, R2, C2, P),
    R3 is R+3, C3 is C+3, cell_at(Board, R3, C3, P).

diag_up(Board, P) :-
    P \= empty,
    between(4, 6, R),
    between(1, 4, C),
    cell_at(Board, R, C, P),
    R1 is R-1, C1 is C+1, cell_at(Board, R1, C1, P),
    R2 is R-2, C2 is C+2, cell_at(Board, R2, C2, P),
    R3 is R-3, C3 is C+3, cell_at(Board, R3, C3, P).

win(Board, P) :- horizontal(Board, P).
win(Board, P) :- vertical(Board, P).
win(Board, P) :- diag_down(Board, P).
win(Board, P) :- diag_up(Board, P).

game_over(state(Board, _), P) :-
    win(Board, P).

game_over(state(Board, _), draw) :-
    \+ win(Board, red),
    \+ win(Board, yellow),
    \+ (member(Row, Board), member(empty, Row)).

render_cell(Cell) :-
    ( Cell = empty -> format('. ')
    ; Cell = red -> format('R ')
    ; Cell = yellow -> format('Y ')
    ).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_state(state(Board, _)) :-
    maplist(render_row, Board).