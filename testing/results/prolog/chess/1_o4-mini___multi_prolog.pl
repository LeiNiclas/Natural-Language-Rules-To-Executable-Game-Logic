:- use_module(library(lists)).
:- use_module(library(apply)).

% set Nth element of a list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% set cell at row I, column J in a 2D list
set_cell(I, J, Board, Val, NewBoard) :-
    nth1(I, Board, Row),
    set_nth1(J, Row, Val, NewRow),
    set_nth1(I, Board, NewRow, NewBoard).

% initial chess state: board, turn, castling rights, en passant target, halfmove clock, fullmove number
initial_state(state(
    [[black_rook,black_knight,black_bishop,black_queen,black_king,black_bishop,black_knight,black_rook],
     [black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn],
     [empty,empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty,empty],
     [white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn],
     [white_rook,white_knight,white_bishop,white_queen,white_king,white_bishop,white_knight,white_rook]],
    white,
    [white_kingside,white_queenside,black_kingside,black_queenside],
    null,
    0,
    1
)).

% current player to move
current_player(state(_, Turn, _, _, _, _), Turn).

% legal moves: castling and piece moves
legal_move(State, castle(Turn, Side)) :-
    State = state(Board, Turn, CastlingRights, _, _, _),
    castling_move_positions(Turn, Side, _KingRow, _KingCol, _RookCol, PathCols),
    atom_concat(Turn, '_', T1),
    atom_concat(T1, Side, SideAtom),
    member(SideAtom, CastlingRights),
    State = state(Board, _, _, _, _, _),
    get_cell(Board, _KR, _KC, _),
    check_empty_squares(Board, _KR, PathCols).

legal_move(State, move(Piece, from(R1,C1), to(R2,C2), Promotion)) :-
    State = state(Board, _, _, EnPassant, _, _),
    get_cell(Board, R1, C1, Piece),
    Piece \= empty,
    piece_color(Piece, Turn),
    piece_specific_moves(Piece, R1, C1, Turn, Board, EnPassant, R2, C2, Promotion).

% castling positions
castling_move_positions(white, kingside, 8, 5, 8, [6,7]).
castling_move_positions(white, queenside, 8, 5, 1, [2,3,4]).
castling_move_positions(black, kingside, 1, 5, 8, [6,7]).
castling_move_positions(black, queenside, 1, 5, 1, [2,3,4]).

check_empty_squares(Board, Row, Cols) :-
    forall(member(C, Cols), get_cell(Board, Row, C, empty)).

get_cell(Board, R, C, Cell) :-
    nth1(R, Board, Row),
    nth1(C, Row, Cell).

in_bounds(R, C) :-
    R >= 1, R =< 8,
    C >= 1, C =< 8.

piece_color(Piece, white) :-
    atom_concat(white_, _, Piece).
piece_color(Piece, black) :-
    atom_concat(black_, _, Piece).

% white pawn moves
piece_specific_moves(white_pawn, R1, C1, white, Board, _EnPassant, R2, C1, Promotion) :-
    R2 is R1 - 1,
    in_bounds(R2, C1),
    get_cell(Board, R2, C1, empty),
    ( R2 = 1 ->
        member(Promotion, [queen, rook, bishop, knight])
    ; Promotion = none ).
piece_specific_moves(white_pawn, 7, C1, white, Board, _EnPassant, 5, C1, none) :-
    get_cell(Board, 6, C1, empty),
    get_cell(Board, 5, C1, empty).
piece_specific_moves(white_pawn, R1, C1, white, Board, _EnPassant, R2, C2, Promotion) :-
    R2 is R1 - 1,
    member(DC, [-1, 1]),
    C2 is C1 + DC,
    in_bounds(R2, C2),
    get_cell(Board, R2, C2, Cell),
    Cell \= empty,
    piece_color(Cell, black),
    ( R2 = 1 ->
        member(Promotion, [queen, rook, bishop, knight])
    ; Promotion = none ).
piece_specific_moves(white_pawn, R1, C1, white, Board, [R2,C2], R2, C2, none) :-
    R2 is R1 - 1,
    member(DC, [-1, 1]),
    C2 is C1 + DC,
    in_bounds(R2, C2),
    get_cell(Board, R2, C2, empty),
    get_cell(Board, R1, C2, Cell),
    piece_color(Cell, black).

% black pawn moves
piece_specific_moves(black_pawn, R1, C1, black, Board, _EnPassant, R2, C1, Promotion) :-
    R2 is R1 + 1,
    in_bounds(R2, C1),
    get_cell(Board, R2, C1, empty),
    ( R2 = 8 ->
        member(Promotion, [queen, rook, bishop, knight])
    ; Promotion = none ).
piece_specific_moves(black_pawn, 2, C1, black, Board, _EnPassant, 4, C1, none) :-
    get_cell(Board, 3, C1, empty),
    get_cell(Board, 4, C1, empty).
piece_specific_moves(black_pawn, R1, C1, black, Board, _EnPassant, R2, C2, Promotion) :-
    R2 is R1 + 1,
    member(DC, [-1, 1]),
    C2 is C1 + DC,
    in_bounds(R2, C2),
    get_cell(Board, R2, C2, Cell),
    Cell \= empty,
    piece_color(Cell, white),
    ( R2 = 8 ->
        member(Promotion, [queen, rook, bishop, knight])
    ; Promotion = none ).
piece_specific_moves(black_pawn, R1, C1, black, Board, [R2,C2], R2, C2, none) :-
    R2 is R1 + 1,
    member(DC, [-1, 1]),
    C2 is C1 + DC,
    in_bounds(R2, C2),
    get_cell(Board, R2, C2, empty),
    get_cell(Board, R1, C2, Cell),
    piece_color(Cell, white).

% knight moves
piece_specific_moves(Piece, R1, C1, Turn, Board, _EnPassant, R2, C2, none) :-
    (Piece = white_knight; Piece = black_knight),
    knight_offset(DR, DC),
    R2 is R1 + DR,
    C2 is C1 + DC,
    in_bounds(R2, C2),
    get_cell(Board, R2, C2, Cell),
    ( Cell = empty
    ; (piece_color(Cell, PC), PC \= Turn)
    ).
knight_offset(2, 1).
knight_offset(2, -1).
knight_offset(-2, 1).
knight_offset(-2, -1).
knight_offset(1, 2).
knight_offset(1, -2).
knight_offset(-1, 2).
knight_offset(-1, -2).

% king moves
piece_specific_moves(Piece, R1, C1, Turn, Board, _EnPassant, R2, C2, none) :-
    (Piece = white_king; Piece = black_king),
    king_offset(DR, DC),
    R2 is R1 + DR,
    C2 is C1 + DC,
    in_bounds(R2, C2),
    get_cell(Board, R2, C2, Cell),
    ( Cell = empty
    ; (piece_color(Cell, PC), PC \= Turn)
    ).
king_offset(1, 0).
king_offset(-1, 0).
king_offset(0, 1).
king_offset(0, -1).
king_offset(1, 1).
king_offset(1, -1).
king_offset(-1, 1).
king_offset(-1, -1).

% sliding moves for rook
piece_specific_moves(Piece, R1, C1, Turn, Board, _EnPassant, R2, C2, none) :-
    (Piece = white_rook; Piece = black_rook),
    member((DR, DC), [(1,0),(-1,0),(0,1),(0,-1)]),
    slide(R1, C1, DR, DC, Turn, Board, R2, C2).

% sliding moves for bishop
piece_specific_moves(Piece, R1, C1, Turn, Board, _EnPassant, R2, C2, none) :-
    (Piece = white_bishop; Piece = black_bishop),
    member((DR, DC), [(1,1),(1,-1),(-1,1),(-1,-1)]),
    slide(R1, C1, DR, DC, Turn, Board, R2, C2).

% sliding moves for queen
piece_specific_moves(Piece, R1, C1, Turn, Board, _EnPassant, R2, C2, none) :-
    (Piece = white_queen; Piece = black_queen),
    member((DR, DC), [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]),
    slide(R1, C1, DR, DC, Turn, Board, R2, C2).

slide(R, C, DR, DC, Turn, Board, R2, C2) :-
    Rn is R + DR,
    Cn is C + DC,
    in_bounds(Rn, Cn),
    get_cell(Board, Rn, Cn, Cell),
    ( Cell = empty ->
        ( R2 = Rn, C2 = Cn
        ; slide(Rn, Cn, DR, DC, Turn, Board, R2, C2)
        )
    ; (piece_color(Cell, PC), PC \= Turn) ->
        R2 = Rn, C2 = Cn
    ).

% switch player
other(white, black).
other(black, white).

% update castling rights after move
update_castling_rights(Piece, R1, C1, Turn, CR, CRNew) :-
    ( (Piece = white_king; Piece = black_king) ->
        atom_concat(Turn,'_kingside',KS),
        delete(CR, KS, CR1),
        atom_concat(Turn,'_queenside',QS),
        delete(CR1, QS, CRNew)
    ; Piece = white_rook, R1 = 8, C1 = 1 ->
        atom_concat(Turn,'_queenside',QS),
        delete(CR, QS, CRNew)
    ; Piece = white_rook, R1 = 8, C1 = 8 ->
        atom_concat(Turn,'_kingside',KS),
        delete(CR, KS, CRNew)
    ; Piece = black_rook, R1 = 1, C1 = 1 ->
        atom_concat(Turn,'_queenside',QS),
        delete(CR, QS, CRNew)
    ; Piece = black_rook, R1 = 1, C1 = 8 ->
        atom_concat(Turn,'_kingside',KS),
        delete(CR, KS, CRNew)
    ; CRNew = CR).

% apply move to state
apply_move(State, castle(Turn, Side), NewState) :-
    State = state(Board, Turn, CR, _, HMC, FMC),
    legal_move(State, castle(Turn, Side)),
    castling_move_positions(Turn, Side, KRow, KCol, ROrigCol, _),
    ( Side = kingside ->
        KDestC is KCol+2,
        RDestC is KCol+1
    ; Side = queenside ->
        KDestC is KCol-2,
        RDestC is KCol-1
    ),
    set_cell(KRow, KCol, Board, empty, B1),
    set_cell(KRow, ROrigCol, B1, empty, B2),
    atom_concat(Turn,'_king', PieceKing),
    set_cell(KRow, KDestC, B2, PieceKing, B3),
    atom_concat(Turn,'_rook', PieceRook),
    set_cell(KRow, RDestC, B3, PieceRook, BoardNew),
    atom_concat(Turn,'_kingside',KS),
    delete(CR, KS, CR1),
    atom_concat(Turn,'_queenside',QS),
    delete(CR1, QS, CRNew),
    EPNew = null,
    HMCNew is HMC+1,
    ( Turn = black -> FMCNew is FMC+1 ; FMCNew = FMC ),
    other(Turn, NextTurn),
    NewState = state(BoardNew, NextTurn, CRNew, EPNew, HMCNew, FMCNew).

apply_move(State, move(Piece, from(R1,C1), to(R2,C2), Promotion), NewState) :-
    State = state(Board, Turn, CR, EPOld, HMC, FMC),
    legal_move(State, move(Piece, from(R1,C1), to(R2,C2), Promotion)),
    get_cell(Board, R2, C2, DestCell),
    ( EPOld = [R2,C2] -> EpCapture = true ; EpCapture = false ),
    set_cell(R1, C1, Board, empty, B1),
    ( EpCapture = true ->
        ( Turn = white -> VictR is R2+1 ; VictR is R2-1 ),
        set_cell(VictR, C2, B1, empty, B2)
    ; B2 = B1 ),
    ( Promotion = none -> NewPiece = Piece
    ; atom_concat(Turn, '_', Tmp), atom_concat(Tmp, Promotion, NewPiece) ),
    set_cell(R2, C2, B2, NewPiece, BoardNew),
    update_castling_rights(Piece, R1, C1, Turn, CR, CRNew),
    ( (Piece = white_pawn; Piece = black_pawn), Diff is R2-R1, abs(Diff) =:= 2 ->
        MidR is (R1+R2)//2,
        EPNew = [MidR, C1]
    ; EPNew = null ),
    ( EpCapture = true ; DestCell \= empty -> Capture = true ; Capture = false ),
    ( Piece = white_pawn ; Piece = black_pawn ; Capture = true -> HMCNew = 0 ; HMCNew is HMC+1 ),
    ( Turn = black -> FMCNew is FMC+1 ; FMCNew = FMC ),
    other(Turn, NextTurn),
    NewState = state(BoardNew, NextTurn, CRNew, EPNew, HMCNew, FMCNew).

% find king position for Player
find_king(Board, Player, R, C) :-
    atom_concat(Player, '_king', King),
    nth1(R, Board, Row),
    nth1(C, Row, King).

% pawn attack detection
attacked_by_pawn(Board, white, R, C) :-
    R1 is R+1,
    member(DC, [1, -1]),
    C1 is C+DC,
    in_bounds(R1, C1),
    get_cell(Board, R1, C1, white_pawn).
attacked_by_pawn(Board, black, R, C) :-
    R1 is R-1,
    member(DC, [1, -1]),
    C1 is C+DC,
    in_bounds(R1, C1),
    get_cell(Board, R1, C1, black_pawn).

% knight attack detection
attacked_by_knight(Board, Opp, R, C) :-
    knight_offset(DR, DC),
    R1 is R+DR,
    C1 is C+DC,
    in_bounds(R1, C1),
    atom_concat(Opp, '_knight', Knight),
    get_cell(Board, R1, C1, Knight).

% king attack detection
attacked_by_king(Board, Opp, R, C) :-
    king_offset(DR, DC),
    R1 is R+DR,
    C1 is C+DC,
    in_bounds(R1, C1),
    atom_concat(Opp, '_king', King),
    get_cell(Board, R1, C1, King).

% sliding attack detection
attacked_by_slider(Board, Opp, R, C) :-
    member((DR, DC), [(1,0),(-1,0),(0,1),(0,-1)]),
    scan_dir(Board, Opp, R, C, DR, DC, ortho).
attacked_by_slider(Board, Opp, R, C) :-
    member((DR, DC), [(1,1),(1,-1),(-1,1),(-1,-1)]),
    scan_dir(Board, Opp, R, C, DR, DC, diag).

scan_dir(Board, Opp, R, C, DR, DC, ortho) :-
    R1 is R+DR,
    C1 is C+DC,
    in_bounds(R1, C1),
    get_cell(Board, R1, C1, Cell),
    ( Cell = empty ->
        scan_dir(Board, Opp, R1, C1, DR, DC, ortho)
    ; piece_color(Cell, Opp),
      ( atom_concat(Opp, '_rook', Cell)
      ; atom_concat(Opp, '_queen', Cell)
      )
    ).
scan_dir(Board, Opp, R, C, DR, DC, diag) :-
    R1 is R+DR,
    C1 is C+DC,
    in_bounds(R1, C1),
    get_cell(Board, R1, C1, Cell),
    ( Cell = empty ->
        scan_dir(Board, Opp, R1, C1, DR, DC, diag)
    ; piece_color(Cell, Opp),
      ( atom_concat(Opp, '_bishop', Cell)
      ; atom_concat(Opp, '_queen', Cell)
      )
    ).

% any attack on R,C by Opponent
attacked_by(Board, Opp, R, C) :-
    attacked_by_pawn(Board, Opp, R, C)
    ; attacked_by_knight(Board, Opp, R, C)
    ; attacked_by_slider(Board, Opp, R, C)
    ; attacked_by_king(Board, Opp, R, C).

% check if Player is in check
in_check(state(Board, _, _, _, _, _), Player) :-
    other(Player, Opp),
    find_king(Board, Player, R, C),
    attacked_by(Board, Opp, R, C).

% no legal moves that avoid check
no_legal_moves(State) :-
    State = state(_, Turn, _, _, _, _),
    \+ ( legal_move(State, M),
         apply_move(State, M, NS),
         \+ in_check(NS, Turn)
       ).

% game over detection: checkmate or stalemate
game_over(State, Winner) :-
    State = state(_, Turn, _, _, _, _),
    no_legal_moves(State),
    ( in_check(State, Turn) ->
        other(Turn, Winner)
    ; Winner = draw ).

% mapping cells to symbols
cell_symbol(empty, '.').
cell_symbol(white_pawn, 'P').
cell_symbol(white_knight, 'N').
cell_symbol(white_bishop, 'B').
cell_symbol(white_rook, 'R').
cell_symbol(white_queen, 'Q').
cell_symbol(white_king, 'K').
cell_symbol(black_pawn, 'p').
cell_symbol(black_knight, 'n').
cell_symbol(black_bishop, 'b').
cell_symbol(black_rook, 'r').
cell_symbol(black_queen, 'q').
cell_symbol(black_king, 'k').

% render a single row
render_row([]).
render_row([Cell]) :-
    cell_symbol(Cell, Sym),
    format('~w', [Sym]).
render_row([Cell|Cells]) :-
    cell_symbol(Cell, Sym),
    format('~w ', [Sym]),
    render_row(Cells).

% render all rows with rank labels
render_rows([], 9).
render_rows([Row|Rows], I) :-
    Rank is 9 - I,
    format('~w | ', [Rank]),
    render_row(Row),
    nl,
    I1 is I+1,
    render_rows(Rows, I1).

% render the full board and current player
render_state(state(Board, Turn, _, _, _, _)) :-
    render_rows(Board, 1),
    format('    a b c d e f g h\n', []),
    format('Current player: ~w\n', [Turn]).