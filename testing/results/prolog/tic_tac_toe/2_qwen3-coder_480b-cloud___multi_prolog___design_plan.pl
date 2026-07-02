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
    (Winner = x; Winner = o),
    check_win(Board, Winner).

game_over(state(Board, _), draw) :-
    check_draw(Board).

check_win(Board, Player) :-
    Player \= empty,
    (   % Rows
        (nth1(1, Board, Player), nth1(2, Board, Player), nth1(3, Board, Player))
    ;   (nth1(4, Board, Player), nth1(5, Board, Player), nth1(6, Board, Player))
    ;   (nth1(7, Board, Player), nth1(8, Board, Player), nth1(9, Board, Player))
    ;   % Columns
        (nth1(1, Board, Player), nth1(4, Board, Player), nth1(7, Board, Player))
    ;   (nth1(2, Board, Player), nth1(5, Board, Player), nth1(8, Board, Player))
    ;   (nth1(3, Board, Player), nth1(6, Board, Player), nth1(9, Board, Player))
    ;   % Diagonals
        (nth1(1, Board, Player), nth1(5, Board, Player), nth1(9, Board, Player))
    ;   (nth1(3, Board, Player), nth1(5, Board, Player), nth1(7, Board, Player))
    ).

check_draw(Board) :-
    \+ member(empty, Board),
    \+ check_win(Board, _).

% render_state(State)
render_state(state(Board, CurrentPlayer)) :-
    render_board(Board),
    format('Current player: ~w~n', [CurrentPlayer]).

render_board(Board) :-
    render_row(Board, 1).

render_row([], _).
render_row([H|T], Pos) :-
    Row is (Pos - 1) // 3 + 1,
    render_cell(H, Pos),
    (Pos mod 3 =:= 0 ->
        (Row =:= 3 -> nl ; (nl, render_row(T, Pos+1)))
    ;
        format(' ', []),
        render_row(T, Pos+1)
    ).

render_cell(C, Pos) :-
    (C = empty ->
        format('~w:.', [Pos])
    ;
        format('~w:~w', [Pos, C])
    ).