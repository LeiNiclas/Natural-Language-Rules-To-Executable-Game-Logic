:- use_module(library(lists)).
:- use_module(library(apply)).

% State representation:
% state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)
% Board: 8x8 list of lists, [Row1,...,Row8], each row [Col1,...,Col8]
% Turn: white | black
% CastlingRights: list of atoms from [white_kingside, white_queenside, black_kingside, black_queenside]
% EnPassantTarget: [] or [Row, Col]
% HalfmoveClock: integer
% FullmoveNumber: integer

% Helper to update a cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Piece colors
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

opponent(white, black).
opponent(black, white).

% Initial state
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
    [],
    0,
    1
)).

current_player(state(_, Turn, _, _, _, _), Turn).

% Legal move generator
legal_move(State, move(FromRow, FromCol, ToRow, ToCol, Promotion)) :-
    state(Board, Turn, _, _, _, _) = State,
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    Piece \= empty,
    piece_color(Piece, Turn),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    (ToRow =\= FromRow ; ToCol =\= FromCol),
    legal_piece_move(State, Piece, FromRow, FromCol, ToRow, ToCol),
    % Check that move doesn't leave king in check
    apply_move(State, move(FromRow, FromCol, ToRow, ToCol, none), TempState),
    \+ king_in_check(TempState, Turn),
    % Handle promotion
    (Piece = white_pawn, ToRow = 1 ->
        member(Promotion, [queen, rook, bishop, knight])
    ; Piece = black_pawn, ToRow = 8 ->
        member(Promotion, [queen, rook, bishop, knight])
    ; Promotion = none).

% Basic piece movement rules (without considering checks)
legal_piece_move(State, Piece, FromRow, FromCol, ToRow, ToCol) :-
    state(Board, _, _, EnPassantTarget, _, _) = State,
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, TargetPiece),
    (TargetPiece = empty ; piece_color(TargetPiece, Opponent), opponent(Opponent, PieceColor), piece_color(Piece, PieceColor)),
    (
        (Piece = white_king ; Piece = black_king) ->
            KingDR is abs(ToRow - FromRow),
            KingDC is abs(ToCol - FromCol),
            ((KingDR = 1, KingDC =< 1) ; (KingDR =< 1, KingDC = 1)) ;
        (Piece = white_queen ; Piece = black_queen) ->
            (rook_move(FromRow, FromCol, ToRow, ToCol) ; bishop_move(FromRow, FromCol, ToRow, ToCol)),
            path_clear(Board, FromRow, FromCol, ToRow, ToCol) ;
        (Piece = white_rook ; Piece = black_rook) ->
            rook_move(FromRow, FromCol, ToRow, ToCol),
            path_clear(Board, FromRow, FromCol, ToRow, ToCol) ;
        (Piece = white_bishop ; Piece = black_bishop) ->
            bishop_move(FromRow, FromCol, ToRow, ToCol),
            path_clear(Board, FromRow, FromCol, ToRow, ToCol) ;
        (Piece = white_knight ; Piece = black_knight) ->
            knight_move(FromRow, FromCol, ToRow, ToCol) ;
        (Piece = white_pawn ; Piece = black_pawn) ->
            pawn_move(State, Piece, FromRow, FromCol, ToRow, ToCol)
    ),
    % Special rules
    (
        % En passant
        (Piece = white_pawn, ToRow =:= FromRow - 1, abs(ToCol - FromCol) =:= 1, TargetPiece = empty, EnPassantTarget = [ToRow, ToCol]) ;
        (Piece = black_pawn, ToRow =:= FromRow + 1, abs(ToCol - FromCol) =:= 1, TargetPiece = empty, EnPassantTarget = [ToRow, ToCol]) ;
        % Normal capture or move
        (TargetPiece = empty ; piece_color(TargetPiece, Opponent), opponent(Opponent, PieceColor), piece_color(Piece, PieceColor)),
        \+ ((Piece = white_pawn ; Piece = black_pawn), ToRow =:= FromRow)
    ).

rook_move(R1, C1, R2, C2) :- R1 =:= R2, C1 =\= C2.
rook_move(R1, C1, R2, C2) :- C1 =:= C2, R1 =\= R2.

bishop_move(R1, C1, R2, C2) :- DR is abs(R2 - R1), DC is abs(C2 - C1), DR =:= DC, DR > 0.

knight_move(R1, C1, R2, C2) :- DR is abs(R2 - R1), DC is abs(C2 - C1), ((DR =:= 2, DC =:= 1) ; (DR =:= 1, DC =:= 2)).

pawn_move(state(Board, white, _, _, _, _), white_pawn, FromRow, FromCol, ToRow, ToCol) :-
    DR is FromRow - ToRow,
    DC is abs(FromCol - ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, TargetPiece),
    (
        % Move forward
        (DC =:= 0, TargetPiece = empty ->
            (DR =:= 1 ; (FromRow =:= 7, DR =:= 2))
        ;
        % Capture diagonally
        DC =:= 1, DR =:= 1, TargetPiece \= empty, piece_color(TargetPiece, black))
    ).

pawn_move(state(Board, black, _, _, _, _), black_pawn, FromRow, FromCol, ToRow, ToCol) :-
    DR is ToRow - FromRow,
    DC is abs(FromCol - ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, TargetPiece),
    (
        % Move forward
        (DC =:= 0, TargetPiece = empty ->
            (DR =:= 1 ; (FromRow =:= 2, DR =:= 2))
        ;
        % Capture diagonally
        DC =:= 1, DR =:= 1, TargetPiece \= empty, piece_color(TargetPiece, white))
    ).

% Check if path is clear for sliding pieces
path_clear(Board, R1, C1, R2, C2) :-
    R1 =:= R2, C1 =\= C2, !,
    (C1 < C2 -> Start is C1 + 1, End is C2 - 1 ; Start is C2 + 1, End is C1 - 1),
    Start =< End,
    findall(C, between(Start, End, C), Cols),
    maplist([C, Square]>>(nth1(R1, Board, Row), nth1(C, Row, Square)), Cols, Squares),
    \+ member(empty, Squares).
path_clear(Board, R1, C1, R2, C2) :-
    C1 =:= C2, R1 =\= R2, !,
    (R1 < R2 -> Start is R1 + 1, End is R2 - 1 ; Start is R2 + 1, End is R1 - 1),
    Start =< End,
    findall(R, between(Start, End, R), Rows),
    maplist([R, Square]>>(nth1(R, Board, Row), nth1(C1, Row, Square)), Rows, Squares),
    \+ member(empty, Squares).
path_clear(Board, R1, C1, R2, C2) :-
    DR is abs(R2 - R1),
    DC is abs(C2 - C1),
    DR =:= DC, DR > 0, !,
    DR1 is sign(R2 - R1),
    DC1 is sign(C2 - C1),
    findall([R,C], (
        between(1, DR, I),
        R is R1 + I * DR1,
        C is C1 + I * DC1
    ), Path),
    append([_], Rest, Path),
    append(Middle, [_], Rest),
    maplist([RC, Square]>>(
        nth0(0, RC, R),
        nth0(1, RC, C),
        nth1(R, Board, Row),
        nth1(C, Row, Square)
    ), Middle, Squares),
    \+ member(empty, Squares).

% Apply move
apply_move(State, Move, NewState) :-
    state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber) = State,
    move(FromRow, FromCol, ToRow, ToCol, Promotion) = Move,
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    % Get target piece for capture detection
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, TargetPiece),
    % Handle en passant capture
    (
        (Piece = white_pawn, TargetPiece = empty, EnPassantTarget = [ToRow, ToCol]) ->
            CapturedRow is ToRow + 1,
            set_cell(CapturedRow, ToCol, Board, empty, Board1)
        ;
        (Piece = black_pawn, TargetPiece = empty, EnPassantTarget = [ToRow, ToCol]) ->
            CapturedRow is ToRow - 1,
            set_cell(CapturedRow, ToCol, Board, empty, Board1)
        ;
        Board1 = Board
    ),
    % Move piece
    set_cell(FromRow, FromCol, Board1, empty, Board2),
    (
        Promotion = none ->
            set_cell(ToRow, ToCol, Board2, Piece, Board3)
        ;
        % Handle promotion
        (Piece = white_pawn ->
            atom_concat(white_, Promotion, NewPiece)
        ;
        Piece = black_pawn ->
            atom_concat(black_, Promotion, NewPiece)
        ),
        set_cell(ToRow, ToCol, Board2, NewPiece, Board3)
    ),
    % Update castling rights
    update_castling_rights(Piece, FromRow, FromCol, CastlingRights, NewCastlingRights),
    % Update en passant target
    (
        (Piece = white_pawn, FromRow =:= 7, ToRow =:= 5) ->
            EnPassantNew = [6, FromCol]
        ;
        (Piece = black_pawn, FromRow =:= 2, ToRow =:= 4) ->
            EnPassantNew = [3, FromCol]
        ;
        EnPassantNew = []
    ),
    % Update clocks
    (
        (Piece = white_pawn ; Piece = black_pawn ; TargetPiece \= empty) ->
            HalfmoveNew = 0
        ;
            HalfmoveNew is HalfmoveClock + 1
    ),
    % Update fullmove number
    (
        Turn = black ->
            FullmoveNew is FullmoveNumber + 1
        ;
            FullmoveNew = FullmoveNumber
    ),
    % Switch turn
    (Turn = white -> NextTurn = black ; NextTurn = white),
    NewState = state(Board3, NextTurn, NewCastlingRights, EnPassantNew, HalfmoveNew, FullmoveNew).

% Update castling rights when king or rook moves
update_castling_rights(white_king, _, _, _, []).
update_castling_rights(black_king, _, _, _, []).
update_castling_rights(white_rook, 8, 1, CastlingRights, NewRights) :-
    subtract(CastlingRights, [white_queenside], NewRights).
update_castling_rights(white_rook, 8, 8, CastlingRights, NewRights) :-
    subtract(CastlingRights, [white_kingside], NewRights).
update_castling_rights(black_rook, 1, 1, CastlingRights, NewRights) :-
    subtract(CastlingRights, [black_queenside], NewRights).
update_castling_rights(black_rook, 1, 8, CastlingRights, NewRights) :-
    subtract(CastlingRights, [black_kingside], NewRights).
update_castling_rights(_, _, _, CastlingRights, CastlingRights).

% Check if king is in check
king_in_check(state(Board, Turn, _, _, _, _), Turn) :-
    find_king(Board, Turn, KingRow, KingCol),
    opponent(Turn, Opponent),
    between(1, 8, R),
    between(1, 8, C),
    nth1(R, Board, RowList),
    nth1(C, RowList, Piece),
    Piece \= empty,
    piece_color(Piece, Opponent),
    legal_piece_move(state(Board, Opponent, [], [], 0, 1), Piece, R, C, KingRow, KingCol).

find_king(Board, Color, Row, Col) :-
    atom_concat(Color, '_king', KingPiece),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, KingPiece).

% Game over conditions
game_over(State, Winner) :-
    current_player(State, Player),
    \+ (legal_move(State, _)),
    (king_in_check(State, Player) ->
        opponent(Player, Winner)
    ;
        Winner = draw
    ).

% Render state
render_state(state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)) :-
    format('  a b c d e f g h~n'),
    forall(between(1, 8, Row),
           (RowNum is 9 - Row,
            nth1(Row, Board, RowList),
            format('~w ', [RowNum]),
            forall(nth1(Col, RowList, Piece),
                   (piece_symbol(Piece, Symbol),
                    format('~w ', [Symbol]))),
            format('~n'))),
    format('  a b c d e f g h~n'),
    format('Turn: ~w~n', [Turn]),
    format('Castling: ~w~n', [CastlingRights]),
    (EnPassantTarget = [R,C] ->
        ColChar is C + 96,
        format('En passant: ~w~w~n', [ColChar, R])
    ;
        format('En passant: -~n')
    ),
    format('Halfmove clock: ~w~n', [HalfmoveClock]),
    format('Fullmove number: ~w~n', [FullmoveNumber]).

piece_symbol(empty, '.').
piece_symbol(white_king, 'K').
piece_symbol(white_queen, 'Q').
piece_symbol(white_rook, 'R').
piece_symbol(white_bishop, 'B').
piece_symbol(white_knight, 'N').
piece_symbol(white_pawn, 'P').
piece_symbol(black_king, 'k').
piece_symbol(black_queen, 'q').
piece_symbol(black_rook, 'r').
piece_symbol(black_bishop, 'b').
piece_symbol(black_knight, 'n').
piece_symbol(black_pawn, 'p').