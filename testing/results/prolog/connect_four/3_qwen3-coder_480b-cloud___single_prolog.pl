:- use_module(library(lists)).
:- use_module(library(apply)).

% Board is a list of 6 rows, each row is a list of 7 cells.
% Rows are numbered 1 to 6 from top to bottom.
% Columns are numbered 1 to 7 from left to right.
% Cells are atoms: empty, red, yellow.

% Helper to update a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state: empty 6x7 board, red to play
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

% Legal move: column is between 1 and 7 and top cell is empty
legal_move(state(Board, _), column(Col)) :-
    between(1, 7, Col),
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

% Apply move: find lowest empty row in column, place piece, switch player
apply_move(state(Board, Player), column(Col), state(NewBoard, NextPlayer)) :-
    between(1, 7, Col),
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty),
    find_lowest_empty_row(Board, Col, Row),
    set_cell(Row, Col, Board, Player, NewBoard),
    (Player = red -> NextPlayer = yellow ; NextPlayer = red).

% Find the lowest empty row in a column (6 down to 1)
find_lowest_empty_row(Board, Col, Row) :-
    between(6, 1, Row),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty), !.

% Game over: win or draw
game_over(State, Winner) :-
    win(State, Winner), !.
game_over(state(Board, _), draw) :-
    maplist(not_empty_row, Board).

not_empty_row(Row) :-
    \+ member(empty, Row).

% Check for win in all directions
win(state(Board, Player), Player) :-
    (win_horizontal(Board, Player) ;
     win_vertical(Board, Player) ;
     win_diagonal_down(Board, Player) ;
     win_diagonal_up(Board, Player)).

% Horizontal win
win_horizontal(Board, Player) :-
    member(Row, Board),
    consecutive_four(Row, Player).

% Vertical win
win_vertical(Board, Player) :-
    between(1, 7, Col),
    findall(Cell, (between(1, 6, Row), nth1(Row, Board, RowList), nth1(Col, RowList, Cell)), Column),
    consecutive_four(Column, Player).

% Diagonal down (\)
win_diagonal_down(Board, Player) :-
    between(1, 3, StartRow),
    between(1, 4, StartCol),
    find_diagonal_down(Board, StartRow, StartCol, Diag),
    length(Diag, Len),
    Len >= 4,
    consecutive_four(Diag, Player).

% Diagonal up (/)
win_diagonal_up(Board, Player) :-
    between(4, 6, StartRow),
    between(1, 4, StartCol),
    find_diagonal_up(Board, StartRow, StartCol, Diag),
    length(Diag, Len),
    Len >= 4,
    consecutive_four(Diag, Player).

% Collect diagonal down (\) from start position
find_diagonal_down(_, Row, _, []) :- Row > 6, !.
find_diagonal_down(_, _, Col, []) :- Col > 7, !.
find_diagonal_down(Board, Row, Col, [Cell|Rest]) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell),
    NextRow is Row + 1,
    NextCol is Col + 1,
    find_diagonal_down(Board, NextRow, NextCol, Rest).

% Collect diagonal up (/) from start position
find_diagonal_up(_, Row, _, []) :- Row < 1, !.
find_diagonal_up(_, _, Col, []) :- Col > 7, !.
find_diagonal_up(Board, Row, Col, [Cell|Rest]) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell),
    NextRow is Row - 1,
    NextCol is Col + 1,
    find_diagonal_up(Board, NextRow, NextCol, Rest).

% Check for 4 consecutive Player atoms in list
consecutive_four([P,P,P,P|_], P) :- P \= empty.
consecutive_four([_|T], P) :- consecutive_four(T, P).

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