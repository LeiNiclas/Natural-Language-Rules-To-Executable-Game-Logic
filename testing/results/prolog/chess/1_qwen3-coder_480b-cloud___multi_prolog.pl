:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow, RestRows),
    set_nth1(Col, OldRow, Value, NewRow),
    nth1(Row, NewBoard, NewRow, RestRows).

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
    State = state(Board, Turn, _, _, _, _),
    nth1(FromRow, Board, Row),
    nth1(FromCol, Row, Piece),
    Piece \= empty,
    piece_color(Piece, Turn),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, TargetSquare),
    (TargetSquare = empty ; piece_color(TargetSquare, Opponent), Turn \= Opponent),
    valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board),
    Move = move(FromRow, FromCol, ToRow, ToCol, none).

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

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = white_pawn,
    ToCol = FromCol,
    ToRow is FromRow - 1,
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = white_pawn,
    FromRow = 7,
    ToCol = FromCol,
    ToRow is FromRow - 2,
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    MiddleRow is FromRow - 1,
    nth1(MiddleRow, Board, MidRowList),
    nth1(ToCol, MidRowList, empty).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = white_pawn,
    ToRow is FromRow - 1,
    (ToCol is FromCol - 1 ; ToCol is FromCol + 1),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, Target),
    Target \= empty,
    piece_color(Target, black).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = black_pawn,
    ToCol = FromCol,
    ToRow is FromRow + 1,
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = black_pawn,
    FromRow = 2,
    ToCol = FromCol,
    ToRow is FromRow + 2,
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    MiddleRow is FromRow + 1,
    nth1(MiddleRow, Board, MidRowList),
    nth1(ToCol, MidRowList, empty).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = black_pawn,
    ToRow is FromRow + 1,
    (ToCol is FromCol - 1 ; ToCol is FromCol + 1),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, Target),
    Target \= empty,
    piece_color(Target, white).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = white_rook,
    (FromRow = ToRow ; FromCol = ToCol),
    is_clear_path(FromRow, FromCol, ToRow, ToCol, Board).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = black_rook,
    (FromRow = ToRow ; FromCol = ToCol),
    is_clear_path(FromRow, FromCol, ToRow, ToCol, Board).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = white_bishop,
    DiffRow is abs(FromRow - ToRow),
    DiffCol is abs(FromCol - ToCol),
    DiffRow = DiffCol,
    DiffRow > 0,
    is_clear_path(FromRow, FromCol, ToRow, ToCol, Board).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = black_bishop,
    DiffRow is abs(FromRow - ToRow),
    DiffCol is abs(FromCol - ToCol),
    DiffRow = DiffCol,
    DiffRow > 0,
    is_clear_path(FromRow, FromCol, ToRow, ToCol, Board).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = white_queen,
    (
        (FromRow = ToRow ; FromCol = ToCol) ;
        (DiffRow is abs(FromRow - ToRow),
         DiffCol is abs(FromCol - ToCol),
         DiffRow = DiffCol,
         DiffRow > 0)
    ),
    is_clear_path(FromRow, FromCol, ToRow, ToCol, Board).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = black_queen,
    (
        (FromRow = ToRow ; FromCol = ToCol) ;
        (DiffRow is abs(FromRow - ToRow),
         DiffCol is abs(FromCol - ToCol),
         DiffRow = DiffCol,
         DiffRow > 0)
    ),
    is_clear_path(FromRow, FromCol, ToRow, ToCol, Board).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, _Board) :-
    Piece = white_knight,
    DiffRow is abs(FromRow - ToRow),
    DiffCol is abs(FromCol - ToCol),
    ((DiffRow = 2, DiffCol = 1) ; (DiffRow = 1, DiffCol = 2)).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, _Board) :-
    Piece = black_knight,
    DiffRow is abs(FromRow - ToRow),
    DiffCol is abs(FromCol - ToCol),
    ((DiffRow = 2, DiffCol = 1) ; (DiffRow = 1, DiffCol = 2)).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = white_king,
    DiffRow is abs(FromRow - ToRow),
    DiffCol is abs(FromCol - ToCol),
    DiffRow =< 1,
    DiffCol =< 1,
    (DiffRow = 1 ; DiffCol = 1),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, Target),
    (Target = empty ; piece_color(Target, black)).

valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    Piece = black_king,
    DiffRow is abs(FromRow - ToRow),
    DiffCol is abs(FromCol - ToCol),
    DiffRow =< 1,
    DiffCol =< 1,
    (DiffRow = 1 ; DiffCol = 1),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, Target),
    (Target = empty ; piece_color(Target, white)).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    FromRow = ToRow,
    FromCol < ToCol,
    check_horizontal(FromRow, FromCol, ToCol, Board, 1).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    FromRow = ToRow,
    FromCol > ToCol,
    check_horizontal(FromRow, ToCol, FromCol, Board, -1).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    FromCol = ToCol,
    FromRow < ToRow,
    check_vertical(FromCol, FromRow, ToRow, Board, 1).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    FromCol = ToCol,
    FromRow > ToRow,
    check_vertical(FromCol, ToRow, FromRow, Board, -1).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    DiffRow is ToRow - FromRow,
    DiffCol is ToCol - FromCol,
    DiffRow = DiffCol,
    DiffRow > 0,
    check_diagonal_down(FromRow, FromCol, ToRow, ToCol, Board, 1, 1).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    DiffRow is FromRow - ToRow,
    DiffCol is ToCol - FromCol,
    DiffRow = DiffCol,
    DiffRow > 0,
    check_diagonal_up(FromRow, FromCol, ToRow, ToCol, Board, -1, 1).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    DiffRow is ToRow - FromRow,
    DiffCol is FromCol - ToCol,
    DiffRow = DiffCol,
    DiffRow > 0,
    check_diagonal_up(FromRow, FromCol, ToRow, ToCol, Board, 1, -1).

is_clear_path(FromRow, FromCol, ToRow, ToCol, Board) :-
    DiffRow is FromRow - ToRow,
    DiffCol is FromCol - ToCol,
    DiffRow = DiffCol,
    DiffRow > 0,
    check_diagonal_down(FromRow, FromCol, ToRow, ToCol, Board, -1, -1).

check_horizontal(_Row, Col, Col, _Board, _Direction).
check_horizontal(Row, Col, EndCol, Board, Direction) :-
    NextCol is Col + Direction,
    NextCol =< EndCol,
    nth1(Row, Board, RowList),
    nth1(NextCol, RowList, Square),
    Square = empty,
    check_horizontal(Row, NextCol, EndCol, Board, Direction).

check_vertical(_Col, Row, Row, _Board, _Direction).
check_vertical(Col, Row, EndRow, Board, Direction) :-
    NextRow is Row + Direction,
    NextRow =< EndRow,
    nth1(NextRow, Board, RowList),
    nth1(Col, RowList, Square),
    Square = empty,
    check_vertical(Col, NextRow, EndRow, Board, Direction).

check_diagonal_down(Row, Col, Row, Col, _Board, _DirR, _DirC).
check_diagonal_down(FromRow, FromCol, ToRow, ToCol, Board, DirR, DirC) :-
    NextRow is FromRow + DirR,
    NextCol is FromCol + DirC,
    NextRow =< ToRow,
    NextCol =< ToCol,
    nth1(NextRow, Board, RowList),
    nth1(NextCol, RowList, Square),
    Square = empty,
    check_diagonal_down(NextRow, NextCol, ToRow, ToCol, Board, DirR, DirC).

check_diagonal_up(Row, Col, Row, Col, _Board, _DirR, _DirC).
check_diagonal_up(FromRow, FromCol, ToRow, ToCol, Board, DirR, DirC) :-
    NextRow is FromRow + DirR,
    NextCol is FromCol + DirC,
    NextRow >= ToRow,
    NextCol =< ToCol,
    nth1(NextRow, Board, RowList),
    nth1(NextCol, RowList, Square),
    Square = empty,
    check_diagonal_up(NextRow, NextCol, ToRow, ToCol, Board, DirR, DirC).

apply_move(State, Move, NewState) :-
    State = state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber),
    Move = move(FromRow, FromCol, ToRow, ToCol, Promotion),
    
    % Get the piece being moved
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    Piece \= empty,
    
    % Check that it's the correct player's turn
    piece_color(Piece, Turn),
    
    % Get the target square
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, TargetSquare),
    
    % Handle en passant capture
    (   EnPassantTarget = [ToRow, ToCol],
        piece_type(Piece, pawn),
        (Turn = white -> CapturedRow is ToRow + 1 ; CapturedRow is ToRow - 1),
        CapturedCol = ToCol,
        nth1(CapturedRow, Board, CapturedRowList),
        nth1(CapturedCol, CapturedRowList, CapturedPiece),
        piece_color(CapturedPiece, Opponent),
        Turn \= Opponent
    ->  % En passant capture
        set_cell(FromRow, FromCol, Board, empty, BoardAfterCapture),
        set_cell(CapturedRow, CapturedCol, BoardAfterCapture, empty, BoardAfterCapture2),
        set_cell(ToRow, ToCol, BoardAfterCapture2, Piece, NewBoard)
    ;   % Normal move
        set_cell(FromRow, FromCol, Board, empty, BoardAfterCapture),
        set_cell(ToRow, ToCol, BoardAfterCapture, Piece, NewBoard)
    ),
    
    % Handle pawn promotion
    (   Promotion \= none,
        piece_type(Piece, pawn),
        ((Turn = white, ToRow = 1) ; (Turn = black, ToRow = 8))
    ->  atom_concat(Turn, '_', Prefix),
        atom_concat(Prefix, Promotion, PromotedPiece),
        set_cell(ToRow, ToCol, NewBoard, PromotedPiece, FinalBoard)
    ;   FinalBoard = NewBoard
    ),
    
    % Update en passant target
    (   piece_type(Piece, pawn),
        (   (Turn = white, FromRow = 7, ToRow = 5)
        ;   (Turn = black, FromRow = 2, ToRow = 4)
        )
    ->  EnPassantRow is (FromRow + ToRow) // 2,
        NewEnPassantTarget = [EnPassantRow, FromCol]
    ;   NewEnPassantTarget = null
    ),
    
    % Update castling rights
    update_castling_rights(CastlingRights, FromRow, FromCol, ToRow, ToCol, NewCastlingRights),
    
    % Update halfmove clock
    (   piece_type(Piece, pawn) ; TargetSquare \= empty ; EnPassantTarget \= null
    ->  NewHalfmoveClock = 0
    ;   NewHalfmoveClock is HalfmoveClock + 1
    ),
    
    % Update fullmove number
    (   Turn = black
    ->  NewFullmoveNumber is FullmoveNumber + 1
    ;   NewFullmoveNumber = FullmoveNumber
    ),
    
    % Switch turn
    (   Turn = white
    ->  NextTurn = black
    ;   NextTurn = white
    ),
    
    % Create new state
    NewState = state(FinalBoard, NextTurn, NewCastlingRights, NewEnPassantTarget, NewHalfmoveClock, NewFullmoveNumber).

piece_type(white_pawn, pawn).
piece_type(white_rook, rook).
piece_type(white_knight, knight).
piece_type(white_bishop, bishop).
piece_type(white_queen, queen).
piece_type(white_king, king).
piece_type(black_pawn, pawn).
piece_type(black_rook, rook).
piece_type(black_knight, knight).
piece_type(black_bishop, bishop).
piece_type(black_queen, queen).
piece_type(black_king, king).

update_castling_rights(CastlingRights, FromRow, FromCol, ToRow, ToCol, NewCastlingRights) :-
    % If king moves, remove all castling rights for that color
    (   (FromRow = 1, FromCol = 5)  % Black king
    ->  subtract(CastlingRights, [black_kingside, black_queenside], TempRights)
    ;   (FromRow = 8, FromCol = 5)  % White king
    ->  subtract(CastlingRights, [white_kingside, white_queenside], TempRights)
    ;   TempRights = CastlingRights
    ),
    
    % If a rook moves, remove its castling right
    (   FromRow = 1, FromCol = 1  % Black queenside rook
    ->  delete(TempRights, black_queenside, TempRights2)
    ;   FromRow = 1, FromCol = 8  % Black kingside rook
    ->  delete(TempRights, black_kingside, TempRights2)
    ;   FromRow = 8, FromCol = 1  % White queenside rook
    ->  delete(TempRights, white_queenside, TempRights2)
    ;   FromRow = 8, FromCol = 8  % White kingside rook
    ->  delete(TempRights, white_kingside, TempRights2)
    ;   TempRights2 = TempRights
    ),
    
    % If a rook is captured, remove its castling right
    (   ToRow = 1, ToCol = 1  % Black queenside rook
    ->  delete(TempRights2, black_queenside, NewCastlingRights)
    ;   ToRow = 1, ToCol = 8  % Black kingside rook
    ->  delete(TempRights2, black_kingside, NewCastlingRights)
    ;   ToRow = 8, ToCol = 1  % White queenside rook
    ->  delete(TempRights2, white_queenside, NewCastlingRights)
    ;   ToRow = 8, ToCol = 8  % White kingside rook
    ->  delete(TempRights2, white_kingside, NewCastlingRights)
    ;   NewCastlingRights = TempRights2
    ).

game_over(State, Winner) :-
    state(Board, Turn, _, _, _, _) = State,
    % Check if the king of the current player is in check
    (   Turn = white
    ->  KingPiece = white_king
    ;   KingPiece = black_king
    ),
    
    % Find the king's position
    nth1(KingRow, Board, Row),
    nth1(KingCol, Row, KingPiece),
    
    % Check if the king is in check
    is_in_check(Turn, KingRow, KingCol, Board),
    
    % Check if there are any legal moves for the current player
    \+ (legal_move(State, _)),
    
    % If the king is in check and there are no legal moves, it's checkmate
    Winner = (Turn = white -> black ; white).

game_over(State, draw) :-
    state(Board, Turn, _, _, _, _) = State,
    
    % Check if the king of the current player is NOT in check
    (   Turn = white
    ->  KingPiece = white_king
    ;   KingPiece = black_king
    ),
    
    % Find the king's position
    nth1(KingRow, Board, Row),
    nth1(KingCol, Row, KingPiece),
    
    % Check if the king is NOT in check
    \+ is_in_check(Turn, KingRow, KingCol, Board),
    
    % Check if there are no legal moves for the current player
    \+ (legal_move(State, _)).

is_in_check(Color, KingRow, KingCol, Board) :-
    % Check if any opponent piece can attack the king
    nth1(AttackerRow, Board, AttackerRowList),
    nth1(AttackerCol, AttackerRowList, AttackerPiece),
    AttackerPiece \= empty,
    piece_color(AttackerPiece, AttackerColor),
    Color \= AttackerColor,
    valid_piece_move(AttackerPiece, AttackerRow, AttackerCol, KingRow, KingCol, Board).

render_state(state(Board, Turn, _, _, _, _)) :-
    format('  a b c d e f g h~n'),
    render_board_rows(Board, 8),
    format('  a b c d e f g h~n'),
    format('Current player: ~w~n', [Turn]).

render_board_rows([], _).
render_board_rows([Row|Rest], RowNum) :-
    format('~w |', [RowNum]),
    render_row(Row),
    format('|~n'),
    NextRowNum is RowNum - 1,
    render_board_rows(Rest, NextRowNum).

render_row([]).
render_row([Piece|Rest]) :-
    (Piece = empty ->
        format(' .')
    ;
        piece_symbol(Piece, Symbol),
        format(' ~w', [Symbol])
    ),
    render_row(Rest).

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