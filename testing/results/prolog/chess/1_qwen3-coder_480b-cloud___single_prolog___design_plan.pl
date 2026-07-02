:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper for 2D board updates
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% State representation:
% state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)
% Board: 8x8 list of lists
% Turn: white | black
% CastlingRights: list of castling rights atoms
% EnPassantTarget: null or [Row, Col]
% HalfmoveClock: integer
% FullmoveNumber: integer

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

legal_move(State, move(FromRow, FromCol, ToRow, ToCol, Promotion)) :-
    State = state(Board, Turn, CastlingRights, EnPassantTarget, _, _),
    % Generate all possible moves
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    Piece \= empty,
    piece_color(Piece, Turn),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    (FromRow \= ToRow ; FromCol \= ToCol),
    % Check if move is legal for the piece
    is_legal_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget),
    % Check if move puts own king in check
    \+ move_puts_own_king_in_check(State, FromRow, FromCol, ToRow, ToCol),
    % Handle promotion
    (piece_type(Piece, pawn) ->
        (ToRow = 1 ; ToRow = 8) ->
            member(Promotion, [queen, rook, bishop, knight])
        ;
            Promotion = none
    ;
        Promotion = none
    ),
    % Handle castling
    (is_castling_move(Piece, FromRow, FromCol, ToRow, ToCol, CastlingRights) ->
        is_legal_castling(State, FromRow, FromCol, ToRow, ToCol)
    ;
        true
    ).

% Get piece at position
get_piece(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Get piece color
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

% Get piece type
piece_type(white_king, king).
piece_type(white_queen, queen).
piece_type(white_rook, rook).
piece_type(white_bishop, bishop).
piece_type(white_knight, knight).
piece_type(white_pawn, pawn).
piece_type(black_king, king).
piece_type(black_queen, queen).
piece_type(black_rook, rook).
piece_type(black_bishop, bishop).
piece_type(black_knight, knight).
piece_type(black_pawn, pawn).

% Check if move is legal for a piece
is_legal_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget) :-
    get_piece(Board, ToRow, ToCol, TargetPiece),
    (TargetPiece = empty ; is_opponent(Piece, TargetPiece) ; 
     (piece_type(Piece, pawn), EnPassantTarget = [ToRow, ToCol])),
    piece_type(Piece, Type),
    is_legal_move_for_type(Type, FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget).

% Check if pieces are opponents
is_opponent(Piece1, Piece2) :-
    piece_color(Piece1, Color1),
    piece_color(Piece2, Color2),
    Color1 \= Color2.

% Legal moves by piece type
is_legal_move_for_type(pawn, FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget) :-
    is_legal_pawn_move(FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget).
is_legal_move_for_type(rook, FromRow, FromCol, ToRow, ToCol, Board, _) :-
    is_legal_rook_move(FromRow, FromCol, ToRow, ToCol),
    is_path_clear(Board, FromRow, FromCol, ToRow, ToCol).
is_legal_move_for_type(bishop, FromRow, FromCol, ToRow, ToCol, Board, _) :-
    is_legal_bishop_move(FromRow, FromCol, ToRow, ToCol),
    is_path_clear(Board, FromRow, FromCol, ToRow, ToCol).
is_legal_move_for_type(queen, FromRow, FromCol, ToRow, ToCol, Board, _) :-
    (is_legal_rook_move(FromRow, FromCol, ToRow, ToCol) ;
     is_legal_bishop_move(FromRow, FromCol, ToRow, ToCol)),
    is_path_clear(Board, FromRow, FromCol, ToRow, ToCol).
is_legal_move_for_type(king, FromRow, FromCol, ToRow, ToCol, _, _) :-
    is_legal_king_move(FromRow, FromCol, ToRow, ToCol).
is_legal_move_for_type(knight, FromRow, FromCol, ToRow, ToCol, _, _) :-
    is_legal_knight_move(FromRow, FromCol, ToRow, ToCol).

% Pawn move legality
is_legal_pawn_move(FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget) :-
    get_piece(Board, FromRow, FromCol, Pawn),
    piece_color(Pawn, Color),
    (Color = white ->
        % White pawn moves
        (ToRow =:= FromRow - 1, ToCol =:= FromCol ->
            % Move forward one square
            get_piece(Board, ToRow, ToCol, Target),
            Target = empty
        ;
            ToRow =:= FromRow - 1, abs(ToCol - FromCol) =:= 1 ->
                % Capture diagonally
                get_piece(Board, ToRow, ToCol, Target),
                (Target \= empty, is_opponent(Pawn, Target) ;
                 EnPassantTarget = [ToRow, ToCol])
        ;
            FromRow =:= 7, ToRow =:= 5, ToCol =:= FromCol ->
                % Move two squares from starting position
                get_piece(Board, 6, FromCol, Middle),
                get_piece(Board, 5, FromCol, Target),
                Middle = empty,
                Target = empty
        )
    ;
        % Black pawn moves
        (ToRow =:= FromRow + 1, ToCol =:= FromCol ->
            % Move forward one square
            get_piece(Board, ToRow, ToCol, Target),
            Target = empty
        ;
            ToRow =:= FromRow + 1, abs(ToCol - FromCol) =:= 1 ->
                % Capture diagonally
                get_piece(Board, ToRow, ToCol, Target),
                (Target \= empty, is_opponent(Pawn, Target) ;
                 EnPassantTarget = [ToRow, ToCol])
        ;
            FromRow =:= 2, ToRow =:= 4, ToCol =:= FromCol ->
                % Move two squares from starting position
                get_piece(Board, 3, FromCol, Middle),
                get_piece(Board, 4, FromCol, Target),
                Middle = empty,
                Target = empty
        )
    ).

% Rook move legality
is_legal_rook_move(FromRow, FromCol, ToRow, ToCol) :-
    (FromRow =:= ToRow ; FromCol =:= ToCol),
    (FromRow \= ToRow ; FromCol \= ToCol).

% Bishop move legality
is_legal_bishop_move(FromRow, FromCol, ToRow, ToCol) :-
    abs(ToRow - FromRow) =:= abs(ToCol - FromCol).

% King move legality
is_legal_king_move(FromRow, FromCol, ToRow, ToCol) :-
    abs(ToRow - FromRow) =< 1,
    abs(ToCol - FromCol) =< 1,
    (FromRow \= ToRow ; FromCol \= ToCol).

% Knight move legality
is_legal_knight_move(FromRow, FromCol, ToRow, ToCol) :-
    ((abs(ToRow - FromRow) =:= 2, abs(ToCol - FromCol) =:= 1) ;
     (abs(ToRow - FromRow) =:= 1, abs(ToCol - FromCol) =:= 2)).

% Check if path is clear
is_path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    FromRow =:= ToRow ->
        % Horizontal move
        (FromCol < ToCol ->
            check_horizontal(Board, FromRow, FromCol+1, ToCol-1)
        ;
            check_horizontal(Board, FromRow, ToCol+1, FromCol-1)
        )
    ;
    FromCol =:= ToCol ->
        % Vertical move
        (FromRow < ToRow ->
            check_vertical(Board, FromCol, FromRow+1, ToRow-1)
        ;
            check_vertical(Board, FromCol, ToRow+1, FromRow-1)
        )
    ;
        % Diagonal move
        check_diagonal(Board, FromRow, FromCol, ToRow, ToCol).

% Check horizontal path
check_horizontal(_, _, Start, End) :-
    Start > End.
check_horizontal(Board, Row, Col, End) :-
    Col =< End,
    get_piece(Board, Row, Col, Piece),
    Piece = empty,
    NextCol is Col + 1,
    check_horizontal(Board, Row, NextCol, End).

% Check vertical path
check_vertical(_, _, Start, End) :-
    Start > End.
check_vertical(Board, Col, Row, End) :-
    Row =< End,
    get_piece(Board, Row, Col, Piece),
    Piece = empty,
    NextRow is Row + 1,
    check_vertical(Board, Col, NextRow, End).

% Check diagonal path
check_diagonal(_, FromRow, _, ToRow, _) :-
    FromRow =:= ToRow.
check_diagonal(Board, FromRow, FromCol, ToRow, ToCol) :-
    FromRow < ToRow ->
        (FromCol < ToCol ->
            check_diagonal_down_right(Board, FromRow+1, FromCol+1, ToRow-1, ToCol-1)
        ;
            check_diagonal_down_left(Board, FromRow+1, FromCol-1, ToRow-1, ToCol+1)
        )
    ;
        (FromCol < ToCol ->
            check_diagonal_up_right(Board, FromRow-1, FromCol+1, ToRow+1, ToCol-1)
        ;
            check_diagonal_up_left(Board, FromRow-1, FromCol-1, ToRow+1, ToCol+1)
        ).

% Diagonal path checking helpers
check_diagonal_down_right(_, FromRow, _, ToRow, _) :-
    FromRow > ToRow.
check_diagonal_down_right(Board, Row, Col, ToRow, _) :-
    Row =< ToRow,
    get_piece(Board, Row, Col, Piece),
    Piece = empty,
    NextRow is Row + 1,
    NextCol is Col + 1,
    check_diagonal_down_right(Board, NextRow, NextCol, ToRow, _).

check_diagonal_down_left(_, FromRow, _, ToRow, _) :-
    FromRow > ToRow.
check_diagonal_down_left(Board, Row, Col, ToRow, _) :-
    Row =< ToRow,
    get_piece(Board, Row, Col, Piece),
    Piece = empty,
    NextRow is Row + 1,
    NextCol is Col - 1,
    check_diagonal_down_left(Board, NextRow, NextCol, ToRow, _).

check_diagonal_up_right(_, FromRow, _, ToRow, _) :-
    FromRow < ToRow.
check_diagonal_up_right(Board, Row, Col, ToRow, _) :-
    Row >= ToRow,
    get_piece(Board, Row, Col, Piece),
    Piece = empty,
    NextRow is Row - 1,
    NextCol is Col + 1,
    check_diagonal_up_right(Board, NextRow, NextCol, ToRow, _).

check_diagonal_up_left(_, FromRow, _, ToRow, _) :-
    FromRow < ToRow.
check_diagonal_up_left(Board, Row, Col, ToRow, _) :-
    Row >= ToRow,
    get_piece(Board, Row, Col, Piece),
    Piece = empty,
    NextRow is Row - 1,
    NextCol is Col - 1,
    check_diagonal_up_left(Board, NextRow, NextCol, ToRow, _).

% Check if move puts own king in check
move_puts_own_king_in_check(State, FromRow, FromCol, ToRow, ToCol) :-
    State = state(Board, Turn, _, _, _, _),
    % Make the move on a temporary board
    get_piece(Board, FromRow, FromCol, Piece),
    make_temporary_move(Board, FromRow, FromCol, ToRow, ToCol, TempBoard),
    % Find the king's position
    find_king(TempBoard, Turn, KingRow, KingCol),
    % Check if the king is in check
    is_king_in_check(TempBoard, KingRow, KingCol, Turn).

% Make a temporary move
make_temporary_move(Board, FromRow, FromCol, ToRow, ToCol, NewBoard) :-
    get_piece(Board, FromRow, FromCol, Piece),
    set_cell(FromRow, FromCol, Board, empty, TempBoard),
    set_cell(ToRow, ToCol, TempBoard, Piece, NewBoard).

% Find king position
find_king(Board, Color, Row, Col) :-
    piece_type(King, king),
    piece_color(King, Color),
    between(1, 8, Row),
    between(1, 8, Col),
    get_piece(Board, Row, Col, King).

% Check if king is in check
is_king_in_check(Board, KingRow, KingCol, Color) :-
    % Check for opponent pieces that can attack the king
    between(1, 8, AttackerRow),
    between(1, 8, AttackerCol),
    get_piece(Board, AttackerRow, AttackerCol, AttackerPiece),
    AttackerPiece \= empty,
    is_opponent(AttackerPiece, Color),
    piece_type(AttackerPiece, AttackerType),
    is_legal_move_for_type(AttackerType, AttackerRow, AttackerCol, KingRow, KingCol, Board, _),
    % Special case for pawn attacks (pawns don't attack straight)
    (AttackerType = pawn ->
        piece_color(AttackerPiece, AttackerColor),
        (AttackerColor = white ->
            KingRow =:= AttackerRow - 1,
            abs(KingCol - AttackerCol) =:= 1
        ;
            KingRow =:= AttackerRow + 1,
            abs(KingCol - AttackerCol) =:= 1
        )
    ;
        true
    ).

% Castling move detection
is_castling_move(Piece, FromRow, FromCol, ToRow, ToCol, CastlingRights) :-
    piece_type(Piece, king),
    FromRow =:= ToRow,
    abs(ToCol - FromCol) =:= 2,
    % Check if the appropriate castling right exists
    (FromRow =:= 1 ->
        (ToCol =:= 7 ->
            member(black_kingside, CastlingRights)
        ;
            member(black_queenside, CastlingRights)
        )
    ;
        (ToCol =:= 7 ->
            member(white_kingside, CastlingRights)
        ;
            member(white_queenside, CastlingRights)
        )
    ).

% Legal castling
is_legal_castling(State, FromRow, FromCol, ToRow, ToCol) :-
    State = state(Board, Turn, _, _, _, _),
    % Check that the path is clear
    (ToCol =:= 7 ->
        % Kingside castling
        get_piece(Board, FromRow, FromCol+1, Middle1),
        get_piece(Board, FromRow, FromCol+2, Middle2),
        Middle1 = empty,
        Middle2 = empty
    ;
        % Queenside castling
        get_piece(Board, FromRow, FromCol-1, Middle1),
        get_piece(Board, FromRow, FromCol-2, Middle2),
        get_piece(Board, FromRow, FromCol-3, Middle3),
        Middle1 = empty,
        Middle2 = empty,
        Middle3 = empty
    ),
    % Check that the king doesn't pass through check
    (ToCol =:= 7 ->
        % Kingside castling
        \+ is_king_in_check(Board, FromRow, FromCol, Turn),
        \+ is_king_in_check(Board, FromRow, FromCol+1, Turn)
    ;
        % Queenside castling
        \+ is_king_in_check(Board, FromRow, FromCol, Turn),
        \+ is_king_in_check(Board, FromRow, FromCol-1, Turn)
    ).

apply_move(State, move(FromRow, FromCol, ToRow, ToCol, Promotion), NewState) :-
    State = state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber),
    % Get the piece being moved
    get_piece(Board, FromRow, FromCol, Piece),
    % Make the move on the board
    make_move_on_board(Board, FromRow, FromCol, ToRow, ToCol, Promotion, NewBoard),
    % Update castling rights
    update_castling_rights(CastlingRights, Piece, FromRow, FromCol, NewCastlingRights),
    % Update en passant target
    (piece_type(Piece, pawn), abs(ToRow - FromRow) =:= 2 ->
        % Pawn moved two squares, set en passant target
        (FromRow < ToRow ->
            EnPassantTargetNew = [FromRow+1, FromCol]
        ;
            EnPassantTargetNew = [FromRow-1, FromCol]
        )
    ;
        % Clear en passant target
        EnPassantTargetNew = null
    ),
    % Update halfmove clock
    (piece_type(Piece, pawn) ; 
     (get_piece(Board, ToRow, ToCol, TargetPiece), TargetPiece \= empty)) ->
        HalfmoveClockNew = 0
    ;
        HalfmoveClockNew is HalfmoveClock + 1,
    % Update fullmove number
    (Turn = black ->
        FullmoveNumberNew is FullmoveNumber + 1
    ;
        FullmoveNumberNew = FullmoveNumber
    ),
    % Switch turn
    (Turn = white ->
        NextTurn = black
    ;
        NextTurn = white
    ),
    % Create new state
    NewState = state(NewBoard, NextTurn, NewCastlingRights, EnPassantTargetNew, HalfmoveClockNew, FullmoveNumberNew).

% Make move on board
make_move_on_board(Board, FromRow, FromCol, ToRow, ToCol, Promotion, NewBoard) :-
    get_piece(Board, FromRow, FromCol, Piece),
    % Handle en passant capture
    (piece_type(Piece, pawn), 
     get_piece(Board, ToRow, ToCol, TargetPiece),
     TargetPiece = empty,
     abs(ToCol - FromCol) =:= 1 ->
        % This is an en passant capture
        % Remove the captured pawn
        (FromRow < ToRow ->
            CapturedRow is FromRow + 1
        ;
            CapturedRow is FromRow - 1
        ),
        set_cell(CapturedRow, ToCol, Board, empty, TempBoard),
        % Move the pawn
        set_cell(FromRow, FromCol, TempBoard, empty, TempBoard2),
        % Handle promotion
        (Promotion = none ->
            PromotedPiece = Piece
        ;
            piece_color(Piece, Color),
            atom_concat(Color, '_', Prefix),
            atom_concat(Prefix, Promotion, PromotedPieceAtom),
            PromotedPiece = PromotedPieceAtom
        ),
        set_cell(ToRow, ToCol, TempBoard2, PromotedPiece, NewBoard)
    ;
        % Handle castling
        (piece_type(Piece, king), abs(ToCol - FromCol) =:= 2 ->
            % Move the king
            set_cell(FromRow, FromCol, Board, empty, TempBoard),
            set_cell(ToRow, ToCol, TempBoard, Piece, TempBoard2),
            % Move the rook
            (ToCol =:= 7 ->
                % Kingside castling
                set_cell(FromRow, 8, TempBoard2, empty, TempBoard3),
                set_cell(FromRow, 6, TempBoard3, 
                    (piece_color(Piece, white) -> white_rook ; black_rook), 
                    NewBoard)
            ;
                % Queenside castling
                set_cell(FromRow, 1, TempBoard2, empty, TempBoard3),
                set_cell(FromRow, 4, TempBoard3, 
                    (piece_color(Piece, white) -> white_rook ; black_rook), 
                    NewBoard)
            )
        ;
            % Regular move
            set_cell(FromRow, FromCol, Board, empty, TempBoard),
            % Handle promotion
            (piece_type(Piece, pawn), (ToRow =:= 1 ; ToRow =:= 8) ->
                (Promotion = none ->
                    PromotedPiece = Piece
                ;
                    piece_color(Piece, Color),
                    atom_concat(Color, '_', Prefix),
                    atom_concat(Prefix, Promotion, PromotedPieceAtom),
                    PromotedPiece = PromotedPieceAtom
                )
            ;
                PromotedPiece = Piece
            ),
            set_cell(ToRow, ToCol, TempBoard, PromotedPiece, NewBoard)
        )
    ).

% Update castling rights
update_castling_rights(CastlingRights, Piece, FromRow, FromCol, NewCastlingRights) :-
    % If king moves, remove both castling rights for that color
    (piece_type(Piece, king) ->
        (piece_color(Piece, white) ->
            delete(CastlingRights, white_kingside, TempRights1),
            delete(TempRights1, white_queenside, NewCastlingRights)
        ;
            delete(CastlingRights, black_kingside, TempRights1),
            delete(TempRights1, black_queenside, NewCastlingRights)
        )
    ;
        % If rook moves, remove the corresponding castling right
        (piece_type(Piece, rook) ->
            (FromRow =:= 1, FromCol =:= 1 ->
                delete(CastlingRights, black_queenside, NewCastlingRights)
            ;
                FromRow =:= 1, FromCol =:= 8 ->
                    delete(CastlingRights, black_kingside, NewCastlingRights)
                ;
                    FromRow =:= 8, FromCol =:= 1 ->
                        delete(CastlingRights, white_queenside, NewCastlingRights)
                    ;
                        FromRow =:= 8, FromCol =:= 8 ->
                            delete(CastlingRights, white_kingside, NewCastlingRights)
                        ;
                            NewCastlingRights = CastlingRights
            )
        ;
            NewCastlingRights = CastlingRights
        )
    ;
        NewCastlingRights = CastlingRights
    ).

game_over(State, Winner) :-
    % Checkmate or stalemate
    \+ legal_move(State, _),
    State = state(Board, Turn, _, _, _, _),
    % Find the king
    find_king(Board, Turn, KingRow, KingCol),
    % Check if king is in check
    (is_king_in_check(Board, KingRow, KingCol, Turn) ->
        % Checkmate
        (Turn = white ->
            Winner = black
        ;
            Winner = white
        )
    ;
        % Stalemate
        Winner = draw
    ).

render_state(state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)) :-
    % Print the board
    forall(between(1, 8, Row),
           (nth1(Row, Board, RowList),
            format('~w | ', [Row]),
            forall(between(1, 8, Col),
                   (nth1(Col, RowList, Piece),
                    render_piece(Piece))),
            format('~n'))),
    format('  +-----------------------~n'),
    format('    a b c d e f g h~n~n'),
    % Print game info
    format('Turn: ~w~n', [Turn]),
    format('Castling rights: ~w~n', [CastlingRights]),
    format('En passant target: ~w~n', [EnPassantTarget]),
    format('Halfmove clock: ~w~n', [HalfmoveClock]),
    format('Fullmove number: ~w~n', [FullmoveNumber]).

% Render a piece
render_piece(Piece) :-
    (Piece = empty ->
        format('. ')
    ;
        (Piece = white_king ->
            format('K ')
        ;
            Piece = white_queen ->
                format('Q ')
            ;
                Piece = white_rook ->
                    format('R ')
                ;
                    Piece = white_bishop ->
                        format('B ')
                    ;
                        Piece = white_knight ->
                            format('N ')
                        ;
                            Piece = white_pawn ->
                                format('P ')
                            ;
                                Piece = black_king ->
                                    format('k ')
                                ;
                                    Piece = black_queen ->
                                        format('q ')
                                    ;
                                        Piece = black_rook ->
                                            format('r ')
                                        ;
                                            Piece = black_bishop ->
                                                format('b ')
                                            ;
                                                Piece = black_knight ->
                                                    format('n ')
                                                ;
                                                    Piece = black_pawn ->
                                                        format('p ')
                                                    ;
                                                        format('? ')
                                            )
                        )
            )
    ).