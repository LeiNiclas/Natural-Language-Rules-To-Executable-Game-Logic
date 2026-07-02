:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% initial game state
initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

% current player to move
current_player(state(_, P), P).

% legal_move(State, Move) is true if Move is a legal placement in State
% Move is of the form place(Player, Position)
legal_move(state(Board, Player), place(Player, Position)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty).

% apply_move(State, Move, NewState) applies Move producing NewState or fails if illegal
apply_move(state(Board, Player), place(Player, Position), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), place(Player, Position)),
    set_nth1(Position, Board, Player, NewBoard),
    (Player = x -> NextPlayer = o ; NextPlayer = x).

% game_over(State, Winner) succeeds if a player has won or if it's a draw

% win conditions
game_over(state(Board,_), Winner) :-
    nth1(1, Board, X), X \= empty,
    nth1(2, Board, X), nth1(3, Board, X),
    Winner = X.
game_over(state(Board,_), Winner) :-
    nth1(4, Board, X), X \= empty,
    nth1(5, Board, X), nth1(6, Board, X),
    Winner = X.
game_over(state(Board,_), Winner) :-
    nth1(7, Board, X), X \= empty,
    nth1(8, Board, X), nth1(9, Board, X),
    Winner = X.
game_over(state(Board,_), Winner) :-
    nth1(1, Board, X), X \= empty,
    nth1(4, Board, X), nth1(7, Board, X),
    Winner = X.
game_over(state(Board,_), Winner) :-
    nth1(2, Board, X), X \= empty,
    nth1(5, Board, X), nth1(8, Board, X),
    Winner = X.
game_over(state(Board,_), Winner) :-
    nth1(3, Board, X), X \= empty,
    nth1(6, Board, X), nth1(9, Board, X),
    Winner = X.
game_over(state(Board,_), Winner) :-
    nth1(1, Board, X), X \= empty,
    nth1(5, Board, X), nth1(9, Board, X),
    Winner = X.
game_over(state(Board,_), Winner) :-
    nth1(3, Board, X), X \= empty,
    nth1(5, Board, X), nth1(7, Board, X),
    Winner = X.

% draw condition
game_over(state(Board,_), draw) :-
    \+ member(empty, Board).

% render_state(State): print board and current player
render_state(state(Board,Player)) :-
    render_row(Board,1),
    render_row(Board,4),
    render_row(Board,7),
    format('Current player: ~w~n', [Player]).

% render_row(Board, Base): prints a row starting at Base position
render_row(Board,Base) :-
    Pos1 = Base,
    Pos2 is Base+1,
    Pos3 is Base+2,
    nth1(Pos1,Board,C1), cell_char(C1,Ch1),
    nth1(Pos2,Board,C2), cell_char(C2,Ch2),
    nth1(Pos3,Board,C3), cell_char(C3,Ch3),
    format('~w:~w ', [Pos1,Ch1]),
    format('~w:~w ', [Pos2,Ch2]),
    format('~w:~w~n', [Pos3,Ch3]).

% cell_char(Content, Char): maps board content to display char
cell_char(empty,'.').
cell_char(X,X).