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

legal_move(state(Board, _), drop(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, Cell),
    Cell = empty.

apply_move(State, drop(Column), NewState) :-
    State = state(Board, CurrentPlayer),
    legal_move(State, drop(Column)),
    find_drop_row(Board, Column, Row),
    set_cell(Board, Row, Column, CurrentPlayer, NewBoard),
    next_player(CurrentPlayer, NextPlayer),
    NewState = state(NewBoard, NextPlayer).

find_drop_row(Board, Column, Row) :-
    find_drop_row_helper(Board, Column, 6, Row).

find_drop_row_helper(_, _, 0, _) :- !, fail.
find_drop_row_helper(Board, Column, Index, Index) :-
    nth1(Index, Board, RowList),
    nth1(Column, RowList, Cell),
    Cell = empty, !.
find_drop_row_helper(Board, Column, Index, Row) :-
    NextIndex is Index - 1,
    find_drop_row_helper(Board, Column, NextIndex, Row).

next_player(red, yellow).
next_player(yellow, red).

game_over(State, Winner) :-
    State = state(Board, _),
    check_win(Board, Winner),
    Winner \= empty.

game_over(State, draw) :-
    State = state(Board, _),
    \+ check_win(Board, _),
    board_full(Board).

check_win(Board, Player) :-
    (check_horizontal(Board, Player) ;
     check_vertical(Board, Player) ;
     check_diagonal_up(Board, Player) ;
     check_diagonal_down(Board, Player)).

check_horizontal(Board, Player) :-
    nth1(RowIdx, Board, Row),
    nth1(ColIdx, Row, Player), Player \= empty,
    ColIdx =< 4,
    NextCol1 is ColIdx + 1,
    NextCol2 is ColIdx + 2,
    NextCol3 is ColIdx + 3,
    nth1(NextCol1, Row, Player),
    nth1(NextCol2, Row, Player),
    nth1(NextCol3, Row, Player).

check_vertical(Board, Player) :-
    nth1(RowIdx, Board, Row),
    nth1(ColIdx, Row, Player), Player \= empty,
    RowIdx =< 3,
    NextRow1 is RowIdx + 1,
    NextRow2 is RowIdx + 2,
    NextRow3 is RowIdx + 3,
    nth1(NextRow1, Board, Row1),
    nth1(NextRow2, Board, Row2),
    nth1(NextRow3, Board, Row3),
    nth1(ColIdx, Row1, Player),
    nth1(ColIdx, Row2, Player),
    nth1(ColIdx, Row3, Player).

check_diagonal_up(Board, Player) :-
    nth1(RowIdx, Board, Row),
    nth1(ColIdx, Row, Player), Player \= empty,
    RowIdx >= 4,
    ColIdx =< 4,
    NextRow1 is RowIdx - 1,
    NextRow2 is RowIdx - 2,
    NextRow3 is RowIdx - 3,
    NextCol1 is ColIdx + 1,
    NextCol2 is ColIdx + 2,
    NextCol3 is ColIdx + 3,
    nth1(NextRow1, Board, Row1),
    nth1(NextRow2, Board, Row2),
    nth1(NextRow3, Board, Row3),
    nth1(NextCol1, Row1, Player),
    nth1(NextCol2, Row2, Player),
    nth1(NextCol3, Row3, Player).

check_diagonal_down(Board, Player) :-
    nth1(RowIdx, Board, Row),
    nth1(ColIdx, Row, Player), Player \= empty,
    RowIdx =< 3,
    ColIdx =< 4,
    NextRow1 is RowIdx + 1,
    NextRow2 is RowIdx + 2,
    NextRow3 is RowIdx + 3,
    NextCol1 is ColIdx + 1,
    NextCol2 is ColIdx + 2,
    NextCol3 is ColIdx + 3,
    nth1(NextRow1, Board, Row1),
    nth1(NextRow2, Board, Row2),
    nth1(NextRow3, Board, Row3),
    nth1(NextCol1, Row1, Player),
    nth1(NextCol2, Row2, Player),
    nth1(NextCol3, Row3, Player).

board_full(Board) :-
    \+ (nth1(_, Board, Row),
        nth1(_, Row, empty)).

render_state(state(Board, CurrentPlayer)) :-
    render_board(Board),
    format('Current player: ~w~n', [CurrentPlayer]).

render_board(Board) :-
    forall(nth1(RowIdx, Board, Row),
           (format('~d |', [RowIdx]),
            forall(nth1(_, Row, Cell),
                   (Cell = empty -> format(' .') ; format(' ~w', [Cell]))),
            format('~n'))),
    format('  +---------------~n'),
    format('    1 2 3 4 5 6 7~n').