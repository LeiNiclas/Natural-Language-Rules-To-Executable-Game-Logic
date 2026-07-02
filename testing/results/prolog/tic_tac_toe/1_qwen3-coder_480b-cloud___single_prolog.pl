:- use_module(library(lists)).
:- use_module(library(apply)).

% Flat list representation for 3x3 board
% Board = [P1,P2,P3,P4,P5,P6,P7,P8,P9]
% Index 1 = top-left, 9 = bottom-right
% Players: x, o
% Empty cells: empty

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

current_player(state(_, P), P).

legal_move(state(Board, Player), Position) :-
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
    % Check rows
    (nth1(1, Board, X), nth1(2, Board, X), nth1(3, Board, X), X \= empty ->
        Winner = X
    ; nth1(4, Board, X), nth1(5, Board, X), nth1(6, Board, X), X \= empty ->
        Winner = X
    ; nth1(7, Board, X), nth1(8, Board, X), nth1(9, Board, X), X \= empty ->
        Winner = X
    % Check columns
    ; nth1(1, Board, X), nth1(4, Board, X), nth1(7, Board, X), X \= empty ->
        Winner = X
    ; nth1(2, Board, X), nth1(5, Board, X), nth1(8, Board, X), X \= empty ->
        Winner = X
    ; nth1(3, Board, X), nth1(6, Board, X), nth1(9, Board, X), X \= empty ->
        Winner = X
    % Check diagonals
    ; nth1(1, Board, X), nth1(5, Board, X), nth1(9, Board, X), X \= empty ->
        Winner = X
    ; nth1(3, Board, X), nth1(5, Board, X), nth1(7, Board, X), X \= empty ->
        Winner = X
    % Check draw
    ; \+ member(empty, Board) ->
        Winner = draw
    ).

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