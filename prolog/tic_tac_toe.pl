:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list, 3x3
% state(Board, CurrentPlayer)
% Board = [[Row1], [Row2], [Row3]]
% CurrentPlayer = x | o

initial_state(state([[empty, empty, empty],
                     [empty, empty, empty],
                     [empty, empty, empty]], x)).

current_player(state(_, P), P).

% Generate all legal moves: every empty cell is a valid move
legal_move(State, move(Row, Col)) :-
    state(Board, _) = State,
    between(1, 3, Row),
    between(1, 3, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty).

% Apply move: place player's mark at (Row, Col)
apply_move(state(Board, Player), move(Row, Col), state(NewBoard, NextPlayer)) :-
    % Check if the move is legal
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    % Update the board
    set_cell(Row, Col, Board, Player, NewBoard),
    next_player(Player, NextPlayer).

% Set cell helper for 2D lists
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Player alternation
next_player(x, o).
next_player(o, x).

% Game over: win or draw
game_over(State, Winner) :-
    check_win(State, Winner).
game_over(state(Board, _), draw) :-
    flatten(Board, FlatBoard),
    \+ member(empty, FlatBoard),
    \+ check_win(state(Board, _), _).

% Check win conditions
check_win(state(Board, Player), Player) :-
    (check_row_win(Board, Player) ;
     check_col_win(Board, Player) ;
     check_diag_win(Board, Player)).

% Check rows
check_row_win([Row|_], Player) :-
    all_same(Row, Player).
check_row_win([_|T], Player) :-
    check_row_win(T, Player).

all_same([X,X,X], X).

% Check columns
check_col_win(Board, Player) :-
    between(1, 3, Col),
    maplist(nth1(Col), Board, Column),
    all_same(Column, Player).

% Check diagonals
check_diag_win(Board, Player) :-
    nth1(1, Board, Row1), nth1(1, Row1, Player),
    nth1(2, Board, Row2), nth1(2, Row2, Player),
    nth1(3, Board, Row3), nth1(3, Row3, Player).

check_diag_win(Board, Player) :-
    nth1(1, Board, Row1), nth1(3, Row1, Player),
    nth1(2, Board, Row2), nth1(2, Row2, Player),
    nth1(3, Board, Row3), nth1(1, Row3, Player).

% Render the board
render_state(state(Board, Player)) :-
    format("Current player: ~w~n", [Player]),
    forall(member(Row, Board),
           (forall(member(Cell, Row),
                   (Cell = empty -> format(" . ") ; format(" ~w ", [Cell]))),
            nl)).