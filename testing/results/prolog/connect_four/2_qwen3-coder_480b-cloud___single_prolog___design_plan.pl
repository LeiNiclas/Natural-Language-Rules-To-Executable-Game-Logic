:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Board, CurrentPlayer)
% Board = [[empty,...], [empty,...], ...] one sublist per row, top to bottom
% CurrentPlayer = red | yellow

initial_state(state(
    [
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty]
    ],
    red
)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, Cell),
    Cell = empty.

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

apply_move(state(Board, CurrentPlayer), move(Column), NewState) :-
    find_drop_row(Board, Column, Row),
    set_cell(Row, Column, Board, CurrentPlayer, NewBoard),
    switch_player(CurrentPlayer, NextPlayer),
    NewState = state(NewBoard, NextPlayer).

find_drop_row(Board, Column, Row) :-
    find_drop_row_helper(Board, Column, 6, Row).

find_drop_row_helper(_, _, 0, _) :- fail.
find_drop_row_helper(Board, Column, R, R) :-
    nth1(R, Board, RowList),
    nth1(Column, RowList, Cell),
    Cell = empty, !.
find_drop_row_helper(Board, Column, R, Row) :-
    R > 0,
    nth1(R, Board, RowList),
    nth1(Column, RowList, Cell),
    Cell \= empty,
    R1 is R - 1,
    find_drop_row_helper(Board, Column, R1, Row).

switch_player(red, yellow).
switch_player(yellow, red).

game_over(state(Board, _), Winner) :-
    (check_win(Board, red) ->
        Winner = red
    ; check_win(Board, yellow) ->
        Winner = yellow
    ; board_full(Board) ->
        Winner = draw
    ).

check_win(Board, Player) :-
    check_horizontal(Board, Player)
    ;
    check_vertical(Board, Player)
    ;
    check_diagonal_up(Board, Player)
    ;
    check_diagonal_down(Board, Player).

check_horizontal(Board, Player) :-
    between(1, 6, Row),
    between(1, 4, Col),
    check_line(Board, Row, Col, Row, Col+1, Row, Col+2, Row, Col+3, Player).

check_vertical(Board, Player) :-
    between(1, 3, Row),
    between(1, 7, Col),
    check_line(Board, Row, Col, Row+1, Col, Row+2, Col, Row+3, Col, Player).

check_diagonal_up(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    check_line(Board, Row, Col, Row-1, Col+1, Row-2, Col+2, Row-3, Col+3, Player).

check_diagonal_down(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    check_line(Board, Row, Col, Row+1, Col+1, Row+2, Col+2, Row+3, Col+3, Player).

check_line(Board, R1, C1, R2, C2, R3, C3, R4, C4, Player) :-
    nth1(R1, Board, Row1), nth1(C1, Row1, Cell1),
    nth1(R2, Board, Row2), nth1(C2, Row2, Cell2),
    nth1(R3, Board, Row3), nth1(C3, Row3, Cell3),
    nth1(R4, Board, Row4), nth1(C4, Row4, Cell4),
    Cell1 = Player,
    Cell2 = Player,
    Cell3 = Player,
    Cell4 = Player.

board_full(Board) :-
    \+ (member(Row, Board), member(Cell, Row), Cell = empty).

render_state(state(Board, CurrentPlayer)) :-
    format("Current player: ~w~n", [CurrentPlayer]),
    format(" 1 2 3 4 5 6 7~n"),
    render_board(Board).

render_board([]).
render_board([Row|Rest]) :-
    render_row(Row),
    nl,
    render_board(Rest).

render_row([]).
render_row([Cell|Rest]) :-
    (Cell = empty ->
        format('. ')
    ; Cell = red ->
        format('R ')
    ; Cell = yellow ->
        format('Y ')
    ),
    render_row(Rest).