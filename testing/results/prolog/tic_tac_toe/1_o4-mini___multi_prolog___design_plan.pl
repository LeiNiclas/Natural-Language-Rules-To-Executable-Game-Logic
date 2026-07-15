:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(+Index, +List, +Value, -NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% initial_state(-State)
% State = state(Board, CurrentPlayer)
initial_state(state(
    [empty,empty,empty,
     empty,empty,empty,
     empty,empty,empty],
    x
)).

% current_player(+State, -Player)
current_player(state(_, Player), Player).

% legal_move(+State, -Move)
legal_move(state(Board,_), move(Position)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty).

% apply_move(+State, +Move, -NewState)
apply_move(state(Board, Player), move(Position), state(NewBoard, NewPlayer)) :-
    integer(Position),
    Position >= 1,
    Position =< 9,
    nth1(Position, Board, empty),
    set_nth1(Position, Board, Player, NewBoard),
    ( Player == x -> NewPlayer = o ; Player == o -> NewPlayer = x ).

% check_line(+Board, +I, +J, +K, -Player)
check_line(Board, I, J, K, Player) :-
    nth1(I, Board, Player),
    Player \= empty,
    nth1(J, Board, Player),
    nth1(K, Board, Player).

% winner(+Board, -Player)
winner(Board, Player) :-
    check_line(Board, 1, 2, 3, Player);
    check_line(Board, 4, 5, 6, Player);
    check_line(Board, 7, 8, 9, Player);
    check_line(Board, 1, 4, 7, Player);
    check_line(Board, 2, 5, 8, Player);
    check_line(Board, 3, 6, 9, Player);
    check_line(Board, 1, 5, 9, Player);
    check_line(Board, 3, 5, 7, Player).

% board_full(+Board)
board_full(Board) :-
    \+ member(empty, Board).

% game_over(+State, -Winner)
game_over(state(Board, _), Winner) :-
    winner(Board, Winner).
game_over(state(Board, _), draw) :-
    board_full(Board),
    \+ winner(Board, _).

% cell_char(+Cell, -Char)
cell_char(empty, '.').
cell_char(x, x).
cell_char(o, o).

% render_row(+Board, +Base)
render_row(Board, Base) :-
    Pos1 = Base,
    Pos2 is Base + 1,
    Pos3 is Base + 2,
    nth1(Pos1, Board, C1),
    nth1(Pos2, Board, C2),
    nth1(Pos3, Board, C3),
    cell_char(C1, Char1),
    cell_char(C2, Char2),
    cell_char(C3, Char3),
    format('~d:~w ~d:~w ~d:~w~n', [Pos1, Char1, Pos2, Char2, Pos3, Char3]).

% render_state(+State)
render_state(state(Board, Player)) :-
    render_row(Board, 1),
    render_row(Board, 4),
    render_row(Board, 7),
    format('Current player: ~w~n', [Player]).
