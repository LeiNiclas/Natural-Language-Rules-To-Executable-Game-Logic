:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList): replace element at Index in List with Value
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Value, Board, NewBoard): set cell at (Row, Col) in Board to Value
set_cell(Row, Col, V, Board, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, V, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial_state(State): 6x7 empty board, red to move
initial_state(state(Board, red)) :-
    Board = [
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty]
    ].

% current_player(State, Player): Player to move in State
current_player(state(_, P), P).

% valid_column(Column): Column is an integer between 1 and 7
valid_column(C) :-
    between(1, 7, C).

% column_top_empty(Board, Column): top cell in Column is empty
column_top_empty(Board, Col) :-
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

% legal_move(State, Move): Move is a legal drop move in State
legal_move(state(Board, _), drop(Col)) :-
    valid_column(Col),
    column_top_empty(Board, Col).

% switch_player(Current, Next): alternate between red and yellow
switch_player(red, yellow).
switch_player(yellow, red).

% find_drop_row(Board, Column, Row): highest empty row index in Column
find_drop_row(Board, Col, Row) :-
    member(Row, [6,5,4,3,2,1]),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    !.

% apply_move(State, Move, NewState): NewState is State after Move; fail if illegal
apply_move(state(Board, Player), drop(Col), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), drop(Col)),
    find_drop_row(Board, Col, Row),
    set_cell(Row, Col, Player, Board, NewBoard),
    switch_player(Player, NextPlayer).

% game_over(State, Winner): succeeds if State is terminal; Winner is player who won or draw
% win if the player who just moved has four in line
game_over(state(Board, NextPlayer), Winner) :-
    switch_player(Winner, NextPlayer),
    four_in_line(Board, Winner),
    !.
% draw if board full and no win for either player
game_over(state(Board, _), draw) :-
    board_full(Board),
    \+ four_in_line(Board, red),
    \+ four_in_line(Board, yellow).

% render_state: print human-readable board and current player

% cell rendering
render_cell(empty) :-
    format(".").
render_cell(red) :-
    format("r").
render_cell(yellow) :-
    format("y").

% row rendering
render_row(Row) :-
    render_row_cells(Row),
    nl.
render_row_cells([C]) :-
    render_cell(C).
render_row_cells([C|Cs]) :-
    render_cell(C),
    format(" "),
    render_row_cells(Cs).

% render_state(State): display board and current player
render_state(state(Board, Player)) :-
    maplist(render_row, Board),
    format("1 2 3 4 5 6 7~n"),
    format("Current player: "),
    render_cell(Player),
    nl.