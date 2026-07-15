:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).
current_player(state(_, P), P).

legal_move(state(Board, _), place(Pos)) :-
    between(1, 9, Pos),
    nth1(Pos, Board, empty).

switch_player(x, o).
switch_player(o, x).

apply_move(state(Board, P), place(Pos), state(NewBoard, NextP)) :-
    between(1, 9, Pos),
    nth1(Pos, Board, empty),
    set_nth1(Pos, Board, P, NewBoard),
    switch_player(P, NextP).

winning_triplet(1,2,3).
winning_triplet(4,5,6).
winning_triplet(7,8,9).
winning_triplet(1,4,7).
winning_triplet(2,5,8).
winning_triplet(3,6,9).
winning_triplet(1,5,9).
winning_triplet(3,5,7).

game_over(state(Board, _), P) :-
    winning_triplet(A, B, C),
    nth1(A, Board, P),
    P \= empty,
    nth1(B, Board, P),
    nth1(C, Board, P),
    !.
game_over(state(Board, _), draw) :-
    \+ member(empty, Board).

% render_state prints the board with indices and current player
render_state(state(Board, P)) :-
    render_rows(Board, 1),
    format("Current player: ~w~n", [P]).

% render_rows prints each row starting at Pos
render_rows(_, Pos) :-
    Pos > 9, !.
render_rows(Board, Pos) :-
    render_row(Board, Pos),
    Next is Pos + 3,
    render_rows(Board, Next).

% render_row prints positions Pos, Pos+1, Pos+2
render_row(Board, Pos) :-
    Pos2 is Pos + 1,
    Pos3 is Pos + 2,
    nth1(Pos, Board, C1),
    nth1(Pos2, Board, C2),
    nth1(Pos3, Board, C3),
    cell_code(C1, Code1),
    cell_code(C2, Code2),
    cell_code(C3, Code3),
    format("~d:~c ~d:~c ~d:~c~n", [Pos, Code1, Pos2, Code2, Pos3, Code3]).

% cell_code maps board contents to ASCII codes for printing
cell_code(empty, 46).
cell_code(x, 120).
cell_code(o, 111).