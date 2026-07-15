:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N - 1, set_nth1(N1, T, V, R).

% set_cell(+Board, +Row, +Col, +Player, -NewBoard)
set_cell(Board, Row, Col, Player, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Player, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(
    [[empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty]],
    red
)).

current_player(state(_, P), P).

% valid_column(+Column) succeeds for each integer Column from 1 to 7
valid_column(Column) :-
    between(1, 7, Column).

% top_empty(+Board, +Column) succeeds if the top cell in Column is empty
top_empty(Board, Column) :-
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

% legal_move(+State, -Move) generates all legal drop(Column) moves
legal_move(state(Board, _), drop(Column)) :-
    valid_column(Column),
    top_empty(Board, Column).

% apply_move(+State, +Move, -NewState)
apply_move(state(Board, Player), drop(Column), state(NewBoard, NextPlayer)) :-
    valid_column(Column),
    top_empty(Board, Column),
    member(Row, [6,5,4,3,2,1]),
    nth1(Row, Board, RowList),
    nth1(Column, RowList, empty),
    set_cell(Board, Row, Column, Player, NewBoard),
    ( Player = red -> NextPlayer = yellow ; NextPlayer = red ).

% game_over(+State, -Winner) succeeds if a player has won or it's a draw
% Winner is the winning player atom or 'draw'
game_over(state(Board,_), Winner) :-
    check_win(Board, Winner).

game_over(state(Board,_), draw) :-
    \+ (nth1(_, Board, Row), member(empty, Row)),
    \+ check_win(Board, red),
    \+ check_win(Board, yellow).

% render_state(+State) prints the board and current player
render_state(state(Board, Player)) :-
    maplist(render_row, Board),
    render_columns,
    abbr_player(Player, PShort),
    format('Current player: ~w~n', [PShort]).

% render_row(+Row) prints one row of cells
render_row(Row) :-
    maplist(render_cell_with_space, Row),
    nl.

% render_cell_with_space(+Cell) prints cell symbol and a space
render_cell_with_space(Cell) :-
    render_cell(Cell),
    format(' ').

% render_cell(+Cell) prints symbol for cell
render_cell(empty) :-
    format('.').
render_cell(red) :-
    format('r').
render_cell(yellow) :-
    format('y').

% render_columns prints column numbers 1 to 7
render_columns :-
    render_cols(1).

render_cols(8) :-
    nl.
render_cols(N) :-
    N =< 7,
    format('~w', [N]),
    ( N < 7 -> format(' ') ; true ),
    N1 is N + 1,
    render_cols(N1).

% abbr_player(+Player, -Abbreviation)
abbr_player(red, r).
abbr_player(yellow, y).

% check_win/2 and related predicates assumed implemented elsewhere.