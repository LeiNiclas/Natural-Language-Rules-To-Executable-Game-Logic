:- use_module(library(lists)).
:- use_module(library(apply)).

% Board is a list of 6 rows, each row is a list of 7 cells.
% Rows are numbered 1 to 6 from top to bottom.
% Columns are numbered 1 to 7 from left to right.
% Cells are either 'empty', 'red', or 'yellow'.

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

% Current player is directly from the state
current_player(state(_, Player), Player).

% Legal move: column is between 1 and 7, and top cell of that column is empty
legal_move(state(Board, _), Column) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, Cell),
    Cell = empty.

% Apply move: find the lowest empty row in the column and place the piece
apply_move(state(Board, Player), Column, state(NewBoard, NextPlayer)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, Cell),
    Cell = empty,
    % Find the lowest empty row in this column
    find_lowest_empty_row(Board, Column, Row),
    % Update the board
    set_cell(Row, Column, Board, Player, NewBoard),
    % Switch player
    (Player = red -> NextPlayer = yellow ; NextPlayer = red).

% Helper to find the lowest empty row in a column
find_lowest_empty_row(Board, Col, Row) :-
    find_lowest_empty_row_helper(Board, Col, 6, Row).

find_lowest_empty_row_helper(_, _, 0, _) :- !, fail.
find_lowest_empty_row_helper(Board, Col, R, R) :-
    nth1(R, Board, RowList),
    nth1(Col, RowList, empty), !.
find_lowest_empty_row_helper(Board, Col, R, Row) :-
    R > 0,
    R1 is R - 1,
    find_lowest_empty_row_helper(Board, Col, R1, Row).

% Game over: either someone has won or it's a draw
game_over(State, Winner) :-
    (win_condition(State, Winner), Winner \= empty) ;
    (draw_condition(State), Winner = draw).

% Check for win conditions
win_condition(state(Board, Player), Player) :-
    % Horizontal
    (check_horizontal_win(Board, Player) ;
    % Vertical
    check_vertical_win(Board, Player) ;
    % Diagonal /
    check_diagonal_up_win(Board, Player) ;
    % Diagonal \
    check_diagonal_down_win(Board, Player)).

% Horizontal win: four in a row horizontally
check_horizontal_win(Board, Player) :-
    member(Row, Board),
    append(_, [Player, Player, Player, Player | _], Row).

% Vertical win: four in a row vertically
check_vertical_win(Board, Player) :-
    between(1, 3, Row), % Only need to check rows 1-3 for vertical
    between(1, 7, Col),
    nth1(Row, Board, Row1),
    nth1(Row+1, Board, Row2),
    nth1(Row+2, Board, Row3),
    nth1(Row+3, Board, Row4),
    nth1(Col, Row1, Player),
    nth1(Col, Row2, Player),
    nth1(Col, Row3, Player),
    nth1(Col, Row4, Player).

% Diagonal up win: four in a row diagonally up (/)
check_diagonal_up_win(Board, Player) :-
    between(4, 6, Row), % Start from row 4 to 6
    between(1, 4, Col), % Start from col 1 to 4
    nth1(Row, Board, Row1),
    nth1(Row-1, Board, Row2),
    nth1(Row-2, Board, Row3),
    nth1(Row-3, Board, Row4),
    nth1(Col, Row1, Player),
    nth1(Col+1, Row2, Player),
    nth1(Col+2, Row3, Player),
    nth1(Col+3, Row4, Player).

% Diagonal down win: four in a row diagonally down (\)
check_diagonal_down_win(Board, Player) :-
    between(1, 3, Row), % Start from row 1 to 3
    between(1, 4, Col), % Start from col 1 to 4
    nth1(Row, Board, Row1),
    nth1(Row+1, Board, Row2),
    nth1(Row+2, Board, Row3),
    nth1(Row+3, Board, Row4),
    nth1(Col, Row1, Player),
    nth1(Col+1, Row2, Player),
    nth1(Col+2, Row3, Player),
    nth1(Col+3, Row4, Player).

% Draw condition: board is full and no winner
draw_condition(state(Board, _)) :-
    \+ (member(Row, Board), member(empty, Row)),
    \+ win_condition(state(Board, red), red),
    \+ win_condition(state(Board, yellow), yellow).

% Render the board
render_state(state(Board, Player)) :-
    format('  1 2 3 4 5 6 7~n'),
    forall(nth1(RowIdx, Board, Row),
           (format('~w ', [RowIdx]),
            forall(nth1(_, Row, Cell),
                   (Cell = empty -> format('. ') ;
                    Cell = red -> format('R ') ;
                    format('Y '))),
            format('~n'))),
    format('Current player: ~w~n', [Player]).