:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Pos)) :-
    member(Pos, [1,2,3,4,5,6,7,8,9]),
    nth1(Pos, Board, empty).

next_player(x, o).
next_player(o, x).

apply_move(state(Board, Player), move(Pos), state(NewBoard, NextPlayer)) :-
    set_nth1(Pos, Board, Player, NewBoard),
    next_player(Player, NextPlayer).

win(Board, Player) :-
    (   (nth1(1,Board,Player), nth1(2,Board,Player), nth1(3,Board,Player))
    ;   (nth1(4,Board,Player), nth1(5,Board,Player), nth1(6,Board,Player))
    ;   (nth1(7,Board,Player), nth1(8,Board,Player), nth1(9,Board,Player))
    ;   (nth1(1,Board,Player), nth1(4,Board,Player), nth1(7,Board,Player))
    ;   (nth1(2,Board,Player), nth1(5,Board,Player), nth1(8,Board,Player))
    ;   (nth1(3,Board,Player), nth1(6,Board,Player), nth1(9,Board,Player))
    ;   (nth1(1,Board,Player), nth1(5,Board,Player), nth1(9,Board,Player))
    ;   (nth1(3,Board,Player), nth1(5,Board,Player), nth1(7,Board,Player))
    ).

game_over(state(Board, _), Winner) :-
    (   win(Board, x) -> Winner = x
    ;   win(Board, o) -> Winner = o
    ;   \+ member(empty, Board) -> Winner = draw
    ;   fail
    ).

render_state(state(Board, _)) :-
    nth1(1,Board,B1), nth1(2,Board,B2), nth1(3,Board,B3),
    nth1(4,Board,B4), nth1(5,Board,B5), nth1(6,Board,B6),
    nth1(7,Board,B7), nth1(8,Board,B8), nth1(9,Board,B9),
    format("~w|~w|~w~n", [B1,B2,B3]),
    format("~w|~w|~w~n", [B4,B5,B6]),
    format("~w|~w|~w~n", [B7,B8,B9]),
    nl.

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, move(5), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).