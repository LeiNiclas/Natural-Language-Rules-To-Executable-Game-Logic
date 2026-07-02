:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, CurrentPlayer)
initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).
current_player(state(_, P), P).

% legal_move(State, Move)
legal_move(state(Board, _), place(Player, Position)) :-
    nth1(Position, Board, empty),
    Position >= 1,
    Position =< 9,
    current_player(state(Board, Player), Player).

% apply_move(State, Move, NewState)
apply_move(state(Board, CurrentPlayer), place(Player, Position), state(NewBoard, NextPlayer)) :-
    Position >= 1,
    Position =< 9,
    nth1(Position, Board, empty),
    current_player(state(Board, Player), Player),
    set_nth1(Position, Board, Player, NewBoard),
    (Player = x -> NextPlayer = o ; NextPlayer = x).

% game_over(State, Winner)
game_over(state(Board, _), Winner) :-
    % Check rows
    (nth1(1,Board,X), nth1(2,Board,X), nth1(3,Board,X), X \= empty -> Winner = X ;
     nth1(4,Board,X), nth1(5,Board,X), nth1(6,Board,X), X \= empty -> Winner = X ;
     nth1(7,Board,X), nth1(8,Board,X), nth1(9,Board,X), X \= empty -> Winner = X ;
     % Check columns
     nth1(1,Board,X), nth1(4,Board,X), nth1(7,Board,X), X \= empty -> Winner = X ;
     nth1(2,Board,X), nth1(5,Board,X), nth1(8,Board,X), X \= empty -> Winner = X ;
     nth1(3,Board,X), nth1(6,Board,X), nth1(9,Board,X), X \= empty -> Winner = X ;
     % Check diagonals
     nth1(1,Board,X), nth1(5,Board,X), nth1(9,Board,X), X \= empty -> Winner = X ;
     nth1(3,Board,X), nth1(5,Board,X), nth1(7,Board,X), X \= empty -> Winner = X ;
     % Check draw
     \+ member(empty, Board) -> Winner = draw).

% render_state(State)
render_state(state(Board, CurrentPlayer)) :-
    format("Current board:~n"),
    render_board(Board),
    format("Current player: ~w~n", [CurrentPlayer]).

render_board([C1,C2,C3,C4,C5,C6,C7,C8,C9]) :-
    render_cell(C1, 1), format(' '), render_cell(C2, 2), format(' '), render_cell(C3, 3), format('~n'),
    render_cell(C4, 4), format(' '), render_cell(C5, 5), format(' '), render_cell(C6, 6), format('~n'),
    render_cell(C7, 7), format(' '), render_cell(C8, 8), format(' '), render_cell(C9, 9), format('~n').

render_cell(C, N) :-
    (C = empty ->
        format('~w:', [N])
    ;
        format('~w:', [C])
    ).