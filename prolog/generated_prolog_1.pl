:- use_module(library(lists)).

% --- set_nth1: the only way to update a list element ---
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% ==========================================================
% State = state(Board, CurrentPlayer)
% Board = list of 9 atoms (X, O, or empty)
% CurrentPlayer = x | o
% ==========================================================

% --- Initial state ---
initial_state(state([empty, empty, empty, empty, empty, empty, empty, empty, empty], x)).

% --- Current player ---
current_player(state(_, P), P).

% --- Legal moves ---
% A move is place(Index). Index must be 1-9 and the square must be empty.
legal_move(state(Board, _), place(Index)) :-
    between(1, 9, Index),
    nth1(Index, Board, empty).

% --- Apply move ---
% Place the mark and switch player. Fail if illegal.
apply_move(state(Board, Player), place(Index), state(NewBoard, NextPlayer)) :-
    nth1(Index, Board, empty),
    set_nth1(Index, Board, Player, NewBoard),
    (Player = x -> NextPlayer = o ; NextPlayer = x).

% --- Win lines ---
check_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

% --- Game over ---
game_over(State, Winner) :-
    State = state(Board, _),
    (check_line(Board, 1, 2, 3, Winner) ;
     check_line(Board, 4, 5, 6, Winner) ;
     check_line(Board, 7, 8, 9, Winner) ;
     check_line(Board, 1, 4, 7, Winner) ;
     check_line(Board, 2, 5, 8, Winner) ;
     check_line(Board, 3, 6, 9, Winner) ;
     check_line(Board, 1, 5, 9, Winner) ;
     check_line(Board, 3, 5, 7, Winner)),
    !.

game_over(state(Board, _), draw) :-
    \+ member(empty, Board),
    \+ game_over(state(Board, _), _).

% --- Render state ---
render_state(state(Board, Player)) :-
    format("Current player: ~w~n", [Player]),
    format("Board:~n"),
    nth1(1, Board, S1), nth1(2, Board, S2), nth1(3, Board, S3),
    nth1(4, Board, S4), nth1(5, Board, S5), nth1(6, Board, S6),
    nth1(7, Board, S7), nth1(8, Board, S8), nth1(9, Board, S9),
    format(" ~w | ~w | ~w ~n", [S1, S2, S3]),
    format("---+---+---~n"),
    format(" ~w | ~w | ~w ~n", [S4, S5, S6]),
    format("---+---+---~n"),
    format(" ~w | ~w | ~w ~n", [S7, S8, S9]).

% === QUERY REFERENCE ===
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, place(5), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).