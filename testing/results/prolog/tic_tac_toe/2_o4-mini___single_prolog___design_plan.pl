:- use_module(library(lists)).

% Flat list representation: Board = [Cell1...Cell9], each empty, x, or o.
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% switch_player(Current, Next): alternate x and o
switch_player(x, o).
switch_player(o, x).

% three_in_line(Board, I1, I2, I3, Player): check positions hold Player
three_in_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

% win(Board, Player): any winning line
win(Board, Player) :-
    three_in_line(Board, 1, 2, 3, Player).
win(Board, Player) :-
    three_in_line(Board, 4, 5, 6, Player).
win(Board, Player) :-
    three_in_line(Board, 7, 8, 9, Player).
win(Board, Player) :-
    three_in_line(Board, 1, 4, 7, Player).
win(Board, Player) :-
    three_in_line(Board, 2, 5, 8, Player).
win(Board, Player) :-
    three_in_line(Board, 3, 6, 9, Player).
win(Board, Player) :-
    three_in_line(Board, 1, 5, 9, Player).
win(Board, Player) :-
    three_in_line(Board, 3, 5, 7, Player).

% full(Board): no empty cells
full(Board) :-
    \+ member(empty, Board).

% initial_state(State): starting empty board, x to move
initial_state(state(
    [empty, empty, empty,
     empty, empty, empty,
     empty, empty, empty],
    x)).

% current_player(State, P): P is to move in State
current_player(state(_, P), P).

% legal_move(State, move(Pos)): Pos between 1-9 and cell is empty
legal_move(state(Board, _), move(Pos)) :-
    integer(Pos),
    Pos >= 1, Pos =< 9,
    nth1(Pos, Board, empty).

% apply_move(State, move(Pos), NewState): place mark and switch player
apply_move(state(Board, Current), move(Pos), state(NewBoard, Next)) :-
    integer(Pos),
    Pos >= 1, Pos =< 9,
    nth1(Pos, Board, empty),
    set_nth1(Pos, Board, Current, NewBoard),
    switch_player(Current, Next).

% game_over(State, Winner): true when win or draw
game_over(state(Board, _), Winner) :-
    win(Board, Winner).
game_over(state(Board, _), draw) :-
    \+ win(Board, _),
    full(Board).

% render_state(State): print the board to stdout
render_state(state(Board, _)) :-
    render_rows(Board, 1).

% render_rows(Board, Row): print each row
render_rows(Board, Row) :-
    Row =< 3,
    Start is (Row - 1) * 3 + 1,
    nth1(Start,     Board, C1),
    nth1(Start + 1, Board, C2),
    nth1(Start + 2, Board, C3),
    print_cell(C1), format(' '),
    print_cell(C2), format(' '),
    print_cell(C3), nl,
    NextRow is Row + 1,
    render_rows(Board, NextRow).
render_rows(_, Row) :-
    Row > 3.

% print_cell(C): print symbol for each cell
print_cell(C) :-
    ( C = empty -> format('.')
    ; C = x     -> format('X')
    ; C = o     -> format('O')
    ).