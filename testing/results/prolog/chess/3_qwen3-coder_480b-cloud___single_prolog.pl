:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 8x8 list of lists, top row is rank 8 (black back rank)
% Rows 1-8, Cols 1-8. Access with nth1(Row, Board, RowList), nth1(Col, RowList, Piece)

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)
% Board = 8x8 list of lists
% Turn = white | black
% CastlingRights = list of atoms subset of [white_kingside, white_queenside, black_kingside, black_queenside]
% EnPassantTarget = null | [Row,Col]
% HalfmoveClock = integer
% FullmoveNumber = integer

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

current_player(state(_, Turn, _, _, _, _), Turn).

% Legal move generation - simplified version that checks basic move legality
% For full implementation, we'd need to check all piece movement rules, check, etc.
% Here we generate all possible moves and then filter with apply_move (which will fail for illegal moves)

legal_move(State, move(FromRow, FromCol, ToRow, ToCol, Promotion)) :-
    state(Board, Turn, _, _, _, _) = State,
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    Piece \= empty,
    piece_color(Piece, Turn),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    (ToRow =\= FromRow ; ToCol =\= FromCol),
    % Try all promotions for pawn moves to last rank
    (pawn_move_to_last_rank(Turn, FromRow, ToRow) ->
        member(Promotion, [queen, rook, bishop, knight])
    ;
        Promotion = none
    ),
    % apply_move will fail if this is illegal
    catch(apply_move(State, move(FromRow, FromCol, ToRow, ToCol, Promotion), _), _, fail).

piece_color(white_pawn, white).
piece_color(white_rook, white).
piece_color(white_knight, white).
piece_color(white_bishop, white).
piece_color(white_queen, white).
piece_color(white_king, white).
piece_color(black_pawn, black).
piece_color(black_rook, black).
piece_color(black_knight, black).
piece_color(black_bishop, black).
piece_color(black_queen, black).
piece_color(black_king, black).

pawn_move_to_last_rank(white, 7, 8).
pawn_move_to_last_rank(black, 2, 1).

% Apply move implementation
apply_move(State, Move, NewState) :-
    Move = move(FromRow, FromCol, ToRow, ToCol, Promotion),
    state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber) = State,
    
    % Get piece at source
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    Piece \= empty,
    piece_color(Piece, Turn),
    
    % Check if move is legal for the piece type
    legal_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget),
    
    % Check if move puts own king in check
    \+ move_puts_own_king_in_check(State, Move),
    
    % Apply the move
    % Remove piece from source
    set_cell(FromRow, FromCol, Board, empty, BoardAfterSource),
    
    % Handle capture (including en passant)
    (is_en_passant_capture(Piece, ToRow, ToCol, EnPassantTarget) ->
        % Remove captured pawn
        (Turn = white -> CapturedRow is ToRow + 1 ; CapturedRow is ToRow - 1),
        set_cell(CapturedRow, ToCol, BoardAfterSource, empty, BoardAfterCapture),
        Captured = true
    ;
        % Normal capture or move to empty square
        nth1(ToRow, BoardAfterSource, ToRowList),
        nth1(ToCol, ToRowList, TargetPiece),
        set_cell(ToRow, ToCol, BoardAfterSource, Piece, BoardAfterCapture),
        (TargetPiece = empty -> Captured = false ; Captured = true)
    ),
    
    % Handle promotion
    (Promotion = none ->
        FinalPiece = Piece
    ;
        (Turn = white -> atom_concat(white_, Promotion, FinalPiece)
        ; atom_concat(black_, Promotion, FinalPiece))
    ),
    
    % Place piece at destination (if not already done by capture handling)
    (is_en_passant_capture(Piece, ToRow, ToCol, EnPassantTarget) ->
        BoardAfterPlacement = BoardAfterCapture
    ;
        set_cell(ToRow, ToCol, BoardAfterCapture, FinalPiece, BoardAfterPlacement)
    ),
    
    % Handle castling
    (is_king_castling(Piece, FromRow, FromCol, ToRow, ToCol) ->
        handle_castling(FromRow, FromCol, ToRow, ToCol, BoardAfterPlacement, BoardAfterCastling)
    ;
        BoardAfterCastling = BoardAfterPlacement
    ),
    
    % Update castling rights
    update_castling_rights(Piece, FromRow, FromCol, CastlingRights, NewCastlingRights),
    
    % Update en passant target
    (is_pawn_double_move(Piece, FromRow, ToRow) ->
        (Turn = white -> EnPassantRow is FromRow - 1 ; EnPassantRow is FromRow + 1),
        NewEnPassantTarget = [EnPassantRow, FromCol]
    ;
        NewEnPassantTarget = null
    ),
    
    % Update clocks
    (Piece = white_pawn ; Piece = black_pawn ; Captured = true ->
        NewHalfmoveClock = 0
    ;
        NewHalfmoveClock is HalfmoveClock + 1
    ),
    
    % Update fullmove number
    (Turn = black ->
        NewFullmoveNumber is FullmoveNumber + 1
    ;
        NewFullmoveNumber = FullmoveNumber
    ),
    
    % Switch turn
    (Turn = white -> NextTurn = black ; NextTurn = white),
    
    NewState = state(BoardAfterCastling, NextTurn, NewCastlingRights, NewEnPassantTarget, NewHalfmoveClock, NewFullmoveNumber).

% Simplified piece move legality (without check detection)
legal_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board, EnPassantTarget) :-
    % Basic bounds check
    between(1, 8, FromRow), between(1, 8, FromCol),
    between(1, 8, ToRow), between(1, 8, ToCol),
    
    % Cannot capture own piece (except en passant which is handled separately)
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, TargetPiece),
    (TargetPiece = empty ; \+ piece_color(TargetPiece, Piece)),
    
    % Piece-specific movement
    (Piece = white_pawn ->
        (ToRow =:= FromRow - 1, ToCol =:= FromCol, TargetPiece = empty ;  % Move forward
         FromRow =:= 7, ToRow =:= 5, ToCol =:= FromCol, TargetPiece = empty,  % Double move from start
         ToRow =:= FromRow - 1, abs(ToCol - FromCol) =:= 1,  % Diagonal capture
         (TargetPiece \= empty, piece_color(TargetPiece, black) ;
          is_en_passant_capture(Piece, ToRow, ToCol, EnPassantTarget)))
    ;
    Piece = black_pawn ->
        (ToRow =:= FromRow + 1, ToCol =:= FromCol, TargetPiece = empty ;  % Move forward
         FromRow =:= 2, ToRow =:= 4, ToCol =:= FromCol, TargetPiece = empty,  % Double move from start
         ToRow =:= FromRow + 1, abs(ToCol - FromCol) =:= 1,  % Diagonal capture
         (TargetPiece \= empty, piece_color(TargetPiece, white) ;
          is_en_passant_capture(Piece, ToRow, ToCol, EnPassantTarget)))
    ;
    Piece = white_rook ; Piece = black_rook ->
        (rook_move(FromRow, FromCol, ToRow, ToCol), path_clear(FromRow, FromCol, ToRow, ToCol, Board))
    ;
    Piece = white_bishop ; Piece = black_bishop ->
        (bishop_move(FromRow, FromCol, ToRow, ToCol), path_clear(FromRow, FromCol, ToRow, ToCol, Board))
    ;
    Piece = white_queen ; Piece = black_queen ->
        ((rook_move(FromRow, FromCol, ToRow, ToCol) ; bishop_move(FromRow, FromCol, ToRow, ToCol)),
         path_clear(FromRow, FromCol, ToRow, ToCol, Board))
    ;
    Piece = white_king ; Piece = black_king ->
        king_move(FromRow, FromCol, ToRow, ToCol)
    ;
    Piece = white_knight ; Piece = black_knight ->
        knight_move(FromRow, FromCol, ToRow, ToCol)
    ).

rook_move(R1, C1, R2, C2) :- R1 =:= R2, C1 =\= C2.
rook_move(R1, C1, R2, C2) :- C1 =:= C2, R1 =\= R2.

bishop_move(R1, C1, R2, C2) :- abs(R2 - R1) =:= abs(C2 - C1), R1 =\= R2.

king_move(R1, C1, R2, C2) :- abs(R2 - R1) =< 1, abs(C2 - C1) =< 1, (R1 =\= R2 ; C1 =\= C2).

knight_move(R1, C1, R2, C2) :- 
    (abs(R2 - R1) =:= 2, abs(C2 - C1) =:= 1 ;
     abs(R2 - R1) =:= 1, abs(C2 - C1) =:= 2).

is_en_passant_capture(white_pawn, ToRow, ToCol, [EnPassantRow, EnPassantCol]) :-
    ToRow =:= EnPassantRow, ToCol =:= EnPassantCol.
is_en_passant_capture(black_pawn, ToRow, ToCol, [EnPassantRow, EnPassantCol]) :-
    ToRow =:= EnPassantRow, ToCol =:= EnPassantCol.
is_en_passant_capture(_, _, _, null) :- fail.

is_pawn_double_move(white_pawn, FromRow, ToRow) :- FromRow =:= 7, ToRow =:= 5.
is_pawn_double_move(black_pawn, FromRow, ToRow) :- FromRow =:= 2, ToRow =:= 4.
is_pawn_double_move(_, _, _) :- fail.

is_king_castling(white_king, 8, 5, 8, 7).  % Kingside
is_king_castling(white_king, 8, 5, 8, 3).  % Queenside
is_king_castling(black_king, 1, 5, 1, 7).  % Kingside
is_king_castling(black_king, 1, 5, 1, 3).  % Queenside

handle_castling(8, 5, 8, 7, Board, NewBoard) :-  % White kingside
    set_cell(8, 6, Board, white_rook, TempBoard),
    set_cell(8, 8, TempBoard, empty, NewBoard).
handle_castling(8, 5, 8, 3, Board, NewBoard) :-  % White queenside
    set_cell(8, 4, Board, white_rook, TempBoard),
    set_cell(8, 1, TempBoard, empty, NewBoard).
handle_castling(1, 5, 1, 7, Board, NewBoard) :-  % Black kingside
    set_cell(1, 6, Board, black_rook, TempBoard),
    set_cell(1, 8, TempBoard, empty, NewBoard).
handle_castling(1, 5, 1, 3, Board, NewBoard) :-  % Black queenside
    set_cell(1, 4, Board, black_rook, TempBoard),
    set_cell(1, 1, TempBoard, empty, NewBoard).

update_castling_rights(white_king, _, _, _, []).
update_castling_rights(black_king, _, _, _, []).
update_castling_rights(white_rook, 8, 1, CastlingRights, NewRights) :-  % Queenside rook
    delete(CastlingRights, white_queenside, NewRights).
update_castling_rights(white_rook, 8, 8, CastlingRights, NewRights) :-  % Kingside rook
    delete(CastlingRights, white_kingside, NewRights).
update_castling_rights(black_rook, 1, 1, CastlingRights, NewRights) :-  % Queenside rook
    delete(CastlingRights, black_queenside, NewRights).
update_castling_rights(black_rook, 1, 8, CastlingRights, NewRights) :-  % Kingside rook
    delete(CastlingRights, black_kingside, NewRights).
update_castling_rights(_, _, _, CastlingRights, CastlingRights).

path_clear(R1, C1, R2, C2, Board) :-
    R1 =:= R2, C1 =\= C2, !,  % Horizontal
    (C1 < C2 -> Dir = 1 ; Dir = -1),
    check_horizontal_path(R1, C1 + Dir, C2, Dir, Board).
path_clear(R1, C1, R2, C2, Board) :-
    C1 =:= C2, R1 =\= R2, !,  % Vertical
    (R1 < R2 -> Dir = 1 ; Dir = -1),
    check_vertical_path(C1, R1 + Dir, R2, Dir, Board).
path_clear(R1, C1, R2, C2, Board) :-  % Diagonal
    abs(R2 - R1) =:= abs(C2 - C1),
    (R2 > R1 -> RowDir = 1 ; RowDir = -1),
    (C2 > C1 -> ColDir = 1 ; ColDir = -1),
    check_diagonal_path(R1 + RowDir, C1 + ColDir, R2, C2, RowDir, ColDir, Board).

check_horizontal_path(_, C, C, _, _).
check_horizontal_path(R, C, EndC, Dir, Board) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, Piece),
    Piece = empty,
    NextC is C + Dir,
    check_horizontal_path(R, NextC, EndC, Dir, Board).

check_vertical_path(_, R, R, _, _).
check_vertical_path(C, R, EndR, Dir, Board) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, Piece),
    Piece = empty,
    NextR is R + Dir,
    check_vertical_path(C, NextR, EndR, Dir, Board).

check_diagonal_path(R, C, R, C, _, _, Board) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, Piece),
    Piece = empty.
check_diagonal_path(R, C, EndR, EndC, RowDir, ColDir, Board) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, Piece),
    Piece = empty,
    NextR is R + RowDir,
    NextC is C + ColDir,
    check_diagonal_path(NextR, NextC, EndR, EndC, RowDir, ColDir, Board).

% Simplified check detection for move validation
move_puts_own_king_in_check(State, Move) :-
    % This would require implementing full check detection, which is complex.
    % For now, we'll just fail this check to allow all moves through.
    % A full implementation would apply the move to a temporary board and see if the king is attacked.
    fail.

% Game over conditions - simplified
game_over(State, Winner) :-
    % Checkmate or stalemate detection would go here
    % For now, we'll just fail to indicate the game is ongoing
    fail.

% Render state
render_state(state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)) :-
    format('  a b c d e f g h~n'),
    render_board_rows(Board, 8),
    format('Turn: ~w~n', [Turn]),
    format('Castling: '),
    (CastlingRights = [] -> 
        format('none')
    ;
        maplist(write_castling_right, CastlingRights)
    ),
    format('~n'),
    format('En passant: ~w~n', [EnPassantTarget]),
    format('Halfmove clock: ~w~n', [HalfmoveClock]),
    format('Fullmove number: ~w~n', [FullmoveNumber]).

write_castling_right(Right) :-
    format('~w ', [Right]).

render_board_rows([], _).
render_board_rows([Row|Rest], N) :-
    format('~w ', [N]),
    render_board_row(Row),
    format('~n'),
    N1 is N - 1,
    render_board_rows(Rest, N1).

render_board_row([]).
render_board_row([Piece|Rest]) :-
    (Piece = empty -> format('. ')
    ; Piece = white_king -> format('K ')
    ; Piece = white_queen -> format('Q ')
    ; Piece = white_rook -> format('R ')
    ; Piece = white_bishop -> format('B ')
    ; Piece = white_knight -> format('N ')
    ; Piece = white_pawn -> format('P ')
    ; Piece = black_king -> format('k ')
    ; Piece = black_queen -> format('q ')
    ; Piece = black_rook -> format('r ')
    ; Piece = black_bishop -> format('b ')
    ; Piece = black_knight -> format('n ')
    ; Piece = black_pawn -> format('p ')
    ; format('? ')
    ),
    render_board_row(Rest).