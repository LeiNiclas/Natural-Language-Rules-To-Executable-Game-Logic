:- use_module(library(lists)).
:- use_module(library(apply)).

% Flat list representation for 3x3 board.
% Index 1 is top-left, 9 is bottom-right.
% Board = [P1, P2, P3, P4, P5, P6, P7, P8, P9]

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, CurrentPlayer)
% Board = list of 9 atoms (empty | x | o)
% CurrentPlayer = x | o

initial_state(state([empty, empty, empty, empty, empty, empty, empty, empty, empty], x)).

current_player(state(_, P), P).

legal_move(state(Board, _), Position) :-
    integer(Position),
    Position >= 1,
    Position =< 9,
    nth1(Position, Board, empty).

apply_move(state(Board, CurrentPlayer), Position, state(NewBoard, NextPlayer)) :-
    integer(Position),
    Position >= 1,
    Position =< 9,
    nth1(Position, Board, empty),
    set_nth1(Position, Board, CurrentPlayer, NewBoard),
    (CurrentPlayer = x -> NextPlayer = o ; NextPlayer = x).

game_over(state(Board, _), Winner) :-
    (check_line(Board, 1, 2, 3, Winner)
    ; check_line(Board, 4, 5, 6, Winner)
    ; check_line(Board, 7, 8, 9, Winner)
    ; check_line(Board, 1, 4, 7, Winner)
    ; check_line(Board, 2, 5, 8, Winner)
    ; check_line(Board, 3, 6, 9, Winner)
    ; check_line(Board, 1, 5, 9, Winner)
    ; check_line(Board, 3, 5, 7, Winner)),
    Winner \= empty.
game_over(state(Board, _), draw) :-
    \+ member(empty, Board),
    \+ (check_line(Board, 1, 2, 3, Winner)
       ; check_line(Board, 4, 5, 6, Winner)
       ; check_line(Board, 7, 8, 9, Winner)
       ; check_line(Board, 1, 4, 7, Winner)
       ; check_line(Board, 2, 5, 8, Winner)
       ; check_line(Board, 3, 6, 9, Winner)
       ; check_line(Board, 1, 5, 9, Winner)
       ; check_line(Board, 3, 5, 7, Winner)).

check_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

render_state(state(Board, CurrentPlayer)) :-
    format("Current player: ~w~n", [CurrentPlayer]),
    print_row(Board, 1),
    print_row(Board, 4),
    print_row(Board, 7),
    format("~n").

print_row(Board, Start) :-
    End is Start + 2,
    forall(between(Start, End, I),
           (nth1(I, Board, C),
            (C = empty -> format('.') ; format('~w', [C])),
            format(' '))),
    format('~n').