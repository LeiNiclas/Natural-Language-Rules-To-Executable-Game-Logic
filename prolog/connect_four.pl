:- use_module(library(lists)).
:- use_module(library(apply)).

% 2D board representation: list of 6 rows, each a list of 7 atoms (empty, red, yellow)

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(Board, red)) :-
    Row = [empty, empty, empty, empty, empty, empty, empty],
    Board = [Row, Row, Row, Row, Row, Row].

current_player(state(_, P), P).

legal_move(state(Board, _), move(Col)) :-
    between(1, 7, Col),
    get_cell(Board, 1, Col, empty).

apply_move(state(Board, Player), move(Col), state(NewBoard, Next)) :-
    between(1, 7, Col),
    get_cell(Board, 1, Col, empty),
    drop_disc(Board, Col, Player, NewBoard),
    switch_player(Player, Next).

game_over(state(Board, _), Winner) :-
    four_in_a_row(Board, Winner).

game_over(state(Board, _), draw) :-
    \+ (member(Row, Board), member(empty, Row)),
    \+ four_in_a_row(Board, red),
    \+ four_in_a_row(Board, yellow).

render_state(state(Board, Player)) :-
    format("Current player: ~w~n", [Player]),
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(empty) :- format(".").
render_cell(red) :- format("R").
render_cell(yellow) :- format("Y").

get_cell(Board, Row, Col, Cell) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell).

column_full(Board, Col) :-
    get_cell(Board, 1, Col, Cell),
    Cell \= empty.

drop_disc(Board, Col, Player, NewBoard) :-
    findall(R, (between(1, 6, R), get_cell(Board, R, Col, empty)), Rows),
    last(Rows, Row),
    set_cell(Row, Col, Board, Player, NewBoard).

switch_player(red, yellow).
switch_player(yellow, red).

check_horizontal(RowList, P) :-
    append(_, [P, P, P, P | _], RowList).

check_vertical(Board, Col, P) :-
    findall(Cell, (between(1, 6, R), get_cell(Board, R, Col, Cell)), ColList),
    check_horizontal(ColList, P).

check_diagonal_neg(Board, P) :-
    between(1, 3, R),
    between(1, 4, C),
    get_cell(Board, R, C, P),
    R1 is R+1, C1 is C+1, get_cell(Board, R1, C1, P),
    R2 is R+2, C2 is C+2, get_cell(Board, R2, C2, P),
    R3 is R+3, C3 is C+3, get_cell(Board, R3, C3, P).

check_diagonal_pos(Board, P) :-
    between(1, 3, R),
    between(4, 7, C),
    get_cell(Board, R, C, P),
    R1 is R+1, C1 is C-1, get_cell(Board, R1, C1, P),
    R2 is R+2, C2 is C-2, get_cell(Board, R2, C2, P),
    R3 is R+3, C3 is C-3, get_cell(Board, R3, C3, P).

four_in_a_row(Board, P) :-
    P \= empty,
    (   member(Row, Board), check_horizontal(Row, P)
    ;   between(1, 7, C), check_vertical(Board, C, P)
    ;   check_diagonal_neg(Board, P)
    ;   check_diagonal_pos(Board, P)
    ).