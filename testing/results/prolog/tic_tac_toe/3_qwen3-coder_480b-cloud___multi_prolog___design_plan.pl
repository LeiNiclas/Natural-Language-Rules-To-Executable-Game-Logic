:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, CurrentPlayer)
initial_state(state([empty, empty, empty, empty, empty, empty, empty, empty, empty], x)).

current_player(state(_, P), P).

% legal_move(State, Move)
legal_move(state(Board, _), move(Position)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty).

% apply_move(State, Move, NewState)
apply_move(state(Board, CurrentPlayer), move(Position), state(NewBoard, NextPlayer)) :-
    between(1, 9, Position),
    nth1(Position, Board, empty),
    set_nth1(Position, Board, CurrentPlayer, NewBoard),
    (CurrentPlayer = x -> NextPlayer = o ; NextPlayer = x).

% game_over(State, Winner)
game_over(state(Board, _), Winner) :-
    check_win(Board, Winner),
    Winner \= empty.
game_over(state(Board, _), draw) :-
    \+ member(empty, Board),
    \+ check_win(Board, _).

% check_win(Board, Player)
check_win(Board, Player) :-
    check_line(Board, 1, 2, 3, Player) ;
    check_line(Board, 4, 5, 6, Player) ;
    check_line(Board, 7, 8, 9, Player) ;
    check_line(Board, 1, 4, 7, Player) ;
    check_line(Board, 2, 5, 8, Player) ;
    check_line(Board, 3, 6, 9, Player) ;
    check_line(Board, 1, 5, 9, Player) ;
    check_line(Board, 3, 5, 7, Player).

% check_line(Board, I1, I2, I3, Player)
check_line(Board, I1, I2, I3, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    Player \= empty.

% render_state(State)
render_state(state(Board, CurrentPlayer)) :-
    render_board(Board),
    format('Current player: ~w~n', [CurrentPlayer]).

% render_board(Board)
render_board(Board) :-
    render_row(Board, 1, 3),
    render_row(Board, 4, 6),
    render_row(Board, 7, 9).

% render_row(Board, Start, End)
render_row(Board, Start, End) :-
    forall(between(Start, End, I),
           (nth1(I, Board, Cell),
            (Cell = empty -> format('~d:. ', [I]) ; format('~d:~w ', [I, Cell])))),
    nl.