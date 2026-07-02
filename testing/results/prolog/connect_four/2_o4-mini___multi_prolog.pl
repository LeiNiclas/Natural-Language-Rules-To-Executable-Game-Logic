:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Board, Value, NewBoard)
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state([
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty]
], red)).

current_player(state(_, P), P).

% legal_move(State, Move) - generative over all legal drop moves
legal_move(state(Board, Player), drop(Player, Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

% other_player(Player, Next)
other_player(red, yellow).
other_player(yellow, red).

% find_empty_row(Board, Column, Row) finds the lowest available row (highest index)
find_empty_row(Board, Column, Row) :-
    find_empty_row(Board, Column, 6, Row).

find_empty_row(Board, Column, N, Row) :-
    N > 0,
    nth1(N, Board, RowList),
    nth1(Column, RowList, empty),
    Row = N.
find_empty_row(Board, Column, N, Row) :-
    N > 1,
    N1 is N - 1,
    find_empty_row(Board, Column, N1, Row).

% apply_move(State, Move, NewState) applies a drop move or fails if illegal
apply_move(state(Board, Player), drop(Player, Column), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), drop(Player, Column)),
    find_empty_row(Board, Column, Row),
    set_cell(Row, Column, Board, Player, NewBoard),
    other_player(Player, NextPlayer).

% game_over(State, Winner) - Winner is a player atom or 'draw'; fails if ongoing
game_over(state(Board,_), Player) :-
    wins(Board, Player).
game_over(state(Board,_), draw) :-
    \+ wins(Board, _),
    board_full(Board).

% wins(Board, Player) holds if Player has four in a row
wins(Board, Player) :-
    Player \= empty,
    horizontal_win(Board, Player).
wins(Board, Player) :-
    Player \= empty,
    vertical_win(Board, Player).
wins(Board, Player) :-
    Player \= empty,
    diag_down_win(Board, Player).
wins(Board, Player) :-
    Player \= empty,
    diag_up_win(Board, Player).

% horizontal four in a row
horizontal_win(Board, Player) :-
    between(1, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Player),
    C2 is Col+1, nth1(C2, RowList, Player),
    C3 is Col+2, nth1(C3, RowList, Player),
    C4 is Col+3, nth1(C4, RowList, Player).

% vertical four in a row
vertical_win(Board, Player) :-
    between(1, 3, Row),
    between(1, 7, Col),
    nth1(Row, Board, RL1), nth1(Col, RL1, Player),
    R2 is Row+1, nth1(R2, Board, RL2), nth1(Col, RL2, Player),
    R3 is Row+2, nth1(R3, Board, RL3), nth1(Col, RL3, Player),
    R4 is Row+3, nth1(R4, Board, RL4), nth1(Col, RL4, Player).

% diagonal down-right four in a row
diag_down_win(Board, Player) :-
    between(1, 3, Row),
    between(1, 4, Col),
    nth1(Row, Board, RL1), nth1(Col, RL1, Player),
    R2 is Row+1, C2 is Col+1, nth1(R2, Board, RL2), nth1(C2, RL2, Player),
    R3 is Row+2, C3 is Col+2, nth1(R3, Board, RL3), nth1(C3, RL3, Player),
    R4 is Row+3, C4 is Col+3, nth1(R4, Board, RL4), nth1(C4, RL4, Player).

% diagonal up-right four in a row
diag_up_win(Board, Player) :-
    between(4, 6, Row),
    between(1, 4, Col),
    nth1(Row, Board, RL1), nth1(Col, RL1, Player),
    R2 is Row-1, C2 is Col+1, nth1(R2, Board, RL2), nth1(C2, RL2, Player),
    R3 is Row-2, C3 is Col+2, nth1(R3, Board, RL3), nth1(C3, RL3, Player),
    R4 is Row-3, C4 is Col+3, nth1(R4, Board, RL4), nth1(C4, RL4, Player).

% board_full(Board) holds if no empty cells remain
board_full(Board) :-
    \+ (nth1(_, Board, Row), nth1(_, Row, empty)).

% render_state(State) prints board to stdout
render_state(state(Board, Player)) :-
    maplist(render_row, Board),
    render_columns,
    abbrev(Player, PChar),
    format('Current player: ~w', [PChar]), nl.

% render_row(RowList) prints one row
render_row([C|Cs]) :-
    render_cell(C),
    render_row_rest(Cs),
    nl.

% render_row_rest(Rest)
render_row_rest([]).
render_row_rest([C|Cs]) :-
    write(' '),
    render_cell(C),
    render_row_rest(Cs).

% render_cell(Cell) prints cell representation
render_cell(empty) :- write('.').
render_cell(red) :- write('r').
render_cell(yellow) :- write('y').

% render_columns prints column numbers
render_columns :-
    write('1'),
    render_columns_rest(2).
render_columns_rest(N) :-
    N =< 7,
    write(' '), write(N),
    N1 is N + 1,
    render_columns_rest(N1).
render_columns_rest(N) :-
    N > 7,
    nl.

% abbrev mapping
abbrev(red, r).
abbrev(yellow, y).
