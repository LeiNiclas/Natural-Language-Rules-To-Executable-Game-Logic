:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% initial state: empty Connect Four board and starting player red
initial_state(state([
  [empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty]
], red)).

% current player to move
current_player(state(_, P), P).

% legal_move(State, Move) is true when Move is a legal drop into a non-full column
legal_move(state(Board,_), move(Column)) :-
    between(1,7,Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

% switch_player(Current, Next)
other_player(red, yellow).
other_player(yellow, red).

% drop_position(Board, Column, Row) finds lowest empty row in Column
drop_position(Board, Col, Row) :- drop_position(Board, Col, 6, Row).
drop_position(Board, Col, Curr, Curr) :-
    Curr >= 1,
    nth1(Curr, Board, RowList),
    nth1(Col, RowList, empty),
    !.
drop_position(Board, Col, Curr, Row) :-
    Curr > 1,
    Prev is Curr - 1,
    drop_position(Board, Col, Prev, Row).

% set_cell(Board, Row, Column, Player, NewBoard)
% produces NewBoard by setting cell at (Row,Column) to Player
set_cell(Board, Row, Col, Val, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Val, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% apply_move(State, Move, NewState)
% NewState is result of dropping a checker for current player in Move's column
apply_move(state(Board, Player), move(Col), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), move(Col)),
    drop_position(Board, Col, Row),
    set_cell(Board, Row, Col, Player, NewBoard),
    other_player(Player, NextPlayer).

% line_of_four(Board, StartRow, StartCol, DRow, DCol, Player)
% succeeds when four consecutive positions from (StartRow,StartCol) by (DRow,DCol) are Player
line_of_four(Board, SR, SC, DR, DC, Player) :-
    nth1(SR, Board, Row1), nth1(SC, Row1, Player),
    SR2 is SR+DR, SC2 is SC+DC, nth1(SR2, Board, Row2), nth1(SC2, Row2, Player),
    SR3 is SR+2*DR, SC3 is SC+2*DC, nth1(SR3, Board, Row3), nth1(SC3, Row3, Player),
    SR4 is SR+3*DR, SC4 is SC+3*DC, nth1(SR4, Board, Row4), nth1(SC4, Row4, Player).

% any_win(Board, Player) is true if Player has any line of four
any_win(Board, Player) :-
    between(1,6,R), between(1,4,C),
    line_of_four(Board, R, C, 0, 1, Player).
any_win(Board, Player) :-
    between(1,3,R), between(1,7,C),
    line_of_four(Board, R, C, 1, 0, Player).
any_win(Board, Player) :-
    between(1,3,R), between(1,4,C),
    line_of_four(Board, R, C, 1, 1, Player).
any_win(Board, Player) :-
    between(4,6,R), between(1,4,C),
    line_of_four(Board, R, C, -1, 1, Player).

% board_full(Board) is true when no cell is empty
board_full(Board) :-
    \+ ( member(Row, Board), member(empty, Row) ).

% game_over(State, Winner) succeeds when the game is over with Winner or draw
game_over(state(Board, Current), Winner) :-
    other_player(Winner, Current),
    any_win(Board, Winner),
    !.
game_over(state(Board,_), draw) :-
    board_full(Board),
    \+ any_win(Board, red),
    \+ any_win(Board, yellow).

% cell_char(Cell, Char) maps cell value to display character
cell_char(empty, '.') :- !.
cell_char(red, 'r') :- !.
cell_char(yellow, 'y') :- !.

% player_char(Player, Char) maps player to display character
player_char(red, 'r').
player_char(yellow, 'y').

% render_row(Row) prints one row of the board
render_row(Row) :-
    maplist(cell_char, Row, Chars),
    atomic_list_concat(Chars, ' ', Line),
    format('~w~n', [Line]).

% render_column_labels prints column numbers 1 through 7
render_column_labels :-
    format('1 2 3 4 5 6 7~n').

% render_state(State) prints the board and current player
render_state(state(Board, Player)) :-
    maplist(render_row, Board),
    render_column_labels,
    player_char(Player, PChar),
    format('Current player: ~w~n', [PChar]).