:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list of 6 rows, 7 columns
% Rows are numbered 1 to 6 from top to bottom
% Columns are numbered 1 to 7 from left to right
% state(Board, CurrentPlayer)

initial_state(state([
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty]
], red)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

find_drop_row(Board, Column, Row) :-
    between(6, 1, R),
    nth1(R, Board, RowList),
    nth1(Column, RowList, empty),
    !,
    Row = R.

apply_move(state(Board, CurrentPlayer), move(Column), state(NewBoard, NextPlayer)) :-
    find_drop_row(Board, Column, Row),
    set_cell(Row, Column, Board, CurrentPlayer, NewBoard),
    (CurrentPlayer = red -> NextPlayer = yellow ; NextPlayer = red).

game_over(state(Board, _), Winner) :-
    check_win(Board, red),
    Winner = red.
game_over(state(Board, _), Winner) :-
    check_win(Board, yellow),
    Winner = yellow.
game_over(state(Board, _), draw) :-
    board_full(Board),
    \+ check_win(Board, red),
    \+ check_win(Board, yellow).

board_full(Board) :-
    \+ (member(Row, Board), member(empty, Row)).

check_win(Board, Player) :-
    check_horizontal_win(Board, Player) ;
    check_vertical_win(Board, Player) ;
    check_diagonal_up_win(Board, Player) ;
    check_diagonal_down_win(Board, Player).

check_horizontal_win(Board, Player) :-
    between(1, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Player),
    C2 is Col + 1,
    C3 is Col + 2,
    C4 is Col + 3,
    nth1(C2, RowList, Player),
    nth1(C3, RowList, Player),
    nth1(C4, RowList, Player),
    Player \= empty.

check_vertical_win(Board, Player) :-
    between(1, 3, Row),
    between(1, 7, Col),
    nth1(Row, Board, RowList1),
    nth1(Col, RowList1, Player),
    R2 is Row + 1,
    R3 is Row + 2,
    R4 is Row + 3,
    nth1(R2, Board, RowList2),
    nth1(R3, Board, RowList3),
    nth1(R4, Board, RowList4),
    nth1(Col, RowList2, Player),
    nth1(Col, RowList3, Player),
    nth1(Col, RowList4, Player),
    Player \= empty.

check_diagonal_up_win(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, RowList1),
    nth1(Col, RowList1, Player),
    R2 is Row - 1,
    C2 is Col + 1,
    R3 is Row - 2,
    C3 is Col + 2,
    R4 is Row - 3,
    C4 is Col + 3,
    nth1(R2, Board, RowList2),
    nth1(R3, Board, RowList3),
    nth1(R4, Board, RowList4),
    nth1(C2, RowList2, Player),
    nth1(C3, RowList3, Player),
    nth1(C4, RowList4, Player),
    Player \= empty.

check_diagonal_down_win(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    nth1(Row, Board, RowList1),
    nth1(Col, RowList1, Player),
    R2 is Row + 1,
    C2 is Col + 1,
    R3 is Row + 2,
    C3 is Col + 2,
    R4 is Row + 3,
    C4 is Col + 3,
    nth1(R2, Board, RowList2),
    nth1(R3, Board, RowList3),
    nth1(R4, Board, RowList4),
    nth1(C2, RowList2, Player),
    nth1(C3, RowList3, Player),
    nth1(C4, RowList4, Player),
    Player \= empty.

render_state(state(Board, CurrentPlayer)) :-
    format("Current player: ~w~n", [CurrentPlayer]),
    format(" 1 2 3 4 5 6 7~n"),
    forall(member(Row, Board),
           (forall(member(Cell, Row),
                   (Cell = empty -> format(' .') ;
                    Cell = red -> format(' R') ;
                    format(' Y'))),
            format('~n'))).