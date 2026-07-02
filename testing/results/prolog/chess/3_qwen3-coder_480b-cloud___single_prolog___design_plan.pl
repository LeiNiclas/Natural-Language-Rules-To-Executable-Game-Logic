:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list of 8 rows, each with 8 elements
% Row 1 = rank 8 (black back rank), Row 8 = rank 1 (white back rank)
% Col 1 = file a (leftmost), Col 8 = file h (rightmost)

% Helper for 2D board manipulation
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% piece_at(+Board, +Row, +Col, -Piece)
piece_at(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% valid_piece_move(+Piece, +FromRow, +FromCol, +ToRow, +ToCol)
valid_piece_move(white_pawn, FromRow, FromCol, ToRow, ToCol) :-
    ToCol =:= FromCol,
    ToRow =:= FromRow - 1.
valid_piece_move(white_pawn, FromRow, FromCol, ToRow, ToCol) :-
    ToCol =:= FromCol,
    FromRow =:= 7,
    ToRow =:= FromRow - 2.
valid_piece_move(white_pawn, FromRow, FromCol, ToRow, ToCol) :-
    abs(ToCol - FromCol) =:= 1,
    ToRow =:= FromRow - 1.
valid_piece_move(black_pawn, FromRow, FromCol, ToRow, ToCol) :-
    ToCol =:= FromCol,
    ToRow =:= FromRow + 1.
valid_piece_move(black_pawn, FromRow, FromCol, ToRow, ToCol) :-
    ToCol =:= FromCol,
    FromRow =:= 2,
    ToRow =:= FromRow + 2.
valid_piece_move(black_pawn, FromRow, FromCol, ToRow, ToCol) :-
    abs(ToCol - FromCol) =:= 1,
    ToRow =:= FromRow + 1.
valid_piece_move(white_knight, FromRow, FromCol, ToRow, ToCol) :-
    (abs(ToRow - FromRow) =:= 2, abs(ToCol - FromCol) =:= 1);
    (abs(ToRow - FromRow) =:= 1, abs(ToCol - FromCol) =:= 2).
valid_piece_move(black_knight, FromRow, FromCol, ToRow, ToCol) :-
    (abs(ToRow - FromRow) =:= 2, abs(ToCol - FromCol) =:= 1);
    (abs(ToRow - FromRow) =:= 1, abs(ToCol - FromCol) =:= 2).
valid_piece_move(white_bishop, FromRow, FromCol, ToRow, ToCol) :-
    abs(ToRow - FromRow) =:= abs(ToCol - FromCol),
    ToRow =\= FromRow.
valid_piece_move(black_bishop, FromRow, FromCol, ToRow, ToCol) :-
    abs(ToRow - FromRow) =:= abs(ToCol - FromCol),
    ToRow =\= FromRow.
valid_piece_move(white_rook, FromRow, FromCol, ToRow, ToCol) :-
    (ToRow =:= FromRow, ToCol =\= FromCol);
    (ToCol =:= FromCol, ToRow =\= FromRow).
valid_piece_move(black_rook, FromRow, FromCol, ToRow, ToCol) :-
    (ToRow =:= FromRow, ToCol =\= FromCol);
    (ToCol =:= FromCol, ToRow =\= FromRow).
valid_piece_move(white_queen, FromRow, FromCol, ToRow, ToCol) :-
    valid_piece_move(white_rook, FromRow, FromCol, ToRow, ToCol);
    valid_piece_move(white_bishop, FromRow, FromCol, ToRow, ToCol).
valid_piece_move(black_queen, FromRow, FromCol, ToRow, ToCol) :-
    valid_piece_move(black_rook, FromRow, FromCol, ToRow, ToCol);
    valid_piece_move(black_bishop, FromRow, FromCol, ToRow, ToCol).
valid_piece_move(white_king, FromRow, FromCol, ToRow, ToCol) :-
    abs(ToRow - FromRow) =< 1,
    abs(ToCol - FromCol) =< 1,
    (ToRow =\= FromRow; ToCol =\= FromCol).
valid_piece_move(black_king, FromRow, FromCol, ToRow, ToCol) :-
    abs(ToRow - FromRow) =< 1,
    abs(ToCol - FromCol) =< 1,
    (ToRow =\= FromRow; ToCol =\= FromCol).

% path_clear(+Board, +FromRow, +FromCol, +ToRow, +ToCol)
path_clear(_, FromRow, _, ToRow, _) :-
    FromRow =:= ToRow.
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    FromRow < ToRow, FromCol =:= ToCol,
    NextRow is FromRow + 1,
    NextRow < ToRow,
    piece_at(Board, NextRow, FromCol, empty),
    path_clear(Board, NextRow, FromCol, ToRow, ToCol).
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    FromRow > ToRow, FromCol =:= ToCol,
    NextRow is FromRow - 1,
    NextRow > ToRow,
    piece_at(Board, NextRow, FromCol, empty),
    path_clear(Board, NextRow, FromCol, ToRow, ToCol).
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    FromRow =:= ToRow, FromCol < ToCol,
    NextCol is FromCol + 1,
    NextCol < ToCol,
    piece_at(Board, FromRow, NextCol, empty),
    path_clear(Board, FromRow, NextCol, ToRow, ToCol).
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    FromRow =:= ToRow, FromCol > ToCol,
    NextCol is FromCol - 1,
    NextCol > ToCol,
    piece_at(Board, FromRow, NextCol, empty),
    path_clear(Board, FromRow, NextCol, ToRow, ToCol).
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    DR is ToRow - FromRow,
    DC is ToCol - FromCol,
    abs(DR) =:= abs(DC),
    DR > 0, DC > 0,
    NextRow is FromRow + 1,
    NextCol is FromCol + 1,
    NextRow < ToRow,
    piece_at(Board, NextRow, NextCol, empty),
    path_clear(Board, NextRow, NextCol, ToRow, ToCol).
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    DR is ToRow - FromRow,
    DC is ToCol - FromCol,
    abs(DR) =:= abs(DC),
    DR > 0, DC < 0,
    NextRow is FromRow + 1,
    NextCol is FromCol - 1,
    NextRow < ToRow,
    piece_at(Board, NextRow, NextCol, empty),
    path_clear(Board, NextRow, NextCol, ToRow, ToCol).
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    DR is ToRow - FromRow,
    DC is ToCol - FromCol,
    abs(DR) =:= abs(DC),
    DR < 0, DC > 0,
    NextRow is FromRow - 1,
    NextCol is FromCol + 1,
    NextRow > ToRow,
    piece_at(Board, NextRow, NextCol, empty),
    path_clear(Board, NextRow, NextCol, ToRow, ToCol).
path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    DR is ToRow - FromRow,
    DC is ToCol - FromCol,
    abs(DR) =:= abs(DC),
    DR < 0, DC < 0,
    NextRow is FromRow - 1,
    NextCol is FromCol - 1,
    NextRow > ToRow,
    piece_at(Board, NextRow, NextCol, empty),
    path_clear(Board, NextRow, NextCol, ToRow, ToCol).

% is_promotion_square(+Row, +Turn)
is_promotion_square(1, white).
is_promotion_square(8, black).

% update_castling_rights(+CastlingRights, +FromRow, +FromCol, +ToRow, +ToCol, -NewRights)
update_castling_rights(CastlingRights, 8, 5, _, _, NewRights) :-
    subtract(CastlingRights, [white_kingside, white_queenside], NewRights).
update_castling_rights(CastlingRights, 1, 5, _, _, NewRights) :-
    subtract(CastlingRights, [black_kingside, black_queenside], NewRights).
update_castling_rights(CastlingRights, 8, 1, _, _, NewRights) :-
    subtract(CastlingRights, [white_queenside], NewRights).
update_castling_rights(CastlingRights, 8, 8, _, _, NewRights) :-
    subtract(CastlingRights, [white_kingside], NewRights).
update_castling_rights(CastlingRights, 1, 1, _, _, NewRights) :-
    subtract(CastlingRights, [black_queenside], NewRights).
update_castling_rights(CastlingRights, 1, 8, _, _, NewRights) :-
    subtract(CastlingRights, [black_kingside], NewRights).
update_castling_rights(CastlingRights, _, _, _, _, CastlingRights).

% find_king(+Board, +Color, -Row, -Col)
find_king(Board, Color, Row, Col) :-
    piece_at(Board, Row, Col, Piece),
    atom_concat(Color, '_king', Piece).

% in_check(+Board, +KingRow, +KingCol, +AttackingColor)
in_check(Board, KingRow, KingCol, AttackingColor) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece),
    Piece \= empty,
    atom_concat(AttackingColor, '_', Prefix),
    atom_concat(Prefix, PieceType, Piece),
    valid_piece_move(Piece, Row, Col, KingRow, KingCol),
    (PieceType = knight -> true ; path_clear(Board, Row, Col, KingRow, KingCol)).

% legal_king_move(+Board, +FromRow, +FromCol, +ToRow, +ToCol, +Turn)
legal_king_move(Board, FromRow, FromCol, ToRow, ToCol, Turn) :-
    set_cell(FromRow, FromCol, Board, empty, TempBoard),
    atom_concat(Turn, '_', KingPiece),
    set_cell(ToRow, ToCol, TempBoard, KingPiece, TestBoard),
    find_king(TestBoard, Turn, NewKingRow, NewKingCol),
    (Turn = white -> Opponent = black ; Opponent = white),
    \+ in_check(TestBoard, NewKingRow, NewKingCol, Opponent).

% generate_pseudo_legal_moves(+Board, +Turn, -Moves)
generate_pseudo_legal_moves(Board, Turn, move(FromRow, FromCol, ToRow, ToCol, none)) :-
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    Piece \= empty,
    atom_concat(Turn, '_', Prefix),
    atom_concat(Prefix, _, Piece),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, Target),
    (Target = empty ->
        true
    ;
        atom_concat(Opponent, _, Target),
        Turn \= Opponent
    ),
    valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol),
    (Piece = white_knight ; Piece = black_knight -> true ; path_clear(Board, FromRow, FromCol, ToRow, ToCol)),
    (atom_concat(_, 'king', Piece) ->
        legal_king_move(Board, FromRow, FromCol, ToRow, ToCol, Turn)
    ; true).

% legal_move_check(+Board, +Turn, +Move)
legal_move_check(Board, Turn, move(FromRow, FromCol, ToRow, ToCol, _)) :-
    piece_at(Board, FromRow, FromCol, Piece),
    (atom_concat(_, 'king', Piece) ->
        legal_king_move(Board, FromRow, FromCol, ToRow, ToCol, Turn)
    ;
        set_cell(FromRow, FromCol, Board, empty, TempBoard1),
        set_cell(ToRow, ToCol, TempBoard1, Piece, TempBoard2),
        find_king(TempBoard2, Turn, KingRow, KingCol),
        (Turn = white -> Opponent = black ; Opponent = white),
        \+ in_check(TempBoard2, KingRow, KingCol, Opponent)).

initial_state(state(
    [
        [black_rook, black_knight, black_bishop, black_queen, black_king, black_bishop, black_knight, black_rook],
        [black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn],
        [white_rook, white_knight, white_bishop, white_queen, white_king, white_bishop, white_knight, white_rook]
    ],
    white,
    [white_kingside, white_queenside, black_kingside, black_queenside],
    null,
    0,
    1
)).

current_player(state(_, Turn, _, _, _, _), Turn).

legal_move(State, Move) :-
    State = state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber),
    generate_pseudo_legal_moves(Board, Turn, PseudoMove),
    legal_move_check(Board, Turn, PseudoMove),
    Move = PseudoMove.

apply_move(state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber),
           move(FromRow, FromCol, ToRow, ToCol, Promotion),
           state(NewBoard, NewTurn, NewCastlingRights, NewEnPassantTarget, NewHalfmoveClock, NewFullmoveNumber)) :-
    piece_at(Board, FromRow, FromCol, Piece),
    atom_concat(Turn, '_', Prefix),
    atom_concat(Prefix, _, Piece),
    piece_at(Board, ToRow, ToCol, Target),
    (Target = empty -> true ;
     (atom_concat(Opponent, _, Target), Turn \= Opponent)),
    valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol),
    (Piece = white_knight ; Piece = black_knight -> true ; path_clear(Board, FromRow, FromCol, ToRow, ToCol)),
    set_cell(FromRow, FromCol, Board, empty, TempBoard1),
    (Promotion = none ->
        NewPiece = Piece
    ;   atom_concat(Turn, '_', TempPrefix),
        atom_concat(TempPrefix, Promotion, NewPiece)
    ),
    set_cell(ToRow, ToCol, TempBoard1, NewPiece, NewBoard),
    update_castling_rights(CastlingRights, FromRow, FromCol, ToRow, ToCol, NewCastlingRights),
    (Turn = white -> NewTurn = black ; NewTurn = white),
    NewEnPassantTarget = null,
    (Piece = white_pawn ; Piece = black_pawn ->
        NewHalfmoveClock = 0
    ;   (Target = empty ->
            NewHalfmoveClock is HalfmoveClock + 1
        ;   NewHalfmoveClock = 0)
    ),
    (Turn = black ->
        NewFullmoveNumber is FullmoveNumber + 1
    ;   NewFullmoveNumber = FullmoveNumber).

game_over(State, Winner) :-
    State = state(Board, Turn, _, _, _, _),
    find_king(Board, Turn, KingRow, KingCol),
    (Turn = white -> Opponent = black ; Opponent = white),
    in_check(Board, KingRow, KingCol, Opponent),
    \+ (generate_pseudo_legal_moves(Board, Turn, Move),
        legal_move_check(Board, Turn, Move)),
    Winner = Opponent.
game_over(State, draw) :-
    State = state(Board, Turn, _, _, _, _),
    \+ find_king(Board, Turn, _, _),
    \+ (generate_pseudo_legal_moves(Board, Turn, Move),
        legal_move_check(Board, Turn, Move)).

render_state(state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)) :-
    format('  a b c d e f g h~n'),
    forall(between(1,8,Row),
           (nth1(Row, Board, RowList),
            format('~w ', [9-Row]),
            forall(nth1(Col, RowList, Piece),
                   (Piece = empty ->
                        format('. ')
                    ;   (Piece = white_pawn -> format('P ')
                        ;   (Piece = white_rook -> format('R ')
                        ;   (Piece = white_knight -> format('N ')
                        ;   (Piece = white_bishop -> format('B ')
                        ;   (Piece = white_queen -> format('Q ')
                        ;   (Piece = white_king -> format('K ')
                        ;   (Piece = black_pawn -> format('p ')
                        ;   (Piece = black_rook -> format('r ')
                        ;   (Piece = black_knight -> format('n ')
                        ;   (Piece = black_bishop -> format('b ')
                        ;   (Piece = black_queen -> format('q ')
                        ;   (Piece = black_king -> format('k ')
                        ;   format('~w ', [Piece])))))))))))))))),
            format('~n'))),
    format('Turn: ~w~n', [Turn]),
    format('Castling: ~w~n', [CastlingRights]),
    format('En Passant: ~w~n', [EnPassantTarget]),
    format('Halfmove: ~w Fullmove: ~w~n', [HalfmoveClock, FullmoveNumber]).