:- use_module(library(lists)).

% --- set_nth1: the only way to update a list element ---
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% ==========================================================
% State = state(Board)
% Board = list of 9 atoms (x, o, empty)
% ==========================================================

% --- Initial state ---
initial_state(state([empty, empty, empty, empty, empty, empty, empty, empty, empty])).

% --- Current player ---
% X always starts; if equal number of x and o, it's x's turn, otherwise o's
current_player(state(Board), x) :-
    include(=(x), Board, Xs),
    include(=(o), Board, Os),
    length(Xs, XCount),
    length(Os, OCount),
    XCount =:= OCount.

current_player(state(Board), o) :-
    include(=(x), Board, Xs),
    include(=(o), Board, Os),
    length(Xs, XCount),
    length(Os, OCount),
    XCount > OCount.

% --- Legal moves ---
% A move is just a position index (1-9)
legal_move(state(Board), Pos) :-
    between(1, 9, Pos),
    nth1(Pos, Board, empty).

% --- Apply move ---
apply_move(State, Pos, NewState) :-
    legal_move(State, Pos),
    current_player(State, Player),
    State = state(Board),
    set_nth1(Pos, Board, Player, NewBoard),
    NewState = state(NewBoard).

% --- Win checking ---
check_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

game_over(state(Board), Winner) :-
    (check_line(Board, 1, 2, 3, Winner) ;
     check_line(Board, 4, 5, 6, Winner) ;
     check_line(Board, 7, 8, 9, Winner) ;
     check_line(Board, 1, 4, 7, Winner) ;
     check_line(Board, 2, 5, 8, Winner) ;
     check_line(Board, 3, 6, 9, Winner) ;
     check_line(Board, 1, 5, 9, Winner) ;
     check_line(Board, 3, 5, 7, Winner)).

game_over(state(Board), draw) :-
    \+ member(empty, Board),
    \+ game_over(state(Board), _).

% --- Render state ---
render_state(state(Board)) :-
    format("Board:~n"),
    nth1(1, Board, C1), nth1(2, Board, C2), nth1(3, Board, C3),
    nth1(4, Board, C4), nth1(5, Board, C5), nth1(6, Board, C6),
    nth1(7, Board, C7), nth1(8, Board, C8), nth1(9, Board, C9),
    format(" ~w | ~w | ~w ~n", [C1, C2, C3]),
    format("---+---+---~n"),
    format(" ~w | ~w | ~w ~n", [C4, C5, C6]),
    format("---+---+---~n"),
    format(" ~w | ~w | ~w ~n", [C7, C8, C9]).

% === QUERY REFERENCE ===
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, 1, S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).