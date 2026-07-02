:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Board, Row, Col, Value, NewBoard) :-
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

current_player(state(_, Player), Player).

legal_move(state(Board, _), drop(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, Cell),
    Cell = empty.

find_drop_row(Board, Column, Row) :-
    find_drop_row_helper(Board, Column, 6, Row).

find_drop_row_helper(_, _, 0, _) :- !, fail.
find_drop_row_helper(Board, Column, CurrentRow, CurrentRow) :-
    nth1(CurrentRow, Board, RowList),
    nth1(Column, RowList, Cell),
    Cell = empty, !.
find_drop_row_helper(Board, Column, CurrentRow, Row) :-
    NextRow is CurrentRow - 1,
    find_drop_row_helper(Board, Column, NextRow, Row).

switch_player(red, yellow).
switch_player(yellow, red).

apply_move(State, drop(Column), NewState) :-
    State = state(Board, CurrentPlayer),
    legal_move(State, drop(Column)),
    find_drop_row(Board, Column, Row),
    set_cell(Board, Row, Column, CurrentPlayer, NewBoard),
    switch_player(CurrentPlayer, NextPlayer),
    NewState = state(NewBoard, NextPlayer).

game_over(State, Winner) :-
    state(Board, _) = State,
    (check_win(Board, red) -> Winner = red
    ; check_win(Board, yellow) -> Winner = yellow
    ; board_full(Board) -> Winner = draw
    ).

check_win(Board, Player) :-
    check_horizontal(Board, Player)
    ; check_vertical(Board, Player)
    ; check_diagonal_down(Board, Player)
    ; check_diagonal_up(Board, Player).

check_horizontal(Board, Player) :-
    between(1, 6, Row),
    between(1, 4, Col),
    Col1 is Col, Col2 is Col+1, Col3 is Col+2, Col4 is Col+3,
    nth1(Row, Board, RowList),
    nth1(Col1, RowList, Cell1),
    nth1(Col2, RowList, Cell2),
    nth1(Col3, RowList, Cell3),
    nth1(Col4, RowList, Cell4),
    Cell1 = Player, Cell2 = Player, Cell3 = Player, Cell4 = Player.

check_vertical(Board, Player) :-
    between(1, 3, Row),
    between(1, 7, Col),
    Row1 is Row, Row2 is Row+1, Row3 is Row+2, Row4 is Row+3,
    nth1(Row1, Board, RowList1),
    nth1(Row2, Board, RowList2),
    nth1(Row3, Board, RowList3),
    nth1(Row4, Board, RowList4),
    nth1(Col, RowList1, Cell1),
    nth1(Col, RowList2, Cell2),
    nth1(Col, RowList3, Cell3),
    nth1(Col, RowList4, Cell4),
    Cell1 = Player, Cell2 = Player, Cell3 = Player, Cell4 = Player.

check_diagonal_down(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    Row1 is Row, Row2 is Row+1, Row3 is Row+2, Row4 is Row+3,
    Col1 is Col, Col2 is Col+1, Col3 is Col+2, Col4 is Col+3,
    nth1(Row1, Board, RowList1),
    nth1(Row2, Board, RowList2),
    nth1(Row3, Board, RowList3),
    nth1(Row4, Board, RowList4),
    nth1(Col1, RowList1, Cell1),
    nth1(Col2, RowList2, Cell2),
    nth1(Col3, RowList3, Cell3),
    nth1(Col4, RowList4, Cell4),
    Cell1 = Player, Cell2 = Player, Cell3 = Player, Cell4 = Player.

check_diagonal_up(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    Row1 is Row, Row2 is Row-1, Row3 is Row-2, Row4 is Row-3,
    Col1 is Col, Col2 is Col+1, Col3 is Col+2, Col4 is Col+3,
    nth1(Row1, Board, RowList1),
    nth1(Row2, Board, RowList2),
    nth1(Row3, Board, RowList3),
    nth1(Row4, Board, RowList4),
    nth1(Col1, RowList1, Cell1),
    nth1(Col2, RowList2, Cell2),
    nth1(Col3, RowList3, Cell3),
    nth1(Col4, RowList4, Cell4),
    Cell1 = Player, Cell2 = Player, Cell3 = Player, Cell4 = Player.

board_full(Board) :-
    \+ (nth1(_, Board, Row), nth1(_, Row, Cell), Cell = empty).

render_state(state(Board, CurrentPlayer)) :-
    render_board(Board),
    format('Current player: ~w~n', [CurrentPlayer]).

render_board(Board) :-
    forall(nth1(RowIdx, Board, Row),
           (format('~d |', [RowIdx]),
            forall(nth1(_, Row, Cell),
                   (Cell = empty -> format(' .')
                   ; format(' ~w', [Cell]))),
            format('~n'))),
    format('  +---------------~n'),
    format('    1 2 3 4 5 6 7~n').