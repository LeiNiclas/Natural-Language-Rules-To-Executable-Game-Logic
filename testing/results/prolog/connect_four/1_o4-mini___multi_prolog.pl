:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, V, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, V, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(
    [
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty]
    ],
    red
)).

current_player(state(_, P), P).

legal_move(state(Board, Player), drop(Player, Col)) :-
    between(1, 7, Col),
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty).

other_player(red, yellow).
other_player(yellow, red).

apply_move(state(Board, Player), drop(Player, Col), state(NewBoard, NextPlayer)) :-
    between(1, 7, Col),
    nth1(1, Board, TopRow),
    nth1(Col, TopRow, empty),
    findall(R, (between(1, 6, R), nth1(R, Board, Row), nth1(Col, Row, empty)), Rows),
    last(Rows, Row),
    set_cell(Row, Col, Board, Player, NewBoard),
    other_player(Player, NextPlayer).

get_cell(Board, R, C, P) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, P).

horizontal_win(Board, P) :-
    between(1, 6, R),
    between(1, 4, C),
    get_cell(Board, R, C, P), P \= empty,
    C1 is C+1, get_cell(Board, R, C1, P),
    C2 is C+2, get_cell(Board, R, C2, P),
    C3 is C+3, get_cell(Board, R, C3, P).

vertical_win(Board, P) :-
    between(1, 3, R),
    between(1, 7, C),
    get_cell(Board, R, C, P), P \= empty,
    R1 is R+1, get_cell(Board, R1, C, P),
    R2 is R+2, get_cell(Board, R2, C, P),
    R3 is R+3, get_cell(Board, R3, C, P).

diag_dr_win(Board, P) :-
    between(1, 3, R),
    between(1, 4, C),
    get_cell(Board, R, C, P), P \= empty,
    R1 is R+1, C1 is C+1, get_cell(Board, R1, C1, P),
    R2 is R+2, C2 is C+2, get_cell(Board, R2, C2, P),
    R3 is R+3, C3 is C+3, get_cell(Board, R3, C3, P).

diag_ur_win(Board, P) :-
    between(4, 6, R),
    between(1, 4, C),
    get_cell(Board, R, C, P), P \= empty,
    R1 is R-1, C1 is C+1, get_cell(Board, R1, C1, P),
    R2 is R-2, C2 is C+2, get_cell(Board, R2, C2, P),
    R3 is R-3, C3 is C+3, get_cell(Board, R3, C3, P).

win(Board, P) :-
    horizontal_win(Board, P);
    vertical_win(Board, P);
    diag_dr_win(Board, P);
    diag_ur_win(Board, P).

board_full(Board) :-
    \+ ( member(Row, Board), member(empty, Row) ).

game_over(state(Board, _), Winner) :-
    win(Board, Winner).
game_over(state(Board, _), draw) :-
    board_full(Board),
    \+ win(Board, _).

% render empty, red, yellow as characters
print_cell(empty) :- format('.').
print_cell(red) :- format('r').
print_cell(yellow) :- format('y').

% render a single row with spaces between cells
render_row([C]) :- print_cell(C).
render_row([C|Cs]) :-
    print_cell(C),
    format(' '),
    render_row(Cs).

% render all rows of the board
render_rows([]).
render_rows([R|Rs]) :-
    render_row(R),
    nl,
    render_rows(Rs).

% render the full game state for Connect Four
render_state(state(Board, CurrentPlayer)) :-
    render_rows(Board),
    format('1 2 3 4 5 6 7'),
    nl,
    format('Current player: ~w', [CurrentPlayer]),
    nl.