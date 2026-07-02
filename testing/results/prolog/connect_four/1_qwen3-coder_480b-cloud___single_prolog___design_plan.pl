:- use_module(library(lists)).
:- use_module(library(apply)).

% Board is a 2D list (6 rows, 7 columns) of atoms (empty, red, yellow)
% CurrentPlayer is an atom (red or yellow)
% state(Board, CurrentPlayer)

initial_state(state([
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty]
], red)).

current_player(state(_, P), P).

% Legal move: Column is between 1 and 7, and top cell is empty
legal_move(state(Board, _), move(Column)) :-
    between(1, 7, Column),
    nth1(1, Board, TopRow),
    nth1(Column, TopRow, empty).

% Helper to find the row where a piece will land in a column
find_drop_row(Board, Column, Row) :-
    between(1, 6, Row),
    nth1(Row, Board, RowList),
    nth1(Column, RowList, empty),
    (   Row =:= 6
    ->  true
    ;   NextRow is Row + 1,
        nth1(NextRow, Board, NextRowList),
        nth1(Column, NextRowList, Below),
        Below \= empty
    ).

% Helper to switch player
switch_player(red, yellow).
switch_player(yellow, red).

% Apply move: drop piece in column, switch player
apply_move(state(Board, Player), move(Column), state(NewBoard, NextPlayer)) :-
    find_drop_row(Board, Column, Row),
    set_cell(Row, Column, Board, Player, NewBoard),
    switch_player(Player, NextPlayer).

% Set cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Game over: check win or draw
game_over(state(Board, _), Player) :-
    check_win(Board, Player).
game_over(state(Board, _), draw) :-
    board_full(Board),
    \+ check_win(Board, red),
    \+ check_win(Board, yellow).

% Check if board is full
board_full(Board) :-
    \+ (member(Row, Board), member(empty, Row)).

% Check win for any player
check_win(Board, Player) :-
    between(1, 6, Row),
    between(1, 7, Col),
    (   check_horizontal(Board, Row, Col, Player)
    ;   check_vertical(Board, Row, Col, Player)
    ;   check_diagonal_down(Board, Row, Col, Player)
    ;   check_diagonal_up(Board, Row, Col, Player)
    ).

% Check horizontal win
check_horizontal(Board, Row, Col, Player) :-
    C1 is Col, C2 is Col+1, C3 is Col+2, C4 is Col+3,
    C4 =< 7,
    nth1(Row, Board, RowList),
    nth1(C1, RowList, Player),
    nth1(C2, RowList, Player),
    nth1(C3, RowList, Player),
    nth1(C4, RowList, Player).

% Check vertical win
check_vertical(Board, Row, Col, Player) :-
    R1 is Row, R2 is Row+1, R3 is Row+2, R4 is Row+3,
    R4 =< 6,
    nth1(R1, Board, Row1List),
    nth1(R2, Board, Row2List),
    nth1(R3, Board, Row3List),
    nth1(R4, Board, Row4List),
    nth1(Col, Row1List, Player),
    nth1(Col, Row2List, Player),
    nth1(Col, Row3List, Player),
    nth1(Col, Row4List, Player).

% Check diagonal down-right win
check_diagonal_down(Board, Row, Col, Player) :-
    R1 is Row, R2 is Row+1, R3 is Row+2, R4 is Row+3,
    C1 is Col, C2 is Col+1, C3 is Col+2, C4 is Col+3,
    R4 =< 6, C4 =< 7,
    nth1(R1, Board, Row1List),
    nth1(R2, Board, Row2List),
    nth1(R3, Board, Row3List),
    nth1(R4, Board, Row4List),
    nth1(C1, Row1List, Player),
    nth1(C2, Row2List, Player),
    nth1(C3, Row3List, Player),
    nth1(C4, Row4List, Player).

% Check diagonal up-right win
check_diagonal_up(Board, Row, Col, Player) :-
    R1 is Row, R2 is Row-1, R3 is Row-2, R4 is Row-3,
    C1 is Col, C2 is Col+1, C3 is Col+2, C4 is Col+3,
    R4 >= 1, C4 =< 7,
    nth1(R1, Board, Row1List),
    nth1(R2, Board, Row2List),
    nth1(R3, Board, Row3List),
    nth1(R4, Board, Row4List),
    nth1(C1, Row1List, Player),
    nth1(C2, Row2List, Player),
    nth1(C3, Row3List, Player),
    nth1(C4, Row4List, Player).

% Render state
render_state(state(Board, Player)) :-
    format("Current player: ~w~n", [Player]),
    format(" 1 2 3 4 5 6 7~n"),
    forall(member(Row, Board),
           (   forall(member(Cell, Row),
                      (   Cell = empty -> format(' .')
                      ;   Cell = red -> format(' R')
                      ;   format(' Y')
                      )),
               format('~n')
           )),
    format("-------------------~n").