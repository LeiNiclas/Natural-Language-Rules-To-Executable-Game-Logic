:- use_module(library(lists)).

% Representation: state(Board, CurrentPlayer)
% Board is a flat list of 9 atoms (empty, x, o), positions 1..9.

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

initial_state(state([empty,empty,empty,
                     empty,empty,empty,
                     empty,empty,empty], x)).

current_player(state(_,P), P).

legal_move(state(Board,_), move(Position)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty).

apply_move(state(Board, Current), move(Position), state(NewBoard, NewCurrent)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty),
    set_nth1(Position, Board, Current, NewBoard),
    (Current = x -> NewCurrent = o ; NewCurrent = x).

win(Board, Player) :-
    ( nth1(1,Board,Player), nth1(2,Board,Player), nth1(3,Board,Player)
    ; nth1(4,Board,Player), nth1(5,Board,Player), nth1(6,Board,Player)
    ; nth1(7,Board,Player), nth1(8,Board,Player), nth1(9,Board,Player)
    ; nth1(1,Board,Player), nth1(4,Board,Player), nth1(7,Board,Player)
    ; nth1(2,Board,Player), nth1(5,Board,Player), nth1(8,Board,Player)
    ; nth1(3,Board,Player), nth1(6,Board,Player), nth1(9,Board,Player)
    ; nth1(1,Board,Player), nth1(5,Board,Player), nth1(9,Board,Player)
    ; nth1(3,Board,Player), nth1(5,Board,Player), nth1(7,Board,Player)
    ),
    Player \= empty.

game_over(state(Board,_), Player) :-
    win(Board, Player).
game_over(state(Board,_), draw) :-
    \+ member(empty, Board),
    \+ win(Board, _).

render_state(state(Board,_)) :-
    render_row(1, Board),
    render_row(4, Board),
    render_row(7, Board).

render_row(Index, Board) :-
    nth1(Index, Board, C1), display_cell(C1), format(' '),
    I2 is Index + 1, nth1(I2, Board, C2), display_cell(C2), format(' '),
    I3 is Index + 2, nth1(I3, Board, C3), display_cell(C3), format('~n').

display_cell(empty) :- format('.').
display_cell(x)     :- format('X').
display_cell(o)     :- format('O').