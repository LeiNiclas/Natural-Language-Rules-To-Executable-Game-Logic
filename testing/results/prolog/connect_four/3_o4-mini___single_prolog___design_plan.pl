:- use_module(library(lists)).
:- use_module(library(apply)).  % apply imported though not used

% Board representation:
% Board = list of 6 rows, each row is a list of 7 atoms (empty, red, yellow).
% state = state(Board, CurrentPlayer)

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- 
    N > 1, 
    N1 is N-1, 
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Board, Value, NewBoard)
% updates the 2D board at (Row,Col) to Value
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% column_in_range(Column)
% true if Column is integer 1..7
column_in_range(C) :-
    between(1,7,C).

% top_cell_empty(Board, Column)
% true if the cell at row 1, Column is empty
top_cell_empty(Board, Col) :-
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

% find_drop_row(Board, Column, Row)
% finds the largest Row index where that cell is empty
find_drop_row(Board, Col, Row) :-
    find_drop_row(Board, Col, 6, Row).
find_drop_row(Board, Col, Cur, Cur) :-
    nth1(Cur, Board, RowList),
    nth1(Col, RowList, empty), 
    !.
find_drop_row(Board, Col, Cur, Row) :-
    Cur > 1,
    Next is Cur - 1,
    find_drop_row(Board, Col, Next, Row).

% next_player(Current, Next)
next_player(red, yellow).
next_player(yellow, red).

% check_line(Board, SR, SC, DR, DC, Player)
% true if four in a line from (SR,SC) in direction (DR,DC) all equal Player
check_line(Board, SR, SC, DR, DC, Player) :-
    nth1(SR, Board, R1), nth1(SC, R1, Player), Player \= empty,
    R2 is SR+DR, C2 is SC+DC, nth1(R2, Board, R2l), nth1(C2, R2l, Player),
    R3 is SR+2*DR, C3 is SC+2*DC, nth1(R3, Board, R3l), nth1(C3, R3l, Player),
    R4 is SR+3*DR, C4 is SC+3*DC, nth1(R4, Board, R4l), nth1(C4, R4l, Player).

% board_full(Board)
% true if no empty cells remain
board_full(Board) :-
    \+ (member(Row, Board), member(empty, Row)).

initial_state(state(
    [
      [empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty]
    ],
    red)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Col)) :-
    column_in_range(Col),
    top_cell_empty(Board, Col).

apply_move(state(Board, Player), move(Col), state(NewBoard, Next)) :-
    column_in_range(Col),
    top_cell_empty(Board, Col),
    find_drop_row(Board, Col, Row),
    set_cell(Row, Col, Board, Player, NewBoard),
    next_player(Player, Next).

game_over(state(Board, _), Player) :-
    member(Player, [red, yellow]),
    (
      between(1,6,SR), between(1,4,SC), check_line(Board, SR, SC, 0, 1, Player)
    ;
      between(1,3,SR), between(1,7,SC), check_line(Board, SR, SC, 1, 0, Player)
    ;
      between(1,3,SR), between(1,4,SC), check_line(Board, SR, SC, 1, 1, Player)
    ;
      between(4,6,SR), between(1,4,SC), check_line(Board, SR, SC, -1, 1, Player)
    ).

game_over(state(Board, _), draw) :-
    \+ game_over(state(Board,_), red),
    \+ game_over(state(Board,_), yellow),
    board_full(Board).

render_state(state(Board, _)) :-
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(Cell) :-
    ( Cell = empty  -> format('. ')
    ; Cell = red    -> format('R ')
    ; Cell = yellow -> format('Y ')
    ).