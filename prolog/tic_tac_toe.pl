:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, Player)
% Board = list of 9 atoms (empty, x, o)
% Player = x | o

initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

current_player(state(_, P), P).

legal_move(state(Board, _), play(Index)) :-
    between(1, 9, Index),
    nth1(Index, Board, empty).

apply_move(state(Board, x), play(Index), state(NewBoard, o)) :-
    nth1(Index, Board, empty),
    set_nth1(Index, Board, x, NewBoard).
apply_move(state(Board, o), play(Index), state(NewBoard, x)) :-
    nth1(Index, Board, empty),
    set_nth1(Index, Board, o, NewBoard).

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
    \+ game_over(state(Board, _), _).

check_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player).

render_state(state(Board, Player)) :-
    format("Current player: ~w~n", [Player]),
    format("+---+---+---+~n"),
    nth1(1, Board, S1), nth1(2, Board, S2), nth1(3, Board, S3),
    format("| ~w | ~w | ~w |~n", [symbol(S1), symbol(S2), symbol(S3)]),
    format("+---+---+---+~n"),
    nth1(4, Board, S4), nth1(5, Board, S5), nth1(6, Board, S6),
    format("| ~w | ~w | ~w |~n", [symbol(S4), symbol(S5), symbol(S6)]),
    format("+---+---+---+~n"),
    nth1(7, Board, S7), nth1(8, Board, S8), nth1(9, Board, S9),
    format("| ~w | ~w | ~w |~n", [symbol(S7), symbol(S8), symbol(S9)]),
    format("+---+---+---+~n").

symbol(empty) :- write(' ').
symbol(X) :- X \= empty, write(X).

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, play(5), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).