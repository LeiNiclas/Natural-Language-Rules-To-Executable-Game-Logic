:- use_module(library(lists)).
:- use_module(library(apply)).

% Board is a flat list of 9 entries: empty, x, or o
% State representation: state(Board, CurrentPlayer)

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% Toggle player mark
next_player(x, o).
next_player(o, x).

% Check three positions for a win
win_three(Board, I1, I2, I3, P) :-
    nth1(I1, Board, P),
    nth1(I2, Board, P),
    nth1(I3, Board, P),
    P \= empty.

% All winning lines
win(Board, P) :- win_three(Board, 1,2,3, P).
win(Board, P) :- win_three(Board, 4,5,6, P).
win(Board, P) :- win_three(Board, 7,8,9, P).
win(Board, P) :- win_three(Board, 1,4,7, P).
win(Board, P) :- win_three(Board, 2,5,8, P).
win(Board, P) :- win_three(Board, 3,6,9, P).
win(Board, P) :- win_three(Board, 1,5,9, P).
win(Board, P) :- win_three(Board, 3,5,7, P).

% initial_state(State) - starting position for Tic-Tac-Toe
initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

% current_player(State, Player) - Player to move
current_player(state(_, P), P).

% legal_move(State, move(Position)) - generative for all legal moves
legal_move(state(Board, _), move(Pos)) :-
    between(1, 9, Pos),
    nth1(Pos, Board, empty).

% apply_move(State, move(Position), NewState) - apply a move
apply_move(state(Board, P), move(Pos), state(NewBoard, P2)) :-
    between(1, 9, Pos),
    nth1(Pos, Board, empty),
    set_nth1(Pos, Board, P, NewBoard),
    next_player(P, P2).

% game_over(State, Winner) - Winner is x, o, or draw
game_over(state(Board, _), Winner) :-
    win(Board, Winner), !.
game_over(state(Board, _), draw) :-
    \+ member(empty, Board).

% render_state(State) - print board to stdout
render_state(state(Board, _)) :-
    print_row(Board, 1),
    print_row(Board, 4),
    print_row(Board, 7).

% Print a row starting at Start index
print_row(Board, Start) :-
    nth1(Start, Board, C1),
    print_cell(C1),
    I2 is Start + 1,
    nth1(I2, Board, C2),
    print_cell(C2),
    I3 is Start + 2,
    nth1(I3, Board, C3),
    print_cell(C3),
    nl.

% Print a single cell: . for empty, x for x, o for o
print_cell(C) :-
    ( C = empty -> format('. ')
    ; C = x     -> format('x ')
    ; format('o ')
    ).
