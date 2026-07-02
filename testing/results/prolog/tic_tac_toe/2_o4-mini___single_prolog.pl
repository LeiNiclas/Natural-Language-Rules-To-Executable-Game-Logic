:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Board,CurrentPlayer)
% Board is a flat list of 9 cells: empty | x | o, indexed 1..9 row-major.
% CurrentPlayer is the atom x or o.

set_nth1(1,[_|T],V,[V|T]).
set_nth1(N,[H|T],V,[H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1,T,V,R).

initial_state(state([empty,empty,empty,
                     empty,empty,empty,
                     empty,empty,empty],
                    x)).

current_player(state(_,P),P).

legal_move(state(Board,_),move(Position)) :-
    between(1,9,Position),
    nth1(Position,Board,empty).

apply_move(state(Board,Player),move(Position),state(NewBoard,NextPlayer)) :-
    legal_move(state(Board,Player),move(Position)),
    set_nth1(Position,Board,Player,NewBoard),
    ( Player = x -> NextPlayer = o ; NextPlayer = x ).

winning(Board,Player) :-
    nth1(1,Board,Player),
    nth1(2,Board,Player),
    nth1(3,Board,Player),
    Player \= empty.
winning(Board,Player) :-
    nth1(4,Board,Player),
    nth1(5,Board,Player),
    nth1(6,Board,Player),
    Player \= empty.
winning(Board,Player) :-
    nth1(7,Board,Player),
    nth1(8,Board,Player),
    nth1(9,Board,Player),
    Player \= empty.
winning(Board,Player) :-
    nth1(1,Board,Player),
    nth1(4,Board,Player),
    nth1(7,Board,Player),
    Player \= empty.
winning(Board,Player) :-
    nth1(2,Board,Player),
    nth1(5,Board,Player),
    nth1(8,Board,Player),
    Player \= empty.
winning(Board,Player) :-
    nth1(3,Board,Player),
    nth1(6,Board,Player),
    nth1(9,Board,Player),
    Player \= empty.
winning(Board,Player) :-
    nth1(1,Board,Player),
    nth1(5,Board,Player),
    nth1(9,Board,Player),
    Player \= empty.
winning(Board,Player) :-
    nth1(3,Board,Player),
    nth1(5,Board,Player),
    nth1(7,Board,Player),
    Player \= empty.

game_over(state(Board,_),Winner) :-
    winning(Board,Winner).
game_over(state(Board,_),draw) :-
    \+ member(empty,Board),
    \+ winning(Board,_).

render_state(state(Board,_)) :-
    render_row(Board,1),
    render_row(Board,4),
    render_row(Board,7).

render_row(Board,I) :-
    nth1(I,Board,C1),
    J is I + 1,
    K is I + 2,
    nth1(J,Board,C2),
    nth1(K,Board,C3),
    render_cell(C1), format(' '),
    render_cell(C2), format(' '),
    render_cell(C3), nl.

render_cell(empty) :- format('.').
render_cell(x) :- format('X').
render_cell(o) :- format('O').