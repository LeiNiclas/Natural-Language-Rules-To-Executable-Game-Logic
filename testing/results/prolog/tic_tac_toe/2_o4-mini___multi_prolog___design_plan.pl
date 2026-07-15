:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% initial_state(State) - fully ground starting state
initial_state(state(
    [empty,empty,empty,
     empty,empty,empty,
     empty,empty,empty],
    x
)).

% current_player(State, Player) - Player to move
current_player(state(_, P), P).

% legal_move(State, Move) - Move is a legal move in State
legal_move(state(Board,_), move(Pos)) :-
    between(1, 9, Pos),
    nth1(Pos, Board, empty).

% apply_move(State, Move, NewState) - apply Move if legal, switch player
apply_move(state(Board, x), move(Pos), state(NewBoard, o)) :-
    legal_move(state(Board, x), move(Pos)),
    set_nth1(Pos, Board, x, NewBoard).

apply_move(state(Board, o), move(Pos), state(NewBoard, x)) :-
    legal_move(state(Board, o), move(Pos)),
    set_nth1(Pos, Board, o, NewBoard).

% winning_line(Board, I1, I2, I3, Player) - three in a row
winning_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

% board_full(Board) - no empty cells
board_full(Board) :-
    \+ member(empty, Board).

% game_over(State, Winner) - Winner is a player or draw
game_over(state(Board,_), Player) :-
    winning_line(Board, 1, 2, 3, Player).
game_over(state(Board,_), Player) :-
    winning_line(Board, 4, 5, 6, Player).
game_over(state(Board,_), Player) :-
    winning_line(Board, 7, 8, 9, Player).
game_over(state(Board,_), Player) :-
    winning_line(Board, 1, 4, 7, Player).
game_over(state(Board,_), Player) :-
    winning_line(Board, 2, 5, 8, Player).
game_over(state(Board,_), Player) :-
    winning_line(Board, 3, 6, 9, Player).
game_over(state(Board,_), Player) :-
    winning_line(Board, 1, 5, 9, Player).
game_over(state(Board,_), Player) :-
    winning_line(Board, 3, 5, 7, Player).
game_over(state(Board,_), draw) :-
    board_full(Board).

% render_state(State) - print board and current player
render_state(state(Board, Player)) :-
    print_row(Board, [1,2,3]),
    nl,
    print_row(Board, [4,5,6]),
    nl,
    print_row(Board, [7,8,9]),
    nl,
    format("Current player: ~w", [Player]).

% print_row(Board, Positions) - print one row of positions
print_row(Board, [P1,P2,P3]) :-
    nth1(P1, Board, C1), cell_char(C1, Ch1),
    nth1(P2, Board, C2), cell_char(C2, Ch2),
    nth1(P3, Board, C3), cell_char(C3, Ch3),
    format("~w:~w ~w:~w ~w:~w", [P1, Ch1, P2, Ch2, P3, Ch3]).

% cell_char(Content, Char) - map empty to '.', others to themselves
cell_char(empty, '.').
cell_char(X, X) :-
    X \= empty.