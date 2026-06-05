:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(Board, red)) :-
    length(Row, 7), maplist(=(empty), Row),
    length(Board, 6), maplist(=(Row), Board).

current_player(state(_, P), P).

legal_move(state(Board, _), column(Col)) :-
    between(1, 7, Col),
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

apply_move(state(Board, P), column(Col), state(NewBoard, NextP)) :-
    legal_move(state(Board, P), column(Col)),
    find_lowest_empty(Board, Col, Row),
    set_cell(Row, Col, Board, P, NewBoard),
    next_player(P, NextP).

find_lowest_empty(Board, Col, Row) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    (Row = 6 ; (Row < 6, nth1(RowNext, Board, RowNextList), nth1(Col, RowNextList, V), V \= empty)).

next_player(red, yellow).
next_player(yellow, red).

game_over(State, Winner) :- win_condition(State, Winner).
game_over(state(Board, _), draw) :- \+ (member(Row, Board), member(empty, Row)).

win_condition(state(Board, Player), Player) :-
    (horizontal_win(Board, Player);
     vertical_win(Board, Player);
     diagonal_win(Board, Player)).

horizontal_win(Board, Player) :-
    member(Row, Board),
    append(_, [Player, Player, Player, Player|_], Row).

vertical_win(Board, Player) :-
    columns(Board, Cols),
    member(Col, Cols),
    append(_, [Player, Player, Player, Player|_], Col).

diagonal_win(Board, Player) :-
    ascending_diagonals(Board, Diags),
    member(Diag, Diags),
    append(_, [Player, Player, Player, Player|_], Diag).

diagonal_win(Board, Player) :-
    descending_diagonals(Board, Diags),
    member(Diag, Diags),
    append(_, [Player, Player, Player, Player|_], Diag).

columns(Board, Cols) :-
    transpose(Board, Cols).

ascending_diagonals(Board, Diags) :-
    findall(Diag, ascending_diag(Board, Diag), Diags).

ascending_diag(Board, Diag) :-
    length(Board, RowCount),
    length(Board, ColCount),
    between(1, RowCount, StartRow),
    between(1, ColCount, StartCol),
    diag_ascend(Board, StartRow, StartCol, Diag).

diag_ascend(Board, Row, Col, [Elem|Diag]) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Elem),
    Row1 is Row + 1, Col1 is Col + 1,
    diag_ascend(Board, Row1, Col1, Diag).
diag_ascend(_, Row, Col, []) :-
    \+ (Row > 0, Col > 0).

descending_diagonals(Board, Diags) :-
    findall(Diag, descending_diag(Board, Diag), Diags).

descending_diag(Board, Diag) :-
    length(Board, RowCount),
    length(Board, ColCount),
    between(1, RowCount, StartRow),
    between(1, ColCount, StartCol),
    diag_descend(Board, StartRow, StartCol, Diag).

diag_descend(Board, Row, Col, [Elem|Diag]) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Elem),
    Row1 is Row + 1, Col1 is Col - 1,
    diag_descend(Board, Row1, Col1, Diag).
diag_descend(_, Row, Col, []) :-
    \+ (Row > 0, Col > 0).

render_state(state(Board, CurrentPlayer)) :-
    maplist(render_row, Board),
    format("Current Player: ~w~n", [CurrentPlayer]).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(empty) :- format('.').
render_cell(P) :- format('~w', [P]).