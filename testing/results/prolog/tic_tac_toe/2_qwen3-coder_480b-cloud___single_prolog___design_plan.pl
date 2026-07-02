:- use_module(library(lists)).
:- use_module(library(apply)).

% Flat list representation for 3x3 board
% Index mapping:
% 1 2 3
% 4 5 6
% 7 8 9

% Helper to replace element at position N in a list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, CurrentPlayer)
% Board = list of 9 atoms (empty, x, o)
% CurrentPlayer = x | o

initial_state(state([empty, empty, empty, empty, empty, empty, empty, empty, empty], x)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Position)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty).

apply_move(state(Board, CurrentPlayer), move(Position), state(NewBoard, NextPlayer)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty),
    set_nth1(Position, Board, CurrentPlayer, NewBoard),
    (CurrentPlayer = x -> NextPlayer = o ; NextPlayer = x).

% Check if Player has a winning line on Board
check_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

check_win(Board, Player) :-
    % Rows
    check_line(Board, 1, 2, 3, Player) ;
    check_line(Board, 4, 5, 6, Player) ;
    check_line(Board, 7, 8, 9, Player) ;
    % Columns
    check_line(Board, 1, 4, 7, Player) ;
    check_line(Board, 2, 5, 8, Player) ;
    check_line(Board, 3, 6, 9, Player) ;
    % Diagonals
    check_line(Board, 1, 5, 9, Player) ;
    check_line(Board, 3, 5, 7, Player).

game_over(State, Winner) :-
    State = state(Board, _),
    check_win(Board, Winner).

game_over(State, draw) :-
    State = state(Board, _),
    \+ member(empty, Board),
    \+ (check_win(Board, x) ; check_win(Board, o)).

render_state(state(Board, CurrentPlayer)) :-
    format("Current player: ~w~n", [CurrentPlayer]),
    format("Board:~n"),
    nth1(1, Board, C1), nth1(2, Board, C2), nth1(3, Board, C3),
    nth1(4, Board, C4), nth1(5, Board, C5), nth1(6, Board, C6),
    nth1(7, Board, C7), nth1(8, Board, C8), nth1(9, Board, C9),
    (C1 = empty -> format('.') ; format('~w', [C1])), format(' '),
    (C2 = empty -> format('.') ; format('~w', [C2])), format(' '),
    (C3 = empty -> format('.') ; format('~w', [C3])), format('~n'),
    (C4 = empty -> format('.') ; format('~w', [C4])), format(' '),
    (C5 = empty -> format('.') ; format('~w', [C5])), format(' '),
    (C6 = empty -> format('.') ; format('~w', [C6])), format('~n'),
    (C7 = empty -> format('.') ; format('~w', [C7])), format(' '),
    (C8 = empty -> format('.') ; format('~w', [C8])), format(' '),
    (C9 = empty -> format('.') ; format('~w', [C9])), format('~n').