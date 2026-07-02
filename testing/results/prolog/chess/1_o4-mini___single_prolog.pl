:- use_module(library(lists)).

% State representation:
% state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)
% Board is a list of 8 rows (row1=rank8) each a list of 8 atoms.

initial_state(state(
    [
      [black_rook,   black_knight, black_bishop, black_queen,  black_king,   black_bishop, black_knight, black_rook],
      [black_pawn,   black_pawn,   black_pawn,   black_pawn,   black_pawn,   black_pawn,   black_pawn,   black_pawn],
      [empty,        empty,        empty,        empty,        empty,        empty,        empty,        empty],
      [empty,        empty,        empty,        empty,        empty,        empty,        empty,        empty],
      [empty,        empty,        empty,        empty,        empty,        empty,        empty,        empty],
      [empty,        empty,        empty,        empty,        empty,        empty,        empty,        empty],
      [white_pawn,   white_pawn,   white_pawn,   white_pawn,   white_pawn,   white_pawn,   white_pawn,   white_pawn],
      [white_rook,   white_knight, white_bishop, white_queen,  white_king,   white_bishop, white_knight, white_rook]
    ],
    white,
    [white_kingside, white_queenside, black_kingside, black_queenside],
    none,
    0,
    1
)).

current_player(state(_, Turn, _, _, _, _), Turn).

% Helpers for board access and updates
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

get_cell(Row, Col, Board, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

inside_board(R, C) :- R >= 1, R =< 8, C >= 1, C =< 8.

% Piece color identification
piece_color(Piece, white) :- atom_concat(white_, _, Piece).
piece_color(Piece, black) :- atom_concat(black_, _, Piece).

opponent(white, black).
opponent(black, white).

% Generate pawn moves (single, double, captures)
pawn_moves(Board, white, FR, FC, TR, FC) :-
    TR is FR - 1,
    inside_board(TR, FC),
    get_cell(TR, FC, Board, empty).
pawn_moves(Board, white, 7, FC, 5, FC) :-
    inside_board(6, FC),
    get_cell(6, FC, Board, empty),
    get_cell(5, FC, Board, empty).
pawn_moves(Board, white, FR, FC, TR, TC) :-
    TR is FR - 1,
    (TC is FC - 1; TC is FC + 1),
    inside_board(TR, TC),
    get_cell(TR, TC, Board, P), P \= empty, piece_color(P, black).

pawn_moves(Board, black, FR, FC, TR, FC) :-
    TR is FR + 1,
    inside_board(TR, FC),
    get_cell(TR, FC, Board, empty).
pawn_moves(Board, black, 2, FC, 4, FC) :-
    inside_board(3, FC),
    get_cell(3, FC, Board, empty),
    get_cell(4, FC, Board, empty).
pawn_moves(Board, black, FR, FC, TR, TC) :-
    TR is FR + 1,
    (TC is FC - 1; TC is FC + 1),
    inside_board(TR, TC),
    get_cell(TR, TC, Board, P), P \= empty, piece_color(P, white).

% Generate knight moves
knight_moves(Board, Turn, FR, FC, TR, TC) :-
    member([DR, DC], [[2,1],[1,2],[-1,2],[-2,1],[-2,-1],[-1,-2],[1,-2],[2,-1]]),
    TR is FR + DR, TC is FC + DC,
    inside_board(TR, TC),
    get_cell(TR, TC, Board, P),
    ( P = empty ; (piece_color(P, C), opponent(Turn, C)) ).

% Legal moves for pawns and knights only
legal_move(state(Board, Turn, _, _, _, _), move(FR, FC, TR, TC, none)) :-
    nth1(FR, Board, RowList),
    nth1(FC, RowList, Piece),
    piece_color(Piece, Turn),
    ( Piece = white_pawn ; Piece = black_pawn ),
    pawn_moves(Board, Turn, FR, FC, TR, TC).
legal_move(state(Board, Turn, _, _, _, _), move(FR, FC, TR, TC, none)) :-
    nth1(FR, Board, RowList),
    nth1(FC, RowList, Piece),
    piece_color(Piece, Turn),
    ( Piece = white_knight ; Piece = black_knight ),
    knight_moves(Board, Turn, FR, FC, TR, TC).

% Apply a legal move, update state fields
apply_move(state(Board, Turn, CR, _, HC, FCN), move(FR, FC, TR, TC, Promo), state(NewBoard, NewTurn, CR, EP, NewHC, NewFCN)) :-
    get_cell(FR, FC, Board, Piece),
    legal_move(state(Board, Turn, CR, _, HC, FCN), move(FR, FC, TR, TC, Promo)),
    get_cell(TR, TC, Board, Captured),
    % Determine new piece for promotion
    ( Piece = white_pawn, TR =:= 1, Promo \= none -> atom_concat(white_, Promo, NewPiece)
    ; Piece = black_pawn, TR =:= 8, Promo \= none -> atom_concat(black_, Promo, NewPiece)
    ; NewPiece = Piece
    ),
    % Move piece on board
    set_cell(FR, FC, Board, empty, B1),
    set_cell(TR, TC, B1, NewPiece, NewBoard),
    % En passant target for double pawn move
    ( Piece = white_pawn, FR =:= 7, TR =:= 5 -> EP = [6,FC]
    ; Piece = black_pawn, FR =:= 2, TR =:= 4 -> EP = [3,FC]
    ; EP = none
    ),
    % Halfmove clock: reset on pawn move or capture
    ( Piece = white_pawn ; Piece = black_pawn ; Captured \= empty -> NewHC = 0 ; NewHC is HC + 1 ),
    % Turn and fullmove number update
    next_player(Turn, NewTurn),
    ( Turn = black -> NewFCN is FCN + 1 ; NewFCN = FCN ).

game_over(_, _) :- fail.

render_state(state(Board, Turn, CR, EP, HC, FCN)) :-
    forall(nth1(_, Board, Row),
        ( forall(nth1(_, Row, C),
            ( C = empty      -> format(". ")
            ; C = white_king   -> format("K ")
            ; C = white_queen  -> format("Q ")
            ; C = white_rook   -> format("R ")
            ; C = white_bishop -> format("B ")
            ; C = white_knight -> format("N ")
            ; C = white_pawn   -> format("P ")
            ; C = black_king   -> format("k ")
            ; C = black_queen  -> format("q ")
            ; C = black_rook   -> format("r ")
            ; C = black_bishop -> format("b ")
            ; C = black_knight -> format("n ")
            ; C = black_pawn   -> format("p ")
            ; format(". ")
            )
          ), format("~n")
        )
    ),
    format("Turn: ~w, Castling: ~w, EnPassant: ~w, Halfmove: ~w, Fullmove: ~w~n",
           [Turn, CR, EP, HC, FCN]).

next_player(white, black).
next_player(black, white).