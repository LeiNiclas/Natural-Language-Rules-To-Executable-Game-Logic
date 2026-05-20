:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, Turn)
% Board = list of 42 atoms (empty, player1, player2)
% Turn  = player1 | player2

initial_state(state([empty,empty,empty,empty,empty,empty,empty,
                     empty,empty,empty,empty,empty,empty,empty,
                     empty,empty,empty,empty,empty,empty,empty,
                     empty,empty,empty,empty,empty,empty,empty,
                     empty,empty,empty,empty,empty,empty,empty,
                     empty,empty,empty,empty,empty,empty,empty], player1)).

current_player(state(_, P), P).

legal_move(state(Board, _), column(Col)) :-
    between(1, 7, Col),
    % Check if column is not full
    nth1(Row, [1,2,3,4,5,6], _),
    Pos is (Row - 1) * 7 + Col,
    nth1(Pos, Board, empty), !.

apply_move(state(Board, Turn), column(Col), state(NewBoard, Next)) :-
    % Find the lowest empty spot in the column
    findall(Row, (between(1, 6, Row),
                  Pos is (Row - 1) * 7 + Col,
                  nth1(Pos, Board, empty)), Rows),
    max_list(Rows, TargetRow),
    Pos1 is (TargetRow - 1) * 7 + Col,
    set_nth1(Pos1, Board, Turn, NewBoard),
    (Turn = player1 -> Next = player2 ; Next = player1).

game_over(state(Board, _), Winner) :-
    % Check horizontal wins
    check_line(Board, 1, 2, 3, 4, player1) -> Winner = player1 ;
    check_line(Board, 1, 2, 3, 4, player2) -> Winner = player2 ;
    check_line(Board, 2, 3, 4, 5, player1) -> Winner = player1 ;
    check_line(Board, 2, 3, 4, 5, player2) -> Winner = player2 ;
    check_line(Board, 3, 4, 5, 6, player1) -> Winner = player1 ;
    check_line(Board, 3, 4, 5, 6, player2) -> Winner = player2 ;
    check_line(Board, 4, 5, 6, 7, player1) -> Winner = player1 ;
    check_line(Board, 4, 5, 6, 7, player2) -> Winner = player2 ;
    % Check vertical wins
    check_line(Board, 1, 8, 15, 22, player1) -> Winner = player1 ;
    check_line(Board, 1, 8, 15, 22, player2) -> Winner = player2 ;
    check_line(Board, 2, 9, 16, 23, player1) -> Winner = player1 ;
    check_line(Board, 2, 9, 16, 23, player2) -> Winner = player2 ;
    check_line(Board, 3, 10, 17, 24, player1) -> Winner = player1 ;
    check_line(Board, 3, 10, 17, 24, player2) -> Winner = player2 ;
    check_line(Board, 4, 11, 18, 25, player1) -> Winner = player1 ;
    check_line(Board, 4, 11, 18, 25, player2) -> Winner = player2 ;
    check_line(Board, 5, 12, 19, 26, player1) -> Winner = player1 ;
    check_line(Board, 5, 12, 19, 26, player2) -> Winner = player2 ;
    check_line(Board, 6, 13, 20, 27, player1) -> Winner = player1 ;
    check_line(Board, 6, 13, 20, 27, player2) -> Winner = player2 ;
    check_line(Board, 7, 14, 21, 28, player1) -> Winner = player1 ;
    check_line(Board, 7, 14, 21, 28, player2) -> Winner = player2 ;
    % Check diagonal (top-left to bottom-right) wins
    check_line(Board, 1, 9, 17, 25, player1) -> Winner = player1 ;
    check_line(Board, 1, 9, 17, 25, player2) -> Winner = player2 ;
    check_line(Board, 2, 10, 18, 26, player1) -> Winner = player1 ;
    check_line(Board, 2, 10, 18, 26, player2) -> Winner = player2 ;
    check_line(Board, 3, 11, 19, 27, player1) -> Winner = player1 ;
    check_line(Board, 3, 11, 19, 27, player2) -> Winner = player2 ;
    check_line(Board, 4, 12, 20, 28, player1) -> Winner = player1 ;
    check_line(Board, 4, 12, 20, 28, player2) -> Winner = player2 ;
    check_line(Board, 8, 16, 24, 32, player1) -> Winner = player1 ;
    check_line(Board, 8, 16, 24, 32, player2) -> Winner = player2 ;
    check_line(Board, 9, 17, 25, 33, player1) -> Winner = player1 ;
    check_line(Board, 9, 17, 25, 33, player2) -> Winner = player2 ;
    check_line(Board, 10, 18, 26, 34, player1) -> Winner = player1 ;
    check_line(Board, 10, 18, 26, 34, player2) -> Winner = player2 ;
    check_line(Board, 11, 19, 27, 35, player1) -> Winner = player1 ;
    check_line(Board, 11, 19, 27, 35, player2) -> Winner = player2 ;
    % Check diagonal (top-right to bottom-left) wins
    check_line(Board, 4, 10, 16, 22, player1) -> Winner = player1 ;
    check_line(Board, 4, 10, 16, 22, player2) -> Winner = player2 ;
    check_line(Board, 5, 11, 17, 23, player1) -> Winner = player1 ;
    check_line(Board, 5, 11, 17, 23, player2) -> Winner = player2 ;
    check_line(Board, 6, 12, 18, 24, player1) -> Winner = player1 ;
    check_line(Board, 6, 12, 18, 24, player2) -> Winner = player2 ;
    check_line(Board, 7, 13, 19, 25, player1) -> Winner = player1 ;
    check_line(Board, 7, 13, 19, 25, player2) -> Winner = player2 ;
    check_line(Board, 11, 17, 23, 29, player1) -> Winner = player1 ;
    check_line(Board, 11, 17, 23, 29, player2) -> Winner = player2 ;
    check_line(Board, 12, 18, 24, 30, player1) -> Winner = player1 ;
    check_line(Board, 12, 18, 24, 30, player2) -> Winner = player2 ;
    check_line(Board, 13, 19, 25, 31, player1) -> Winner = player1 ;
    check_line(Board, 13, 19, 25, 31, player2) -> Winner = player2 ;
    check_line(Board, 14, 20, 26, 32, player1) -> Winner = player1 ;
    check_line(Board, 14, 20, 26, 32, player2) -> Winner = player2 ;
    % Draw condition
    \+ member(empty, Board) -> Winner = draw.

check_line(Board, I1, I2, I3, I4, Player) :-
    nth1(I1, Board, Player),
    nth1(I2, Board, Player),
    nth1(I3, Board, Player),
    nth1(I4, Board, Player).

render_state(state(Board, Turn)) :-
    format("Current player: ~w~n", [Turn]),
    format("-----------------------------~n"),
    print_board(Board, 1).

print_board([], _).
print_board([H|T], Index) :-
    (Index mod 7 =:= 1 -> format("|") ; true),
    (H = empty -> format(" . ") ;
     H = player1 -> format(" X ") ;
     H = player2 -> format(" O ")),
    (Index mod 7 =:= 0 -> format("|~n") ; true),
    NextIndex is Index + 1,
    print_board(T, NextIndex).

% === QUERY REFERENCE ===
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, column(1), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).