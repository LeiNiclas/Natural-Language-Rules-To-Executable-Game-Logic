:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)
% Board = list of 8 rows, each a list of 8 atoms
% Turn = white | black
% CastlingRights = list of atoms subset of [white_kingside, white_queenside, black_kingside, black_queenside]
% EnPassantTarget = null | [Row, Col]
% HalfmoveClock = integer
% FullmoveNumber = integer

% Helper to set a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial board setup
initial_board([
    [black_rook, black_knight, black_bishop, black_queen, black_king, black_bishop, black_knight, black_rook],
    [black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn, black_pawn],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn, white_pawn],
    [white_rook, white_knight, white_bishop, white_queen, white_king, white_bishop, white_knight, white_rook]
]).

initial_state(state(Board, white, [white_kingside, white_queenside, black_kingside, black_queenside], null, 0, 1)) :-
    initial_board(Board).

current_player(state(_, Turn, _, _, _, _), Turn).

% Legal move generation and validation
legal_move(State, move(FromRow, FromCol, ToRow, ToCol, Promotion)) :-
    State = state(Board, Turn, _, _, _, _),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    piece_color(Piece, Turn),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, Target),
    (Target = empty ; piece_color(Target, Opponent), Opponent \= Turn),
    valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board),
    % Check that the move doesn't leave the king in check
    apply_move(State, move(FromRow, FromCol, ToRow, ToCol, none), TempState),
    \+ is_in_check(TempState, Turn).

% Piece color determination
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

% Valid move for each piece type
valid_piece_move(Piece, FromRow, FromCol, ToRow, ToCol, Board) :-
    delta_move(Piece, DR, DC),
    (DR =:= ToRow - FromRow, DC =:= ToCol - FromCol ; DR =:= FromRow - ToRow, DC =:= FromCol - ToCol),
    path_clear(FromRow, FromCol, ToRow, ToCol, Board).

% King moves one square in any direction
delta_move(white_king, DR, DC) :- member(DR, [-1, 0, 1]), member(DC, [-1, 0, 1]), (DR \= 0 ; DC \= 0).
delta_move(black_king, DR, DC) :- member(DR, [-1, 0, 1]), member(DC, [-1, 0, 1]), (DR \= 0 ; DC \= 0).

% Rook moves straight
delta_move(white_rook, DR, DC) :- (DR = 0, DC \= 0 ; DR \= 0, DC = 0).
delta_move(black_rook, DR, DC) :- (DR = 0, DC \= 0 ; DR \= 0, DC = 0).

% Bishop moves diagonally
delta_move(white_bishop, DR, DC) :- DR = DC ; DR = -DC.
delta_move(black_bishop, DR, DC) :- DR = DC ; DR = -DC.

% Queen moves straight or diagonally
delta_move(white_queen, DR, DC) :- 
    (DR = 0, DC \= 0 ; DR \= 0, DC = 0 ; DR = DC ; DR = -DC).
delta_move(black_queen, DR, DC) :- 
    (DR = 0, DC \= 0 ; DR \= 0, DC = 0 ; DR = DC ; DR = -DC).

% Knight moves in L-shape
delta_move(white_knight, DR, DC) :- 
    member((DR, DC), [(2,1),(2,-1),(-2,1),(-2,-1),(1,2),(1,-2),(-1,2),(-1,-2)]).
delta_move(black_knight, DR, DC) :- 
    member((DR, DC), [(2,1),(2,-1),(-2,1),(-2,-1),(1,2),(1,-2),(-1,2),(-1,-2)]).

% Pawn moves forward or captures diagonally
delta_move(white_pawn, DR, DC) :- DR = -1, (DC = 0 ; abs(DC) = 1).
delta_move(black_pawn, DR, DC) :- DR = 1, (DC = 0 ; abs(DC) = 1).

% Check if path is clear for non-knight pieces
path_clear(R1, C1, R2, C2, Board) :-
    (R1 = R2 -> 
        (C1 < C2 -> check_row_clear(R1, C1+1, C2-1, Board) ;
         C1 > C2 -> check_row_clear(R1, C2+1, C1-1, Board) ;
         true)
    ;
    C1 = C2 -> 
        (R1 < R2 -> check_col_clear(C1, R1+1, R2-1, Board) ;
         R1 > R2 -> check_col_clear(C1, R2+1, R1-1, Board) ;
         true)
    ;
    abs(R2 - R1) =:= abs(C2 - C1) -> 
        check_diag_clear(R1, C1, R2, C2, Board)
    ;
    true).

check_row_clear(_, Start, End, _) :- Start > End, !.
check_row_clear(Row, Col, End, Board) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    NextCol is Col + 1,
    check_row_clear(Row, NextCol, End, Board).

check_col_clear(_, Start, End, _) :- Start > End, !.
check_col_clear(Col, Row, End, Board) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    NextRow is Row + 1,
    check_col_clear(Col, NextRow, End, Board).

check_diag_clear(R1, C1, R2, C2, Board) :-
    DR is sign(R2 - R1),
    DC is sign(C2 - C1),
    check_diag_clear_step(R1+DR, C1+DC, R2, C2, DR, DC, Board).

check_diag_clear_step(R, C, R2, C2, _, _, _) :- R =:= R2, C =:= C2, !.
check_diag_clear_step(R, C, R2, C2, DR, DC, Board) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, empty),
    NextR is R + DR,
    NextC is C + DC,
    check_diag_clear_step(NextR, NextC, R2, C2, DR, DC, Board).

% Apply move
apply_move(State, Move, NewState) :-
    State = state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber),
    Move = move(FromRow, FromCol, ToRow, ToCol, Promotion),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    % Move piece
    set_cell(FromRow, FromCol, Board, empty, TempBoard1),
    (Promotion = none -> 
        set_cell(ToRow, ToCol, TempBoard1, Piece, NewBoard) ;
        (Turn = white -> 
            (Promotion = queen -> PromotedPiece = white_queen ;
             Promotion = rook -> PromotedPiece = white_rook ;
             Promotion = bishop -> PromotedPiece = white_bishop ;
             Promotion = knight -> PromotedPiece = white_knight) ;
         (Promotion = queen -> PromotedPiece = black_queen ;
          Promotion = rook -> PromotedPiece = black_rook ;
          Promotion = bishop -> PromotedPiece = black_bishop ;
          Promotion = knight -> PromotedPiece = black_knight)),
        set_cell(ToRow, ToCol, TempBoard1, PromotedPiece, NewBoard)
    ),
    % Update castling rights
    update_castling_rights(Piece, FromRow, FromCol, CastlingRights, NewCastlingRights),
    % Update en passant target
    (Piece = white_pawn, ToRow =:= FromRow - 2 -> 
        EnPassantSquare = [FromRow - 1, FromCol] ;
     Piece = black_pawn, ToRow =:= FromRow + 2 -> 
        EnPassantSquare = [FromRow + 1, FromCol] ;
     EnPassantSquare = null),
    % Update clocks
    (Piece = white_pawn ; Piece = black_pawn ; 
     nth1(ToRow, NewBoard, ToRowList), nth1(ToCol, ToRowList, Captured), Captured \= empty ->
        NewHalfmoveClock = 0 ;
        NewHalfmoveClock is HalfmoveClock + 1),
    (Turn = black -> NewFullmoveNumber is FullmoveNumber + 1 ; NewFullmoveNumber = FullmoveNumber),
    % Switch turn
    (Turn = white -> NextTurn = black ; NextTurn = white),
    NewState = state(NewBoard, NextTurn, NewCastlingRights, EnPassantSquare, NewHalfmoveClock, NewFullmoveNumber).

% Update castling rights when king or rook moves
update_castling_rights(white_king, _, _, _, []).
update_castling_rights(black_king, _, _, _, []).
update_castling_rights(white_rook, 8, 1, CastlingRights, NewCastlingRights) :-
    subtract(CastlingRights, [white_queenside], NewCastlingRights).
update_castling_rights(white_rook, 8, 8, CastlingRights, NewCastlingRights) :-
    subtract(CastlingRights, [white_kingside], NewCastlingRights).
update_castling_rights(black_rook, 1, 1, CastlingRights, NewCastlingRights) :-
    subtract(CastlingRights, [black_queenside], NewCastlingRights).
update_castling_rights(black_rook, 1, 8, CastlingRights, NewCastlingRights) :-
    subtract(CastlingRights, [black_kingside], NewCastlingRights).
update_castling_rights(_, _, _, CastlingRights, CastlingRights).

% Check if king is in check
is_in_check(state(Board, Turn, _, _, _, _), Turn) :-
    % Find king position
    find_piece(Board, Turn, king, KingRow, KingCol),
    % Check if any opponent piece attacks the king
    opponent(Turn, Opponent),
    member(ORow, [1,2,3,4,5,6,7,8]),
    member(OCol, [1,2,3,4,5,6,7,8]),
    nth1(ORow, Board, ORowList),
    nth1(OCol, ORowList, OPiece),
    piece_color(OPiece, Opponent),
    valid_piece_move(OPiece, ORow, OCol, KingRow, KingCol, Board).

% Find piece position
find_piece(Board, Color, PieceType, Row, Col) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece),
    piece_color(Piece, Color),
    atom_concat(Color, '_', Prefix),
    atom_concat(Prefix, PieceType, Piece).

% Opponent color
opponent(white, black).
opponent(black, white).

% Game over conditions
game_over(State, Winner) :-
    % Checkmate or stalemate
    \+ legal_move(State, _),
    (is_in_check(State, _) -> 
        current_player(State, Loser),
        (Loser = white -> Winner = black ; Winner = white) ;
        Winner = draw).

% Render state
render_state(state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)) :-
    format('  a b c d e f g h~n'),
    render_board(Board, 8),
    format('Turn: ~w~n', [Turn]),
    format('Castling: ~w~n', [CastlingRights]),
    format('En passant: ~w~n', [EnPassantTarget]),
    format('Halfmove clock: ~w~n', [HalfmoveClock]),
    format('Fullmove number: ~w~n', [FullmoveNumber]).

render_board([], _).
render_board([Row|Rest], N) :-
    format('~w ', [N]),
    render_row(Row),
    format('~n'),
    N1 is N - 1,
    render_board(Rest, N1).

render_row([]).
render_row([Piece|Rest]) :-
    (Piece = empty -> format('. ') ;
     Piece = white_king -> format('K ') ;
     Piece = white_queen -> format('Q ') ;
     Piece = white_rook -> format('R ') ;
     Piece = white_bishop -> format('B ') ;
     Piece = white_knight -> format('N ') ;
     Piece = white_pawn -> format('P ') ;
     Piece = black_king -> format('k ') ;
     Piece = black_queen -> format('q ') ;
     Piece = black_rook -> format('r ') ;
     Piece = black_bishop -> format('b ') ;
     Piece = black_knight -> format('n ') ;
     Piece = black_pawn -> format('p ')),
    render_row(Rest).