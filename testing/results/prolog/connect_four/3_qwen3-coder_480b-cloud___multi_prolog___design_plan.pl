:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Board, Row, Col, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state([
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty]
], red)).

current_player(state(_, Player), Player).

legal_move(state(Board, _), move(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, Cell),
    Cell = empty.

find_drop_row(_, 0, _) :- !, fail.
find_drop_row(Board, Column, Row) :-
    nth1(Row, Board, RowList),
    nth1(Column, RowList, empty), !.
find_drop_row(Board, Column, Row) :-
    NextRow is Row - 1,
    NextRow >= 1,
    find_drop_row(Board, Column, NextRow).

other_player(red, yellow).
other_player(yellow, red).

apply_move(state(Board, CurrentPlayer), move(Column), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, CurrentPlayer), move(Column)),
    find_drop_row(Board, Column, Row),
    set_cell(Board, Row, Column, CurrentPlayer, NewBoard),
    other_player(CurrentPlayer, NextPlayer).

check_line(Board, R1,C1,R2,C2,R3,C3,R4,C4, Player) :-
    nth1(R1, Board, Row1), nth1(C1, Row1, Cell1), Cell1 = Player,
    nth1(R2, Board, Row2), nth1(C2, Row2, Cell2), Cell2 = Player,
    nth1(R3, Board, Row3), nth1(C3, Row3, Cell3), Cell3 = Player,
    nth1(R4, Board, Row4), nth1(C4, Row4, Cell4), Cell4 = Player.

check_win(Board, Player) :-
    (   check_horizontal(Board, Player)
    ;   check_vertical(Board, Player)
    ;   check_diagonal_down(Board, Player)
    ;   check_diagonal_up(Board, Player)
    ).

check_horizontal(Board, Player) :-
    between(1, 6, R),
    between(1, 4, C),
    C1 is C, C2 is C+1, C3 is C+2, C4 is C+3,
    check_line(Board, R,C1,R,C2,R,C3,R,C4, Player).

check_vertical(Board, Player) :-
    between(1, 3, R),
    between(1, 7, C),
    R1 is R, R2 is R+1, R3 is R+2, R4 is R+3,
    check_line(Board, R1,C,R2,C,R3,C,R4,C, Player).

check_diagonal_down(Board, Player) :-
    between(1, 3, R),
    between(1, 4, C),
    R1 is R, R2 is R+1, R3 is R+2, R4 is R+3,
    C1 is C, C2 is C+1, C3 is C+2, C4 is C+3,
    check_line(Board, R1,C1,R2,C2,R3,C3,R4,C4, Player).

check_diagonal_up(Board, Player) :-
    between(4, 6, R),
    between(1, 4, C),
    R1 is R, R2 is R-1, R3 is R-2, R4 is R-3,
    C1 is C, C2 is C+1, C3 is C+2, C4 is C+3,
    check_line(Board, R1,C1,R2,C2,R3,C3,R4,C4, Player).

board_full(Board) :-
    \+ (nth1(_, Board, Row), nth1(_, Row, empty)).

game_over(State, Winner) :-
    State = state(Board, _),
    (   check_win(Board, red) ->
        Winner = red
    ;   check_win(Board, yellow) ->
        Winner = yellow
    ;   board_full(Board) ->
        Winner = draw
    ).

render_state(state(Board, CurrentPlayer)) :-
    forall(nth1(RowIndex, Board, Row),
           (   forall(nth1(ColIndex, Row, Cell),
                      (   (Cell = empty ->
                           format('.')
                         ; format('~w', [Cell]))
                      )),
               nl
           )),
    format('1 2 3 4 5 6 7~n'),
    format('Current player: ~w~n', [CurrentPlayer]).