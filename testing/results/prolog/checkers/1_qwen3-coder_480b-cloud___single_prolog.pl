:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list 8x8
% Rows 1-8 (top to bottom), Cols 1-8 (left to right)
% Pieces: empty, light_man, dark_man, light_king, dark_king

% Helper to update a cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial board state
initial_board([
    [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
    [dark_man, empty, dark_man, empty, dark_man, empty, dark_man, empty],
    [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [light_man, empty, light_man, empty, light_man, empty, light_man, empty],
    [empty, light_man, empty, light_man, empty, light_man, empty, light_man],
    [light_man, empty, light_man, empty, light_man, empty, light_man, empty]
]).

initial_state(state(Board, dark)) :- initial_board(Board).

current_player(state(_, Player), Player).

% Legal moves
legal_move(State, move(FromRow, FromCol, ToRow, ToCol)) :-
    State = state(Board, Player),
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    abs(ToRow - FromRow) =:= abs(ToCol - FromCol),
    (   abs(ToRow - FromRow) =:= 1
    ->  (   Piece = dark_man -> ToRow =:= FromRow + 1
        ;   Piece = light_man -> ToRow =:= FromRow - 1
        ;   true
        )
    ;   abs(ToRow - FromRow) =:= 2
    ->  MidRow is (FromRow + ToRow) // 2,
        MidCol is (FromCol + ToCol) // 2,
        nth1(MidRow, Board, MidRowList),
        nth1(MidCol, MidRowList, MidPiece),
        opponent_piece(Player, MidPiece)
    ),
    (   has_capture_move(State)
    ->  abs(ToRow - FromRow) =:= 2
    ;   true
    ).

player_piece(light, light_man).
player_piece(light, light_king).
player_piece(dark, dark_man).
player_piece(dark, dark_king).

opponent_piece(light, dark_man).
opponent_piece(light, dark_king).
opponent_piece(dark, light_man).
opponent_piece(dark, light_king).

has_capture_move(state(Board, Player)) :-
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),
    ToRow1 is FromRow + 2,
    ToCol1 is FromCol + 2,
    valid_capture(Board, FromRow, FromCol, ToRow1, ToCol1, Player),
    !.
has_capture_move(state(Board, Player)) :-
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),
    ToRow2 is FromRow + 2,
    ToCol2 is FromCol - 2,
    valid_capture(Board, FromRow, FromCol, ToRow2, ToCol2, Player),
    !.
has_capture_move(state(Board, Player)) :-
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),
    ToRow3 is FromRow - 2,
    ToCol3 is FromCol + 2,
    valid_capture(Board, FromRow, FromCol, ToRow3, ToCol3, Player),
    !.
has_capture_move(state(Board, Player)) :-
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),
    ToRow4 is FromRow - 2,
    ToCol4 is FromCol - 2,
    valid_capture(Board, FromRow, FromCol, ToRow4, ToCol4, Player),
    !.

valid_capture(Board, FromRow, FromCol, ToRow, ToCol, Player) :-
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    MidRow is (FromRow + ToRow) // 2,
    MidCol is (FromCol + ToCol) // 2,
    nth1(MidRow, Board, MidRowList),
    nth1(MidCol, MidRowList, MidPiece),
    opponent_piece(Player, MidPiece).

% Apply move
apply_move(State, move(FromRow, FromCol, ToRow, ToCol), NewState) :-
    State = state(Board, Player),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    abs(ToRow - FromRow) =:= abs(ToCol - FromCol),
    (   abs(ToRow - FromRow) =:= 1
    ->  (   Piece = dark_man -> ToRow =:= FromRow + 1
        ;   Piece = light_man -> ToRow =:= FromRow - 1
        ;   true
        ),
        set_cell(FromRow, FromCol, Board, empty, Board1),
        set_cell(ToRow, ToCol, Board1, Piece, Board2),
        promote_if_needed(ToRow, Piece, NewPiece),
        set_cell(ToRow, ToCol, Board2, NewPiece, FinalBoard),
        next_player(Player, NextPlayer),
        NewState = state(FinalBoard, NextPlayer)
    ;   abs(ToRow - FromRow) =:= 2
    ->  MidRow is (FromRow + ToRow) // 2,
        MidCol is (FromCol + ToCol) // 2,
        nth1(MidRow, Board, MidRowList),
        nth1(MidCol, MidRowList, MidPiece),
        opponent_piece(Player, MidPiece),
        set_cell(FromRow, FromCol, Board, empty, Board1),
        set_cell(MidRow, MidCol, Board1, empty, Board2),
        set_cell(ToRow, ToCol, Board2, Piece, Board3),
        promote_if_needed(ToRow, Piece, NewPiece),
        set_cell(ToRow, ToCol, Board3, NewPiece, FinalBoard),
        (   has_further_jumps(FinalBoard, ToRow, ToCol, Player)
        ->  NewState = state(FinalBoard, Player)
        ;   next_player(Player, NextPlayer),
            NewState = state(FinalBoard, NextPlayer)
        )
    ),
    (   has_capture_move(State)
    ->  abs(ToRow - FromRow) =:= 2
    ;   true
    ).

promote_if_needed(1, light_man, light_king) :- !.
promote_if_needed(8, dark_man, dark_king) :- !.
promote_if_needed(_, Piece, Piece).

has_further_jumps(Board, Row, Col, Player) :-
    ToRow1 is Row + 2,
    ToCol1 is Col + 2,
    valid_capture(Board, Row, Col, ToRow1, ToCol1, Player),
    !.
has_further_jumps(Board, Row, Col, Player) :-
    ToRow2 is Row + 2,
    ToCol2 is Col - 2,
    valid_capture(Board, Row, Col, ToRow2, ToCol2, Player),
    !.
has_further_jumps(Board, Row, Col, Player) :-
    ToRow3 is Row - 2,
    ToCol3 is Col + 2,
    valid_capture(Board, Row, Col, ToRow3, ToCol3, Player),
    !.
has_further_jumps(Board, Row, Col, Player) :-
    ToRow4 is Row - 2,
    ToCol4 is Col - 2,
    valid_capture(Board, Row, Col, ToRow4, ToCol4, Player),
    !.

next_player(light, dark).
next_player(dark, light).

% Game over conditions
game_over(State, Winner) :-
    State = state(Board, _),
    \+ (member(Row, Board), member(Piece, Row), (Piece = dark_man ; Piece = dark_king))),
    Winner = light.
game_over(State, Winner) :-
    State = state(Board, _),
    \+ (member(Row, Board), member(Piece, Row), (Piece = light_man ; Piece = light_king))),
    Winner = dark.
game_over(State, Winner) :-
    \+ legal_move(State, _),
    State = state(_, Player),
    next_player(Player, Winner).
game_over(State, draw) :-
    \+ has_capture_move(State),
    State = state(_, Player),
    next_player(Player, Opponent),
    state(Board, _) = State,
    \+ has_capture_move(state(Board, Opponent)).

% Render state
render_state(state(Board, Player)) :-
    format('Current player: ~w~n', [Player]),
    format('  1 2 3 4 5 6 7 8~n'),
    render_rows(Board, 1).

render_rows([], _).
render_rows([Row|Rows], N) :-
    format('~w ', [N]),
    render_row(Row),
    nl,
    N1 is N + 1,
    render_rows(Rows, N1).

render_row([]).
render_row([H|T]) :-
    (   H = empty -> format('. ')
    ;   H = light_man -> format('l ')
    ;   H = dark_man -> format('d ')
    ;   H = light_king -> format('L ')
    ;   H = dark_king -> format('D ')
    ),
    render_row(T).