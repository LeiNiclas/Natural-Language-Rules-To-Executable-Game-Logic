:- use_module(library(lists)).
:- use_module(library(apply)).

% replace Nth element of a list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% set the cell at Row,Col in a 2D board
set_cell(1, Col, [Row|Rest], V, [NewRow|Rest]) :-
    set_nth1(Col, Row, V, NewRow).
set_cell(RowNum, Col, [Row|Rest], V, [Row|NewRest]) :-
    RowNum > 1,
    RowNum1 is RowNum - 1,
    set_cell(RowNum1, Col, Rest, V, NewRest).

% initial state: empty 6x7 board, red to move
initial_state(state(
    [[empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty]],
    red
)).

% get the current player from state
current_player(state(_, P), P).

% legal moves: drop a disc of the current player's color into a non-full column
legal_move(state(Board, Player), drop(Player, Col)) :-
    between(1, 7, Col),
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

% helper: find the lowest empty cell in column Col, return its Row index
drop_row(Board, Col, Row) :-
    drop_row(Board, Col, 6, Row).

drop_row(_, _, 0, _) :- fail.
drop_row(Board, Col, N, N) :-
    nth1(N, Board, RowList),
    nth1(Col, RowList, empty), !.
drop_row(Board, Col, N, Row) :-
    N > 0,
    N1 is N - 1,
    drop_row(Board, Col, N1, Row).

% switch player
other(red, yellow).
other(yellow, red).

% apply move: drop a disc and switch turn
apply_move(State, drop(Player, Col), state(NewBoard, NextPlayer)) :-
    legal_move(State, drop(Player, Col)),
    State = state(Board, Player),
    drop_row(Board, Col, Row),
    set_cell(Row, Col, Board, Player, NewBoard),
    other(Player, NextPlayer).

% helper to get a cell's value
cell(Board, Row, Col, Val) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Val).

% horizontal win
win_line(Board, Player) :-
    between(1, 6, Row),
    between(1, 4, Col),
    cell(Board, Row, Col, Player),
    Player \= empty,
    C1 is Col + 1, cell(Board, Row, C1, Player),
    C2 is Col + 2, cell(Board, Row, C2, Player),
    C3 is Col + 3, cell(Board, Row, C3, Player).

% vertical win
win_line(Board, Player) :-
    between(1, 3, Row),
    between(1, 7, Col),
    cell(Board, Row, Col, Player),
    Player \= empty,
    R1 is Row + 1, cell(Board, R1, Col, Player),
    R2 is Row + 2, cell(Board, R2, Col, Player),
    R3 is Row + 3, cell(Board, R3, Col, Player).

% diagonal down-right (\) win
win_line(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    cell(Board, Row, Col, Player),
    Player \= empty,
    R1 is Row + 1, C1 is Col + 1, cell(Board, R1, C1, Player),
    R2 is Row + 2, C2 is Col + 2, cell(Board, R2, C2, Player),
    R3 is Row + 3, C3 is Col + 3, cell(Board, R3, C3, Player).

% diagonal up-right (/) win
win_line(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    cell(Board, Row, Col, Player),
    Player \= empty,
    R1 is Row - 1, C1 is Col + 1, cell(Board, R1, C1, Player),
    R2 is Row - 2, C2 is Col + 2, cell(Board, R2, C2, Player),
    R3 is Row - 3, C3 is Col + 3, cell(Board, R3, C3, Player).

% game_over for a win
game_over(state(Board, _), Winner) :-
    win_line(Board, Winner), !.

% game_over for a draw
game_over(state(Board, _), draw) :-
    \+ (nth1(_, Board, Row), nth1(_, Row, empty)),
    \+ win_line(Board, _).

% render_state prints the board and current player
render_state(state(Board, Player)) :-
    maplist(render_row, Board),
    render_columns,
    ( Player = red -> Abbrev = r ; Player = yellow -> Abbrev = y ),
    format('Current player: ~w~n', [Abbrev]).

% render_row prints one row of the board
render_row(Row) :-
    maplist(render_cell, Row),
    nl.

% render_cell prints a single cell
render_cell(Cell) :-
    ( Cell = empty -> Symbol = '.' ;
      Cell = red -> Symbol = r ;
      Cell = yellow -> Symbol = y ),
    format('~w ', [Symbol]).

% render_columns prints column numbers
render_columns :-
    forall(between(1,7,C), format('~d ', [C])),
    nl.
