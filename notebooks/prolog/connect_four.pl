:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, Player)
% Board = list of 6 rows, each row list of 7 atoms (empty|player1|player2)
% Player = player1|player2

initial_state(state(Board, player1)) :-
    length(Board, 6),
    maplist(empty_row, Board).

empty_row(Row) :-
    length(Row, 7),
    maplist(=(empty), Row).

current_player(state(_, P), P).

legal_move(state(Board, _), move(Col)) :-
    between(1, 7, Col),
    nth1(1, Board, Row1),
    nth1(Col, Row1, empty).

% Helper to find lowest empty row in a column (1=top, 6=bottom)
lowest_empty_row(Board, Col, R) :-
    lowest_empty_row_(Board, Col, 6, R).

lowest_empty_row_(_Board, _Col, 0, _) :- fail.
lowest_empty_row_(Board, Col, N, R) :-
    nth1(N, Board, Row),
    nth1(Col, Row, empty),
    R = N.
lowest_empty_row_(Board, Col, N, R) :-
    N > 1,
    N1 is N-1,
    lowest_empty_row_(Board, Col, N1, R).

next_player(player1, player2).
next_player(player2, player1).

apply_move(state(Board, Player), move(Col), state(NewBoard, NextPlayer)) :-
    lowest_empty_row(Board, Col, R),
    nth1(R, Board, OldRow),
    set_nth1(Col, OldRow, Player, NewRow),
    set_nth1(R, Board, NewRow, NewBoard),
    next_player(Player, NextPlayer).

% Win detection
win(Player, Board) :-
    horizontal_win(Player, Board) ;
    vertical_win(Player, Board) ;
    diag_down_win(Player, Board) ;
    diag_up_win(Player, Board).

horizontal_win(Player, Board) :-
    between(1, 6, R),
    between(1, 4, C),
    nth1(R, Board, Row),
    nth1(C, Row, Player),
    C1 is C + 1, nth1(C1, Row, Player),
    C2 is C + 2, nth1(C2, Row, Player),
    C3 is C + 3, nth1(C3, Row, Player).

vertical_win(Player, Board) :-
    between(1, 3, R),
    between(1, 7, C),
    nth1(R, Board, Row1), nth1(C, Row1, Player),
    R2 is R + 1, nth1(R2, Board, Row2), nth1(C, Row2, Player),
    R3 is R + 2, nth1(R3, Board, Row3), nth1(C, Row3, Player),
    R4 is R + 3, nth1(R4, Board, Row4), nth1(C, Row4, Player).

diag_down_win(Player, Board) :-
    between(1, 3, R),
    between(1, 4, C),
    nth1(R, Board, Row1), nth1(C, Row1, Player),
    R2 is R + 1, C2 is C + 1, nth1(R2, Board, Row2), nth1(C2, Row2, Player),
    R3 is R + 2, C3 is C + 2, nth1(R3, Board, Row3), nth1(C3, Row3, Player),
    R4 is R + 3, C4 is C + 3, nth1(R4, Board, Row4), nth1(C4, Row4, Player).

diag_up_win(Player, Board) :-
    between(4, 6, R),
    between(1, 4, C),
    nth1(R, Board, Row1), nth1(C, Row1, Player),
    R2 is R - 1, C2 is C + 1, nth1(R2, Board, Row2), nth1(C2, Row2, Player),
    R3 is R - 2, C3 is C + 2, nth1(R3, Board, Row3), nth1(C3, Row3, Player),
    R4 is R - 3, C4 is C + 3, nth1(R4, Board, Row4), nth1(C4, Row4, Player).

draw(Board) :-
    maplist(\+member(empty), Board),
    \+ win(player1, Board),
    \+ win(player2, Board).

game_over(state(Board, _), Winner) :-
    (   win(player1, Board) -> Winner = player1
    ;   win(player2, Board) -> Winner = player2
    ;   draw(Board) -> Winner = draw
    ).

render_state(state(Board, Player)) :-
    format("Current player: ~w~n", [Player]),
    print_board(Board).

print_board([]).
print_board([Row|Rows]) :-
    print_row(Row),
    nl,
    print_board(Rows).

print_row([]).
print_row([Cell|Rest]) :-
    (   Cell = empty -> format(" . ")
    ;   Cell = player1 -> format(" X ")
    ;   Cell = player2 -> format(" O ")
    ),
    print_row(Rest).

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, move(3), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).