:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper to set cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state
initial_state(state(Board, white, [white_kingside, white_queenside, black_kingside, black_queenside], null, 0, 1)) :-
    Board = [
        [black_rook, black_knight, black_bishop, black_queen, black_king, black_bishop, black_knight, black_rook],
        [black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn],
        [white_rook, white_knight, white_bishop, white_queen, white_king, white_bishop, white_knight, white_rook]
    ].

% Current player
current_player(state(_, Turn, _, _, _, _), Turn).

% Get piece at position
get_piece(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Check if square is empty
is_empty(Board, Row, Col) :-
    get_piece(Board, Row, Col, empty).

% Check if piece belongs to color
is_piece(white, Piece) :- member(Piece, [white_king, white_queen, white_rook, white_bishop, white_knight, white_pawn]).
is_piece(black, Piece) :- member(Piece, [black_king, black_queen, black_rook, black_bishop, black_knight, black_pawn]).

% Check if square contains opponent piece
is_opponent_piece(Color, Board, Row, Col) :-
    get_piece(Board, Row, Col, Piece),
    Piece \= empty,
    (Color = white -> is_piece(black, Piece) ; is_piece(white, Piece)).

% Check if king is in check
is_in_check(Board, Color, KingRow, KingCol) :-
    next_player(Color, Opponent),
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    is_piece(Opponent, Piece),
    is_legal_move(Piece, Board, FromRow, FromCol, KingRow, KingCol, Opponent, [white_kingside, white_queenside, black_kingside, black_queenside]),
    \+ is_empty(Board, FromRow, FromCol).

is_in_check(Board, Color) :-
    nth1(KingRow, Board, RowList),
    nth1(KingCol, RowList, Piece),
    (Color = white -> Piece = white_king ; Piece = black_king),
    is_in_check(Board, Color, KingRow, KingCol).

% Generate pseudo-legal moves (ignoring check)
generate_pseudo_legal_moves(Board, Color, CastlingRights, Moves) :-
    findall(Move, (
        nth1(FromRow, Board, RowList),
        nth1(FromCol, RowList, Piece),
        is_piece(Color, Piece),
        between(1, 8, ToRow),
        between(1, 8, ToCol),
        is_legal_move(Piece, Board, FromRow, FromCol, ToRow, ToCol, Color, CastlingRights),
        (is_empty(Board, ToRow, ToCol) ; is_opponent_piece(Color, Board, ToRow, ToCol)),
        Move = move(FromRow, FromCol, ToRow, ToCol, none)
    ), Moves).

% Legal move patterns
is_legal_king_move(FromRow, FromCol, ToRow, ToCol) :-
    DR is abs(ToRow - FromRow),
    DC is abs(ToCol - FromCol),
    DR =< 1, DC =< 1,
    (DR = 1 ; DC = 1),
    (DR = 1 ; DC = 1),
    (DR = 0 -> DC = 1 ; (DC = 0 -> DR = 1 ; DR = 1, DC = 1)),
    (FromRow \= ToRow ; FromCol \= ToCol).

is_legal_rook_move(FromRow, FromCol, ToRow, ToCol) :-
    (FromRow = ToRow ; FromCol = ToCol),
    (FromRow \= ToRow ; FromCol \= ToCol).

is_legal_bishop_move(FromRow, FromCol, ToRow, ToCol) :-
    DR is abs(ToRow - FromRow),
    DC is abs(ToCol - FromCol),
    DR = DC,
    DR > 0.

is_legal_queen_move(FromRow, FromCol, ToRow, ToCol) :-
    is_legal_rook_move(FromRow, FromCol, ToRow, ToCol) ;
    is_legal_bishop_move(FromRow, FromCol, ToRow, ToCol).

is_legal_knight_move(FromRow, FromCol, ToRow, ToCol) :-
    DR is abs(ToRow - FromRow),
    DC is abs(ToCol - FromCol),
    ((DR = 2, DC = 1) ; (DR = 1, DC = 2)).

is_legal_pawn_move(Color, FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget) :-
    (Color = white ->
        (ToRow is FromRow - 1, ToCol = FromCol, is_empty(Board, ToRow, ToCol)) ; % Move forward
        (ToRow is FromRow + 1, ToCol = FromCol, is_empty(Board, ToRow, ToCol))   % Move forward
    ),
    % Capture diagonally
    (Color = white ->
        ((ToRow is FromRow - 1, ToCol is FromCol - 1, is_opponent_piece(Color, Board, ToRow, ToCol)) ;
         (ToRow is FromRow - 1, ToCol is FromCol + 1, is_opponent_piece(Color, Board, ToRow, ToCol)) ;
         (ToRow is FromRow - 1, ToCol is FromCol - 1, EnPassantTarget = [ToRow, ToCol])) ;
        ((ToRow is FromRow + 1, ToCol is FromCol - 1, is_opponent_piece(Color, Board, ToRow, ToCol)) ;
         (ToRow is FromRow + 1, ToCol is FromCol + 1, is_opponent_piece(Color, Board, ToRow, ToCol)) ;
         (ToRow is FromRow + 1, ToCol is FromCol - 1, EnPassantTarget = [ToRow, ToCol]))
    ).

% Check if path is clear for sliding pieces
is_clear_path(Board, FromRow, FromCol, ToRow, ToCol) :-
    FromRow = ToRow ->
        (FromCol < ToCol ->
            check_horizontal(Board, FromRow, FromCol, ToCol)
        ;
            check_horizontal(Board, FromRow, ToCol, FromCol)
        )
    ;
    (FromCol = ToCol ->
        (FromRow < ToRow ->
            check_vertical(Board, FromCol, FromRow, ToRow)
        ;
            check_vertical(Board, FromCol, ToRow, FromRow)
        )
    ;
        check_diagonal(Board, FromRow, FromCol, ToRow, ToCol)
    ).

check_horizontal(Board, Row, FromCol, ToCol) :-
    StartCol is FromCol + 1,
    EndCol is ToCol - 1,
    check_horizontal_range(Board, Row, StartCol, EndCol).

check_horizontal_range(_, _, Start, End) :-
    Start > End.

check_horizontal_range(Board, Row, Start, End) :-
    Start =< End,
    get_piece(Board, Row, Start, empty),
    Next is Start + 1,
    check_horizontal_range(Board, Row, Next, End).

check_vertical(Board, Col, FromRow, ToRow) :-
    StartRow is FromRow + 1,
    EndRow is ToRow - 1,
    check_vertical_range(Board, Col, StartRow, EndRow).

check_vertical_range(_, _, Start, End) :-
    Start > End.

check_vertical_range(Board, Col, Start, End) :-
    Start =< End,
    get_piece(Board, Start, Col, empty),
    Next is Start + 1,
    check_vertical_range(Board, Col, Next, End).

check_diagonal(Board, FromRow, FromCol, ToRow, ToCol) :-
    DR is ToRow - FromRow,
    DC is ToCol - FromCol,
    StepR is sign(DR),
    StepC is sign(DC),
    NumSteps is abs(DR) - 1,
    check_diagonal_steps(Board, FromRow, FromCol, StepR, StepC, NumSteps).

check_diagonal_steps(_, _, _, _, _, 0).

check_diagonal_steps(Board, Row, Col, StepR, StepC, Steps) :-
    Steps > 0,
    NewRow is Row + StepR,
    NewCol is Col + StepC,
    get_piece(Board, NewRow, NewCol, empty),
    NewSteps is Steps - 1,
    check_diagonal_steps(Board, NewRow, NewCol, StepR, StepC, NewSteps).

% Legal move for a piece
is_legal_move(Piece, Board, FromRow, FromCol, ToRow, ToCol, Color, CastlingRights) :-
    (Piece = white_king ; Piece = black_king) ->
        (is_legal_king_move(FromRow, FromCol, ToRow, ToCol) ;
         (is_castling_legal(Board, Color, kingside, CastlingRights), ToRow = FromRow, ToCol is FromCol + 2) ;
         (is_castling_legal(Board, Color, queenside, CastlingRights), ToRow = FromRow, ToCol is FromCol - 2))
    ;
    (Piece = white_rook ; Piece = black_rook) ->
        is_legal_rook_move(FromRow, FromCol, ToRow, ToCol),
        is_clear_path(Board, FromRow, FromCol, ToRow, ToCol)
    ;
    (Piece = white_bishop ; Piece = black_bishop) ->
        is_legal_bishop_move(FromRow, FromCol, ToRow, ToCol),
        is_clear_path(Board, FromRow, FromCol, ToRow, ToCol)
    ;
    (Piece = white_queen ; Piece = black_queen) ->
        is_legal_queen_move(FromRow, FromCol, ToRow, ToCol),
        is_clear_path(Board, FromRow, FromCol, ToRow, ToCol)
    ;
    (Piece = white_knight ; Piece = black_knight) ->
        is_legal_knight_move(FromRow, FromCol, ToRow, ToCol)
    ;
    (Piece = white_pawn ; Piece = black_pawn) ->
        is_legal_pawn_move(Color, FromRow, FromCol, ToRow, ToCol, Board, null).

% Castling legality check
is_castling_legal(Board, Color, Side, CastlingRights) :-
    % Check if the right exists
    (Color = white ->
        (Side = kingside -> member(white_kingside, CastlingRights) ;
         Side = queenside -> member(white_queenside, CastlingRights))
    ;
        (Side = kingside -> member(black_kingside, CastlingRights) ;
         Side = queenside -> member(black_queenside, CastlingRights))
    ),
    % Check if path is clear
    (Color = white ->
        (Side = kingside ->
            get_piece(Board, 8, 6, empty),
            get_piece(Board, 8, 7, empty)
        ;
            get_piece(Board, 8, 2, empty),
            get_piece(Board, 8, 3, empty),
            get_piece(Board, 8, 4, empty)
        )
    ;
        (Side = kingside ->
            get_piece(Board, 1, 6, empty),
            get_piece(Board, 1, 7, empty)
        ;
            get_piece(Board, 1, 2, empty),
            get_piece(Board, 1, 3, empty),
            get_piece(Board, 1, 4, empty)
        )
    ),
    % Check that king is not in check
    \+ is_in_check(Board, Color).

% Legal move predicate
legal_move(State, Move) :-
    State = state(Board, Turn, CastlingRights, EnPassantTarget, _, _),
    Move = move(FromRow, FromCol, ToRow, ToCol, Promotion),
    get_piece(Board, FromRow, FromCol, Piece),
    is_piece(Turn, Piece),
    (is_empty(Board, ToRow, ToCol) ; is_opponent_piece(Turn, Board, ToRow, ToCol)),
    is_legal_move(Piece, Board, FromRow, FromCol, ToRow, ToCol, Turn, CastlingRights),
    % Check if move leaves king in check
    set_cell(FromRow, FromCol, Board, empty, TempBoard),
    (Promotion = none ->
        set_cell(ToRow, ToCol, TempBoard, Piece, NewBoard)
    ;
        (Turn = white ->
            (Promotion = queen -> NewPiece = white_queen ;
             Promotion = rook -> NewPiece = white_rook ;
             Promotion = bishop -> NewPiece = white_bishop ;
             Promotion = knight -> NewPiece = white_knight)
        ;
            (Promotion = queen -> NewPiece = black_queen ;
             Promotion = rook -> NewPiece = black_rook ;
             Promotion = bishop -> NewPiece = black_bishop ;
             Promotion = knight -> NewPiece = black_knight)
        ),
        set_cell(ToRow, ToCol, TempBoard, NewPiece, NewBoard)
    ),
    \+ is_in_check(NewBoard, Turn).

% Apply move
apply_move(State, Move, NewState) :-
    State = state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber),
    Move = move(FromRow, FromCol, ToRow, ToCol, Promotion),
    get_piece(Board, FromRow, FromCol, Piece),
    % Move piece
    set_cell(FromRow, FromCol, Board, empty, TempBoard),
    (Promotion = none ->
        FinalPiece = Piece ;
        (Turn = white ->
            (Promotion = queen -> FinalPiece = white_queen ;
             Promotion = rook -> FinalPiece = white_rook ;
             Promotion = bishop -> FinalPiece = white_bishop ;
             Promotion = knight -> FinalPiece = white_knight)
        ;
            (Promotion = queen -> FinalPiece = black_queen ;
             Promotion = rook -> FinalPiece = black_rook ;
             Promotion = bishop -> FinalPiece = black_bishop ;
             Promotion = knight -> FinalPiece = black_knight)
        )
    ),
    set_cell(ToRow, ToCol, TempBoard, FinalPiece, NewBoard),
    % Update castling rights
    update_castling_rights(Move, CastlingRights, NewCastlingRights),
    % Update en passant target
    NewEnPassantTarget = null, % TODO: Implement en passant logic
    % Update clocks
    (Piece = white_pawn ; Piece = black_pawn ->
        NewHalfmoveClock = 0 ;
        NewHalfmoveClock is HalfmoveClock + 1
    ),
    % Update fullmove number
    (Turn = black ->
        NewFullmoveNumber is FullmoveNumber + 1 ;
        NewFullmoveNumber = FullmoveNumber
    ),
    % Switch turn
    next_player(Turn, NewTurn),
    NewState = state(NewBoard, NewTurn, NewCastlingRights, NewEnPassantTarget, NewHalfmoveClock, NewFullmoveNumber).

% Update castling rights
update_castling_rights(move(FromRow, FromCol, _, _, _), OldRights, NewRights) :-
    % TODO: Implement proper castling rights update
    NewRights = OldRights.

% Next player
next_player(white, black).
next_player(black, white).

% Game over conditions
game_over(State, Winner) :-
    % TODO: Implement checkmate and stalemate detection
    fail.

% Render state
render_state(state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)) :-
    format('  a b c d e f g h~n'),
    forall(between(1, 8, Row),
           (nth1(Row, Board, RowList),
            format('~w ', [Row]),
            forall(nth1(Col, RowList, Piece),
                   (Piece = empty ->
                       format('. ')
                   ;
                       (atom_chars(Piece, Chars),
                        (nth0(1, Chars, Char) ->
                            format('~w ', [Char])
                        ;
                            format('~w ', [Piece])
                        )
                       )
                   )
            ),
            format('~w~n', [Row])
           )
    ),
    format('  a b c d e f g h~n'),
    format('Turn: ~w~n', [Turn]),
    format('Castling: ~w~n', [CastlingRights]),
    format('En passant: ~w~n', [EnPassantTarget]),
    format('Halfmove: ~w Fullmove: ~w~n', [HalfmoveClock, FullmoveNumber]).