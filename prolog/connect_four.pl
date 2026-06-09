:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper to set Nth element in list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% Helper to set cell at (Row,Col) in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Check column is between 1 and 7
column_in_range(Column) :-
    between(1, 7, Column).

% Check top cell of column is empty
column_not_full(Board, Column) :-
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

% Find drop row by scanning from bottom (6) upwards
find_drop_row(Board, Column, Row) :-
    find_drop_row(6, Board, Column, Row).
find_drop_row(0, _, _, _) :- fail.
find_drop_row(R, Board, Column, R) :-
    nth1(R, Board, RowList),
    nth1(Column, RowList, empty), !.
find_drop_row(R, Board, Column, Row) :-
    R1 is R - 1,
    find_drop_row(R1, Board, Column, Row).

% Update board at position with player's disc
update_board(Board, Row, Column, Player, NewBoard) :-
    set_cell(Row, Column, Board, Player, NewBoard).

% Alternate players
next_player(red, yellow).
next_player(yellow, red).

% Check four consecutive in a list
consecutive_four([A,B,C,D|_], Player) :-
    A == Player,
    B == Player,
    C == Player,
    D == Player.
consecutive_four([_|T], Player) :-
    consecutive_four(T, Player).

% Extract column list
get_column(Board, Col, ColList) :-
    findall(Cell, (nth1(_, Board, Row), nth1(Col, Row, Cell)), ColList).

% Extract descending diagonal from start
get_diag_desc(Board, Row, Col, [Cell|Rest]) :-
    Row =< 6,
    Col =< 7,
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell),
    R1 is Row + 1,
    C1 is Col + 1,
    get_diag_desc(Board, R1, C1, Rest).
get_diag_desc(_, Row, Col, []) :-
    (Row > 6 ; Col > 7).

% Extract ascending diagonal from start
get_diag_asc(Board, Row, Col, [Cell|Rest]) :-
    Row >= 1,
    Col =< 7,
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell),
    R1 is Row - 1,
    C1 is Col + 1,
    get_diag_asc(Board, R1, C1, Rest).
get_diag_asc(_, Row, Col, []) :-
    (Row < 1 ; Col > 7).

% Check horizontal win
four_consecutive_horizontal(Board, Player) :-
    member(RowList, Board),
    consecutive_four(RowList, Player).

% Check vertical win
four_consecutive_vertical(Board, Player) :-
    between(1, 7, Col),
    get_column(Board, Col, ColList),
    consecutive_four(ColList, Player).

% Check descending diagonal win
four_consecutive_diagonal_desc(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    get_diag_desc(Board, Row, Col, Diag),
    consecutive_four(Diag, Player).

% Check ascending diagonal win
four_consecutive_diagonal_asc(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    get_diag_asc(Board, Row, Col, Diag),
    consecutive_four(Diag, Player).

% Check if board is full (no empties)
board_full(Board) :-
    \+ ( member(Row, Board), member(empty, Row) ).

% Initial game state
initial_state(state([
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty]
], red)).

% Get current player
current_player(state(_, P), P).

% Enumerate legal moves
legal_move(state(Board, _), move(Column)) :-
    column_in_range(Column),
    column_not_full(Board, Column).

% Apply a move to the state
apply_move(state(Board, Player), move(Column), state(NewBoard, Next)) :-
    column_in_range(Column),
    column_not_full(Board, Column),
    find_drop_row(Board, Column, Row),
    update_board(Board, Row, Column, Player, NewBoard),
    next_player(Player, Next).

% Check for game over by win
game_over(state(Board, Current), Winner) :-
    next_player(Winner, Current),
    (
        four_consecutive_horizontal(Board, Winner)
    ;   four_consecutive_vertical(Board, Winner)
    ;   four_consecutive_diagonal_desc(Board, Winner)
    ;   four_consecutive_diagonal_asc(Board, Winner)
    ), !.

% Check for game over by draw
game_over(state(Board, _), draw) :-
    board_full(Board).

% Render the board and current player
render_state(state(Board, Player)) :-
    maplist(render_row, Board),
    format("Player to move: ~w~n", [Player]).

% Render a single row
render_row(Row) :-
    maplist(render_cell, Row),
    nl.

% Render a single cell
render_cell(empty) :- format(". ").
render_cell(red) :- format("R ").
render_cell(yellow) :- format("Y ").