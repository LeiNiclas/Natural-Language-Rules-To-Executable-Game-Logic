:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% initial_state(State)
initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

% current_player(State, P)
current_player(state(_, Turn), Turn).

% legal_move(State, Move)
legal_move(state(Board, Turn), move(Pos)) :-
    between(1,9,Pos),
    nth1(Pos, Board, empty).

% opposite/2
opposite(x, o).
opposite(o, x).

% apply_move(State, Move, New)
apply_move(state(Board, Turn), move(Pos), state(NewBoard, NextTurn)) :-
    nth1(Pos, Board, empty),
    set_nth1(Pos, Board, Turn, NewBoard),
    opposite(Turn, NextTurn).

% win_for(Board, Player)
win_for(Board, Player) :-
    member(Combo, [[1,2,3],[4,5,6],[7,8,9],[1,4,7],[2,5,8],[3,6,9],[1,5,9],[3,5,7]]),
    all_same(Board, Combo, Player).

% all_same(Board, [Index|Rest], Player)
all_same(_, [], _).
all_same(Board, [Idx|Rest], Player) :-
    nth1(Idx, Board, Player),
    all_same(Board, Rest, Player).

% game_over(State, Winner)
game_over(state(Board, _), Winner) :-
    win_for(Board, Winner).
game_over(state(Board, _), draw) :-
    \+ member(empty, Board),
    \+ win_for(Board, _).

% render_state(State)
render_state(state(Board, _)) :-
    nl,
    row(Board, [1,2,3]),
    fmt_sep,
    row(Board, [4,5,6]),
    fmt_sep,
    row(Board, [7,8,9]),
    nl.

% row(Board, Positions)
row(Board, [P1,P2,P3]) :-
    nth1(P1,Board,V1), disp(V1,D1),
    nth1(P2,Board,V2), disp(V2,D2),
    nth1(P3,Board,V3), disp(V3,D3),
    format(' ~w | ~w | ~w ~n', [D1,D2,D3]).

% disp(Value, Display)
disp(empty, '_').
disp(x, x).
disp(o, o).

% fmt_sep
fmt_sep :- format('---+---+---~n', []).

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, move(5), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).