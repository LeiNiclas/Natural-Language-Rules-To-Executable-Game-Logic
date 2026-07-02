:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper to set Nth element of a list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% Helper to set a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Determine piece color
piece_color(white_king, white).
piece_color(white_queen, white).
piece_color(white_rook, white).
piece_color(white_bishop, white).
piece_color(white_knight, white).
piece_color(white_pawn, white).
piece_color(black_king, black).
piece_color(black_queen, black).
piece_color(black_rook, black).
piece_color(black_bishop, black).
piece_color(black_knight, black).
piece_color(black_pawn, black).

% Opponent mapping
opponent(white, black).
opponent(black, white).

% Update castling rights on king or rook move
update_castling(Rights, _, _, white_king, NewRights) :-
    delete(Rights, white_kingside, R1),
    delete(R1, white_queenside, NewRights).
update_castling(Rights, 8, 1, white_rook, NewRights) :-
    delete(Rights, white_queenside, NewRights).
update_castling(Rights, 8, 8, white_rook, NewRights) :-
    delete(Rights, white_kingside, NewRights).
update_castling(Rights, _, _, black_king, NewRights) :-
    delete(Rights, black_kingside, R2),
    delete(R2, black_queenside, NewRights).
update_castling(Rights, 1, 1, black_rook, NewRights) :-
    delete(Rights, black_queenside, NewRights).
update_castling(Rights, 1, 8, black_rook, NewRights) :-
    delete(Rights, black_kingside, NewRights).
update_castling(Rights, _, _, _, Rights).

% Initial chess position
initial_state(state(
    [
      [black_rook,black_knight,black_bishop,black_queen,black_king,black_bishop,black_knight,black_rook],
      [black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn],
      [white_rook,white_knight,white_bishop,white_queen,white_king,white_bishop,white_knight,white_rook]
    ],
    white,
    [white_kingside,white_queenside,black_kingside,black_queenside],
    null,
    0,
    1
)).

% Current player is the turn field
current_player(state(_, Turn, _, _, _, _), Turn).

% Legal moves: any piece of current player to any empty or opponent square
legal_move(state(Board, Turn, _, _, _, _),
           move(FromRow, FromCol, ToRow, ToCol, none)) :-
    between(1,8,FromRow),
    between(1,8,FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    Piece \= empty,
    piece_color(Piece, Turn),
    between(1,8,ToRow),
    between(1,8,ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, Target),
    ( Target = empty
    ; piece_color(Target, Opp), opponent(Turn, Opp)
    ).

% Apply a move
apply_move(state(Board, Turn, Rights, _, HMC, FN),
           move(FromRow, FromCol, ToRow, ToCol, none),
           state(NewBoard3, NextTurn, NewRights, null, NewHMC, NewFN)) :-
    nth1(FromRow, Board, FRList),
    nth1(FromCol, FRList, Piece),
    nth1(ToRow, Board, TRList),
    nth1(ToCol, TRList, Captured),
    set_cell(FromRow, FromCol, Board, empty, Board1),
    set_cell(ToRow, ToCol, Board1, Piece, NewBoard3),
    update_castling(Rights, FromRow, FromCol, Piece, NewRights),
    ( Piece = white_pawn ; Piece = black_pawn ; Captured \= empty ->
        NewHMC = 0
    ;   NewHMC is HMC + 1
    ),
    ( Turn = black -> NewFN is FN + 1 ; NewFN = FN ),
    opponent(Turn, NextTurn).

% Game over when a king is captured
game_over(state(Board, _, _, _, _, _), black) :-
    \+ ( member(Row, Board), member(white_king, Row) ).
game_over(state(Board, _, _, _, _, _), white) :-
    \+ ( member(Row, Board), member(black_king, Row) ).

% Render state to stdout
render_state(state(Board, Turn, _, _, _, _)) :-
    maplist(render_row, Board),
    format("Turn: ~w~n", [Turn]).

% Render a single row
render_row(Row) :-
    maplist(render_cell, Row),
    nl.

% Render a single cell with abbreviation
render_cell(Cell) :-
    ( Cell = empty         -> C = '.'
    ; Cell = white_king    -> C = 'K'
    ; Cell = white_queen   -> C = 'Q'
    ; Cell = white_rook    -> C = 'R'
    ; Cell = white_bishop  -> C = 'B'
    ; Cell = white_knight  -> C = 'N'
    ; Cell = white_pawn    -> C = 'P'
    ; Cell = black_king    -> C = 'k'
    ; Cell = black_queen   -> C = 'q'
    ; Cell = black_rook    -> C = 'r'
    ; Cell = black_bishop  -> C = 'b'
    ; Cell = black_knight  -> C = 'n'
    ; Cell = black_pawn    -> C = 'p'
    ; otherwise            -> C = '?'
    ),
    format("~w ", [C]).