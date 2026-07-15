:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Board, CurrentPlayer). Board is flat list of 9 positions numbered 1..9; each entry empty, x, or o. CurrentPlayer is x or o.
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% replace_at(Board, Position, Player, NewBoard)
replace_at(Board, Pos, Player, NewBoard) :-
    set_nth1(Pos, Board, Player, NewBoard).

% switch_player(Current, Next)
switch_player(x, o).
switch_player(o, x).

% check_line(Board, I1, I2, I3, Player)
check_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

% win_on_board(Board, Player)
win_on_board(Board, Player) :-
    check_line(Board, 1, 2, 3, Player);
    check_line(Board, 4, 5, 6, Player);
    check_line(Board, 7, 8, 9, Player);
    check_line(Board, 1, 4, 7, Player);
    check_line(Board, 2, 5, 8, Player);
    check_line(Board, 3, 6, 9, Player);
    check_line(Board, 1, 5, 9, Player);
    check_line(Board, 3, 5, 7, Player).

% board_full(Board)
board_full(Board) :-
    \+ member(empty, Board).

% initial_state(State)
initial_state(state([empty,empty,empty,empty,empty,empty,empty,empty,empty], x)).

% current_player(State, P)
current_player(state(_, P), P).

% legal_move(State, Move)
legal_move(state(Board, Player), move(Pos)) :-
    \+ game_over(state(Board, Player), _),
    nth1(Pos, Board, empty).

% apply_move(State, Move, NewState)
apply_move(state(Board, Player), move(Pos), state(NewBoard, NextPlayer)) :-
    \+ game_over(state(Board, Player), _),
    nth1(Pos, Board, empty),
    replace_at(Board, Pos, Player, NewBoard),
    switch_player(Player, NextPlayer).

% game_over(State, Winner)
game_over(state(Board, _), Player) :-
    win_on_board(Board, Player).
game_over(state(Board, _), draw) :-
    \+ win_on_board(Board, _),
    board_full(Board).

% render_state(State)
render_state(state(Board, _)) :-
    render_cells(Board, 1).

% Helper for render_state: render_cells(Board, Index)
render_cells([], _) :-
    nl.
render_cells([C|Rest], Index) :-
    ( C = empty -> format('. ') ; ( C = x -> format('x ') ; format('o ') ) ),
    ( Index mod 3 =:= 0 -> nl ; true ),
    NextIndex is Index + 1,
    render_cells(Rest, NextIndex).