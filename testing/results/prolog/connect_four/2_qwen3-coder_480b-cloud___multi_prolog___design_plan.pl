:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Board, Row, Col, Value, NewBoard) :-
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

current_player(state(_, Player), Player).

legal_move(state(Board, _), move(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

find_drop_row(Board, Column, Row) :-
    find_drop_row_helper(Board, Column, 6, Row).

find_drop_row_helper(_, _, 0, _) :- !, fail.
find_drop_row_helper(Board, Column, Index, Index) :-
    nth1(Index, Board, RowList),
    nth1(Column, RowList, empty), !.
find_drop_row_helper(Board, Column, Index, Row) :-
    NextIndex is Index - 1,
    find_drop_row_helper(Board, Column, NextIndex, Row).

switch_player(red, yellow).
switch_player(yellow, red).

apply_move(State, Move, NewState) :-
    State = state(Board, CurrentPlayer),
    Move = move(Column),
    legal_move(State, Move),
    find_drop_row(Board, Column, Row),
    set_cell(Board, Row, Column, CurrentPlayer, NewBoard),
    switch_player(CurrentPlayer, NextPlayer),
    NewState = state(NewBoard, NextPlayer).

game_over(State, Winner) :-
    State = state(Board, CurrentPlayer),
    (check_win(Board, CurrentPlayer) ->
        Winner = CurrentPlayer
    ; (board_full(Board) ->
        Winner = draw
      ; fail)).

check_win(Board, Player) :-
    (check_horizontal_win(Board, Player) ;
     check_vertical_win(Board, Player) ;
     check_diagonal_win(Board, Player)).

check_horizontal_win(Board, Player) :-
    nth1(RowIdx, Board, Row),
    append(_, [Player, Player, Player, Player|_], Row).

check_vertical_win(Board, Player) :-
    between(1, 3, StartRow),
    between(1, 7, Col),
    findall(Cell, (between(0, 3, Offset), Row is StartRow + Offset, get_cell(Board, Row, Col, Cell)), Cells),
    Cells = [Player, Player, Player, Player].

check_diagonal_win(Board, Player) :-
    (check_diagonal_down_win(Board, Player) ;
     check_diagonal_up_win(Board, Player)).

check_diagonal_down_win(Board, Player) :-
    between(1, 3, StartRow),
    between(1, 4, StartCol),
    findall(Cell, (between(0, 3, Offset), Row is StartRow + Offset, Col is StartCol + Offset, get_cell(Board, Row, Col, Cell)), Cells),
    Cells = [Player, Player, Player, Player].

check_diagonal_up_win(Board, Player) :-
    between(4, 6, StartRow),
    between(1, 4, StartCol),
    findall(Cell, (between(0, 3, Offset), Row is StartRow - Offset, Col is StartCol + Offset, get_cell(Board, Row, Col, Cell)), Cells),
    Cells = [Player, Player, Player, Player].

board_full(Board) :-
    \+ (nth1(_, Board, Row), nth1(_, Row, empty)).

get_cell(Board, Row, Col, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

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