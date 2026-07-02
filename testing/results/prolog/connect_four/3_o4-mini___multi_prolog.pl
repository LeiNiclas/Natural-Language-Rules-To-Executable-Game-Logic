:- use_module(library(lists)).
:- use_module(library(apply)).

% replace Nth element of a list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% set cell at (Row,Col) in a 2D board
set_cell(Row, Col, V, Board, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, V, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial state: empty 6x7 board, red to move
initial_state(state(Board, red)) :-
    Board = [
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty]
    ].

% current player of the state
current_player(state(_, P), P).

% legal moves: drop a checker into any non-full column
legal_move(state(Board, Player), drop(Player, Column)) :-
    between(1,7,Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

% map to next player
other_player(red, yellow).
other_player(yellow, red).

% find the row to drop into for a given column
drop_row(Col, Board, Row) :-
    drop_row(Col, Board, 6, Row).

drop_row(Col, Board, N, N) :-
    N >= 1,
    nth1(N, Board, RowList),
    nth1(Col, RowList, empty),
    !.
drop_row(Col, Board, N, Row) :-
    N > 1,
    N1 is N - 1,
    drop_row(Col, Board, N1, Row).

% apply a move to the state
apply_move(state(Board, Player), drop(Player, Column), state(NewBoard, NextPlayer)) :-
    between(1,7,Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty),
    drop_row(Column, Board, Row),
    set_cell(Row, Column, Player, Board, NewBoard),
    other_player(Player, NextPlayer).

% get value at (Row,Col)
get_cell(Board, Row, Col, Cell) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell).

% check horizontal win
horizontal_win(Board, Player) :-
    between(1,6,Row),
    between(1,4,Col),
    Col1 is Col+1,
    Col2 is Col+2,
    Col3 is Col+3,
    get_cell(Board, Row, Col, Player),
    Player \= empty,
    get_cell(Board, Row, Col1, Player),
    get_cell(Board, Row, Col2, Player),
    get_cell(Board, Row, Col3, Player).

% check vertical win
vertical_win(Board, Player) :-
    between(1,7,Col),
    between(1,3,Row),
    Row1 is Row+1,
    Row2 is Row+2,
    Row3 is Row+3,
    get_cell(Board, Row, Col, Player),
    Player \= empty,
    get_cell(Board, Row1, Col, Player),
    get_cell(Board, Row2, Col, Player),
    get_cell(Board, Row3, Col, Player).

% check diagonal down-right win
diag_dr_win(Board, Player) :-
    between(1,3,Row),
    between(1,4,Col),
    Row1 is Row+1,
    Row2 is Row+2,
    Row3 is Row+3,
    Col1 is Col+1,
    Col2 is Col+2,
    Col3 is Col+3,
    get_cell(Board, Row, Col, Player),
    Player \= empty,
    get_cell(Board, Row1, Col1, Player),
    get_cell(Board, Row2, Col2, Player),
    get_cell(Board, Row3, Col3, Player).

% check diagonal up-right win
diag_ur_win(Board, Player) :-
    between(1,4,Col),
    between(4,6,Row),
    Row1 is Row-1,
    Row2 is Row-2,
    Row3 is Row-3,
    Col1 is Col+1,
    Col2 is Col+2,
    Col3 is Col+3,
    get_cell(Board, Row, Col, Player),
    Player \= empty,
    get_cell(Board, Row1, Col1, Player),
    get_cell(Board, Row2, Col2, Player),
    get_cell(Board, Row3, Col3, Player).

% any winning line
win(Board, Player) :-
    horizontal_win(Board, Player)
    ;
    vertical_win(Board, Player)
    ;
    diag_dr_win(Board, Player)
    ;
    diag_ur_win(Board, Player).

% full board
board_full(Board) :-
    \+ ( member(Row, Board), member(empty, Row) ).

% game over with winner
game_over(state(Board, _), Player) :-
    win(Board, Player).

% game over draw
game_over(state(Board, _), draw) :-
    \+ win(Board, _),
    board_full(Board).

% render_state: print Connect Four board and current player
render_state(state(Board, Player)) :-
    maplist(render_row, Board),
    forall(between(1,7,C), format('~w ', [C])),
    nl,
    format('Current player: ~w~n', [Player]).

% render a single row of the board
render_row(Row) :-
    maplist(render_cell, Row),
    nl.

% render a single cell: empty as '.', red as 'r', yellow as 'y'
render_cell(Cell) :-
    ( Cell = empty -> Symbol = '.' ; Cell = red -> Symbol = 'r' ; Cell = yellow -> Symbol = 'y' ),
    format('~w ', [Symbol]).