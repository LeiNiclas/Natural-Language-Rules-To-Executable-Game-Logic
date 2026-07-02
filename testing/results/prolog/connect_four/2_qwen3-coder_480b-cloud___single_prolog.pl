:- use_module(library(lists)).
:- use_module(library(apply)).

% Board is a list of 6 rows, each row is a list of 7 cells.
% Rows are numbered 1 to 6 from top to bottom.
% Columns are numbered 1 to 7 from left to right.
% Cells are either empty, red, or yellow.

% Helper to update a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state: empty 6x7 board, red to move
initial_state(state([
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty]
], red)).

% Current player
current_player(state(_, Player), Player).

% Legal move: column must be between 1 and 7 and top cell must be empty
legal_move(state(Board, _), Column) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

% Apply move: find lowest empty row in column, place piece, switch player
apply_move(state(Board, Player), Column, state(NewBoard, NextPlayer)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty),
    find_lowest_empty_row(Board, Column, Row),
    set_cell(Row, Column, Board, Player, NewBoard),
    (Player = red -> NextPlayer = yellow ; NextPlayer = red).

% Find the lowest empty row in a column (from row 6 down to 1)
find_lowest_empty_row(Board, Col, Row) :-
    find_lowest_empty_row_(Board, Col, 6, Row).

find_lowest_empty_row_(_, _, 0, _) :- !, fail.
find_lowest_empty_row_(Board, Col, R, R) :-
    nth1(R, Board, RowList),
    nth1(Col, RowList, empty), !.
find_lowest_empty_row_(Board, Col, R, Row) :-
    R > 0,
    R1 is R - 1,
    find_lowest_empty_row_(Board, Col, R1, Row).

% Game over: win or draw
game_over(State, Winner) :-
    win(State, Winner).
game_over(State, draw) :-
    draw(State).

% Check for win
win(state(Board, _), Player) :-
    (check_horizontal(Board, Player) ;
     check_vertical(Board, Player) ;
     check_diagonal_down(Board, Player) ;
     check_diagonal_up(Board, Player)).

% Check horizontal win
check_horizontal(Board, Player) :-
    member(Row, Board),
    append(_, [Player, Player, Player, Player|_], Row).

% Check vertical win
check_vertical(Board, Player) :-
    between(1, 3, Row),
    between(1, 7, Col),
    nth1(Row, Board, Row1),
    nth1(Row+1, Board, Row2),
    nth1(Row+2, Board, Row3),
    nth1(Row+3, Board, Row4),
    nth1(Col, Row1, Player),
    nth1(Col, Row2, Player),
    nth1(Col, Row3, Player),
    nth1(Col, Row4, Player).

% Check diagonal down win (top-left to bottom-right)
check_diagonal_down(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    nth1(Row, Board, R1),
    nth1(Row+1, Board, R2),
    nth1(Row+2, Board, R3),
    nth1(Row+3, Board, R4),
    nth1(Col, R1, Player),
    nth1(Col+1, R2, Player),
    nth1(Col+2, R3, Player),
    nth1(Col+3, R4, Player).

% Check diagonal up win (bottom-left to top-right)
check_diagonal_up(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, R1),
    nth1(Row-1, Board, R2),
    nth1(Row-2, Board, R3),
    nth1(Row-3, Board, R4),
    nth1(Col, R1, Player),
    nth1(Col+1, R2, Player),
    nth1(Col+2, R3, Player),
    nth1(Col+3, R4, Player).

% Draw: board full with no winner
draw(state(Board, _)) :-
    \+ (member(Row, Board), member(empty, Row)).

% Render state
render_state(state(Board, Player)) :-
    format("  1 2 3 4 5 6 7~n"),
    forall(nth1(RowNum, Board, Row),
           (format("~w ", [RowNum]),
            forall(nth1(_, Row, Cell),
                   (Cell = empty -> format(". ") ;
                    Cell = red -> format("R ") ;
                    format("Y "))),
            format("~n"))),
    format("Current player: ~w~n", [Player]).