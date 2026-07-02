:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, CurrentPlayer)
initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).
current_player(state(_, P), P).

% legal_move(State, Move)
legal_move(state(Board, _), place(Position)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty).

% apply_move(State, Move, NewState)
apply_move(state(Board, CurrentPlayer), place(Position), state(NewBoard, NextPlayer)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty),
    set_nth1(Position, Board, CurrentPlayer, NewBoard),
    (CurrentPlayer = x -> NextPlayer = o ; NextPlayer = x).

% game_over(State, Winner)
game_over(state(Board, _), Winner) :-
    % Check rows
    (nth1(1, Board, X), nth1(2, Board, X), nth1(3, Board, X), X \= empty -> Winner = X
    ; nth1(4, Board, X), nth1(5, Board, X), nth1(6, Board, X), X \= empty -> Winner = X
    ; nth1(7, Board, X), nth1(8, Board, X), nth1(9, Board, X), X \= empty -> Winner = X
    % Check columns
    ; nth1(1, Board, X), nth1(4, Board, X), nth1(7, Board, X), X \= empty -> Winner = X
    ; nth1(2, Board, X), nth1(5, Board, X), nth1(8, Board, X), X \= empty -> Winner = X
    ; nth1(3, Board, X), nth1(6, Board, X), nth1(9, Board, X), X \= empty -> Winner = X
    % Check diagonals
    ; nth1(1, Board, X), nth1(5, Board, X), nth1(9, Board, X), X \= empty -> Winner = X
    ; nth1(3, Board, X), nth1(5, Board, X), nth1(7, Board, X), X \= empty -> Winner = X
    ).

game_over(state(Board, _), draw) :-
    \+ member(empty, Board),
    \+ game_over(state(Board, _), _).

% render_state(State)
render_state(state(Board, CurrentPlayer)) :-
    format('Current player: ~w~n', [CurrentPlayer]),
    forall(between(1, 3, Row),
           (Start is (Row-1)*3+1,
            End is Start+2,
            forall(between(Start, End, Pos),
                   (nth1(Pos, Board, Cell),
                    (Cell = empty ->
                     format('~w:.', [Pos])
                    ;
                     format('~w:~w', [Pos, Cell])),
                    (Pos = End -> nl ; format(' ')))))).