:- use_module(library(lists)).

% Flat list of 9 cells: Board = [Cell1,...,Cell9], index 1=top-left, 9=bottom-right.
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Pos)) :-
    between(1, 9, Pos),
    nth1(Pos, Board, empty).

apply_move(state(Board, CP), move(Pos), state(NewBoard, NewCP)) :-
    nth1(Pos, Board, empty),
    set_nth1(Pos, Board, CP, NewBoard),
    next_player(CP, NewCP).

next_player(x, o).
next_player(o, x).

% Winning lines for Tic-Tac-Toe
win(Board, Player) :-
    nth1(1, Board, Player), nth1(2, Board, Player), nth1(3, Board, Player), Player \= empty.
win(Board, Player) :-
    nth1(4, Board, Player), nth1(5, Board, Player), nth1(6, Board, Player), Player \= empty.
win(Board, Player) :-
    nth1(7, Board, Player), nth1(8, Board, Player), nth1(9, Board, Player), Player \= empty.
win(Board, Player) :-
    nth1(1, Board, Player), nth1(4, Board, Player), nth1(7, Board, Player), Player \= empty.
win(Board, Player) :-
    nth1(2, Board, Player), nth1(5, Board, Player), nth1(8, Board, Player), Player \= empty.
win(Board, Player) :-
    nth1(3, Board, Player), nth1(6, Board, Player), nth1(9, Board, Player), Player \= empty.
win(Board, Player) :-
    nth1(1, Board, Player), nth1(5, Board, Player), nth1(9, Board, Player), Player \= empty.
win(Board, Player) :-
    nth1(3, Board, Player), nth1(5, Board, Player), nth1(7, Board, Player), Player \= empty.

game_over(state(Board, _), Winner) :-
    win(Board, Winner).
game_over(state(Board, _), draw) :-
    \+ member(empty, Board),
    \+ win(Board, _).

% Print a cell: empty as '.', x as 'x', o as 'o'
print_cell(empty) :- format('. ').
print_cell(x) :- format('x ').
print_cell(o) :- format('o ').

render_state(state(Board, _)) :-
    Board = [A,B,C,D,E,F,G,H,I],
    print_cell(A), print_cell(B), print_cell(C), nl,
    print_cell(D), print_cell(E), print_cell(F), nl,
    print_cell(G), print_cell(H), print_cell(I), nl.