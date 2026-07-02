:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% set_cell(Row, Col, Board, Value, NewBoard)
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial_state(State)
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

% current_player(State, Player)
current_player(state(_, Player, _, _, _, _), Player).

% piece_color(Piece, Color)
piece_color(white_king,white).
piece_color(white_queen,white).
piece_color(white_rook,white).
piece_color(white_bishop,white).
piece_color(white_knight,white).
piece_color(white_pawn,white).
piece_color(black_king,black).
piece_color(black_queen,black).
piece_color(black_rook,black).
piece_color(black_bishop,black).
piece_color(black_knight,black).
piece_color(black_pawn,black).

% piece_type(Piece, Type)
piece_type(white_king,king).
piece_type(white_queen,queen).
piece_type(white_rook,rook).
piece_type(white_bishop,bishop).
piece_type(white_knight,knight).
piece_type(white_pawn,pawn).
piece_type(black_king,king).
piece_type(black_queen,queen).
piece_type(black_rook,rook).
piece_type(black_bishop,bishop).
piece_type(black_knight,knight).
piece_type(black_pawn,pawn).

% opponent(Player, Opponent)
opponent(white, black).
opponent(black, white).

% on_board(Row, Col)
on_board(R, C) :- between(1,8,R), between(1,8,C).

% cell_at(Board, Row, Col, Cell)
cell_at(Board, R, C, Cell) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, Cell).

% sign(Value, Sign)
sign(V, 1) :- V > 0.
sign(V, -1) :- V < 0.
sign(0, 0).

% clear_path(Board, FromR, FromC, ToR, ToC)
clear_path(Board, FR, FC, TR, TC) :-
    DR0 is TR - FR, DC0 is TC - FC,
    sign(DR0, DR), sign(DC0, DC),
    clear_step(Board, FR+DR, FC+DC, TR, TC, DR, DC).

% clear_step(Board, Row, Col, ToR, ToC, DR, DC)
clear_step(_, TR, TC, TR, TC, _, _) :- !.
clear_step(Board, R, C, TR, TC, DR, DC) :-
    cell_at(Board, R, C, empty),
    R1 is R + DR, C1 is C + DC,
    clear_step(Board, R1, C1, TR, TC, DR, DC).

% pawn_moves(State, FromR, FromC, Move)
pawn_moves(state(Board, white, _, EP, _, _), FR, FC, Move) :-
    TR is FR - 1, on_board(TR, FC),
    cell_at(Board, TR, FC, empty),
    ( TR > 1 ->
        Move = move(pawn,[FR,FC],[TR,FC])
    ; member(Prom, [queen,rook,bishop,knight]),
      Move = promote(pawn,[FR,FC],[TR,FC],Prom)
    ).
pawn_moves(state(Board, white, _, _, _, _), 7, FC, Move) :-
    cell_at(Board, 6, FC, empty),
    cell_at(Board, 5, FC, empty),
    Move = move(pawn,[7,FC],[5,FC]).
pawn_moves(state(Board, white, _, _, _, _), FR, FC, Move) :-
    TR is FR - 1,
    member(DC, [-1,1]),
    TC is FC + DC,
    on_board(TR, TC),
    cell_at(Board, TR, TC, P), piece_color(P,Black), Black \= white,
    ( TR > 1 ->
        Move = capture(pawn,[FR,FC],[TR,TC])
    ; member(Prom, [queen,rook,bishop,knight]),
      Move = promote(pawn,[FR,FC],[TR,TC],Prom)
    ).
pawn_moves(state(Board, white, _, EP, _, _), FR, FC, Move) :-
    EP \== null, EP = [TR,TC],
    TR is FR - 1,
    member(DC, [-1,1]), TC is FC + DC,
    on_board(TR,TC),
    Move = en_passant_capture(pawn,[FR,FC],[TR,TC]).

pawn_moves(state(Board, black, _, EP, _, _), FR, FC, Move) :-
    TR is FR + 1, on_board(TR, FC),
    cell_at(Board, TR, FC, empty),
    ( TR < 8 ->
        Move = move(pawn,[FR,FC],[TR,FC])
    ; member(Prom, [queen,rook,bishop,knight]),
      Move = promote(pawn,[FR,FC],[TR,FC],Prom)
    ).
pawn_moves(state(Board, black, _, _, _, _), 2, FC, Move) :-
    cell_at(Board, 3, FC, empty),
    cell_at(Board, 4, FC, empty),
    Move = move(pawn,[2,FC],[4,FC]).
pawn_moves(state(Board, black, _, _, _, _), FR, FC, Move) :-
    TR is FR + 1,
    member(DC, [-1,1]),
    TC is FC + DC,
    on_board(TR, TC),
    cell_at(Board, TR, TC, P), piece_color(P,White), White \= black,
    ( TR < 8 ->
        Move = capture(pawn,[FR,FC],[TR,TC])
    ; member(Prom, [queen,rook,bishop,knight]),
      Move = promote(pawn,[FR,FC],[TR,TC],Prom)
    ).
pawn_moves(state(Board, black, _, EP, _, _), FR, FC, Move) :-
    EP \== null, EP = [TR,TC],
    TR is FR + 1,
    member(DC, [-1,1]), TC is FC + DC,
    on_board(TR,TC),
    Move = en_passant_capture(pawn,[FR,FC],[TR,TC]).

% knight_moves(State, FromR, FromC, Move)
knight_moves(state(Board, Player, _, _, _, _), FR, FC, Move) :-
    member([DR,DC], [[2,1],[2,-1],[-2,1],[-2,-1],[1,2],[1,-2],[-1,2],[-1,-2]]),
    TR is FR + DR, TC is FC + DC,
    on_board(TR,TC),
    cell_at(Board, TR, TC, P),
    ( P = empty ->
        Move = move(knight,[FR,FC],[TR,TC])
    ; piece_color(P,Opp), Opp \= Player ->
        Move = capture(knight,[FR,FC],[TR,TC])
    ).

% king_moves(State, FromR, FromC, Move)
king_moves(state(Board, Player, _, _, _, _), FR, FC, Move) :-
    member([DR,DC], [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]),
    TR is FR + DR, TC is FC + DC,
    on_board(TR,TC),
    cell_at(Board, TR, TC, P),
    ( P = empty ->
        Move = move(king,[FR,FC],[TR,TC])
    ; piece_color(P,Opp), Opp \= Player ->
        Move = capture(king,[FR,FC],[TR,TC])
    ).

% sliding_moves(Type, Directions, State, FromR, FromC, Move)
sliding_moves(rook, [[1,0],[-1,0],[0,1],[0,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,1,0,rook,Move).
sliding_moves(rook, [[1,0],[-1,0],[0,1],[0,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,-1,0,rook,Move).
sliding_moves(rook, [[1,0],[-1,0],[0,1],[0,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,0,1,rook,Move).
sliding_moves(rook, [[1,0],[-1,0],[0,1],[0,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,0,-1,rook,Move).
sliding_moves(bishop, [[1,1],[1,-1],[-1,1],[-1,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,1,1,bishop,Move).
sliding_moves(bishop, [[1,1],[1,-1],[-1,1],[-1,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,1,-1,bishop,Move).
sliding_moves(bishop, [[1,1],[1,-1],[-1,1],[-1,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,-1,1,bishop,Move).
sliding_moves(bishop, [[1,1],[1,-1],[-1,1],[-1,-1]], state(Board,Player,_,_,_,_), FR, FC, Move) :-
    slide(Board,Player,FR,FC,-1,-1,bishop,Move).
sliding_moves(queen, Dirs, State, FR, FC, Move) :-
    sliding_moves(rook,Dirs,State, FR, FC, Move).
sliding_moves(queen, Dirs, State, FR, FC, Move) :-
    sliding_moves(bishop,Dirs,State, FR, FC, Move).

% slide(Board, Player, FromR, FromC, DR, DC, Type, Move)
slide(Board, Player, FR, FC, DR, DC, Type, Move) :-
    TR is FR + DR, TC is FC + DC,
    on_board(TR,TC),
    cell_at(Board,TR,TC,P),
    ( P = empty ->
        Move = move(Type,[FR,FC],[TR,TC])
    ; piece_color(P,Opp), Opp \= Player ->
        Move = capture(Type,[FR,FC],[TR,TC])
    ),
    ( P = empty ->
        slide(Board,Player,TR,TC,DR,DC,Type,_)
    ; true ).

% castling_moves(State, Move)
castling_moves(state(Board, white, Cast, _, _, _), Move) :-
    member(white_kingside, Cast),
    cell_at(Board,8,5,white_king),
    cell_at(Board,8,6,empty),
    cell_at(Board,8,7,empty),
    cell_at(Board,8,8,white_rook),
    Move = castle(white,kingside).
castling_moves(state(Board, white, Cast, _, _, _), Move) :-
    member(white_queenside, Cast),
    cell_at(Board,8,5,white_king),
    cell_at(Board,8,4,empty),
    cell_at(Board,8,3,empty),
    cell_at(Board,8,2,empty),
    cell_at(Board,8,1,white_rook),
    Move = castle(white,queenside).
castling_moves(state(Board, black, Cast, _, _, _), Move) :-
    member(black_kingside, Cast),
    cell_at(Board,1,5,black_king),
    cell_at(Board,1,6,empty),
    cell_at(Board,1,7,empty),
    cell_at(Board,1,8,black_rook),
    Move = castle(black,kingside).
castling_moves(state(Board, black, Cast, _, _, _), Move) :-
    member(black_queenside, Cast),
    cell_at(Board,1,5,black_king),
    cell_at(Board,1,4,empty),
    cell_at(Board,1,3,empty),
    cell_at(Board,1,2,empty),
    cell_at(Board,1,1,black_rook),
    Move = castle(black,queenside).

% legal_move(State, Move)
legal_move(State, Move) :-
    State = state(Board, Player, _, _, _, _),
    between(1,8,FR), between(1,8,FC),
    cell_at(Board, FR, FC, Piece),
    piece_color(Piece, Player),
    piece_type(Piece, Type),
    ( Type = pawn   -> pawn_moves(State, FR, FC, Move)
    ; Type = knight -> knight_moves(State, FR, FC, Move)
    ; Type = king   -> ( king_moves(State, FR, FC, Move)
                      ; castling_moves(State, Move) )
    ; Type = rook   -> sliding_moves(rook,_, State, FR, FC, Move)
    ; Type = bishop -> sliding_moves(bishop,_, State, FR, FC, Move)
    ; Type = queen  -> sliding_moves(queen,_, State, FR, FC, Move)
    ).

% remove_right(CastlingRights, Right, NewRights)
remove_right(Cast, Right, NewCast) :-
    ( select(Right, Cast, Temp) -> NewCast = Temp ; NewCast = Cast ).

% update_move_castling(Cast, Turn, Type, FromR, FromC, NewCast)
update_move_castling(Cast, white, king, _, _, CastOut) :-
    remove_right(Cast, white_kingside, T1),
    remove_right(T1, white_queenside, CastOut).
update_move_castling(Cast, black, king, _, _, CastOut) :-
    remove_right(Cast, black_kingside, T1),
    remove_right(T1, black_queenside, CastOut).
update_move_castling(Cast, white, rook, 8, 1, CastOut) :-
    remove_right(Cast, white_queenside, CastOut).
update_move_castling(Cast, white, rook, 8, 8, CastOut) :-
    remove_right(Cast, white_kingside, CastOut).
update_move_castling(Cast, black, rook, 1, 1, CastOut) :-
    remove_right(Cast, black_queenside, CastOut).
update_move_castling(Cast, black, rook, 1, 8, CastOut) :-
    remove_right(Cast, black_kingside, CastOut).
update_move_castling(Cast, _, _, _, _, Cast).

% update_capture_castling(Cast, Board, ToR, ToC, NewCast)
update_capture_castling(Cast, Board, TR, TC, CastOut) :-
    cell_at(Board, TR, TC, P),
    piece_type(P, rook),
    piece_color(P, Color),
    ( Color = white ->
        ( (TR = 8, TC = 1, Right = white_queenside) ;
          (TR = 8, TC = 8, Right = white_kingside) )
    ; Color = black ->
        ( (TR = 1, TC = 1, Right = black_queenside) ;
          (TR = 1, TC = 8, Right = black_kingside) )
    ),
    !,
    remove_right(Cast, Right, CastOut).
update_capture_castling(Cast, _, _, _, Cast).

% promotion_piece(Color, Promotion, PieceAtom)
promotion_piece(white, queen, white_queen).
promotion_piece(white, rook, white_rook).
promotion_piece(white, bishop, white_bishop).
promotion_piece(white, knight, white_knight).
promotion_piece(black, queen, black_queen).
promotion_piece(black, rook, black_rook).
promotion_piece(black, bishop, black_bishop).
promotion_piece(black, knight, black_knight).

% apply_move for a simple move
apply_move(state(Board, Turn, Cast, _, HMC, FN), move(Type, [FR,FC], [TR,TC]),
          state(NewBoard, Next, FinalCast, EP2, HMC2, FN2)) :-
    cell_at(Board, FR, FC, P),
    piece_type(P, Type),
    piece_color(P, Turn),
    set_cell(FR, FC, Board, empty, B1),
    set_cell(TR, TC, B1, P, B2),
    Diff is TR - FR,
    ( Type = pawn, (Diff =:= 2 ; Diff =:= -2) ->
        MRow is (FR + TR) // 2,
        EP2 = [MRow, FC]
    ; EP2 = null ),
    update_move_castling(Cast, Turn, Type, FR, FC, Cast1),
    update_capture_castling(Cast1, Board, TR, TC, FinalCast),
    ( Type = pawn -> HMC2 = 0 ; HMC2 is HMC + 1 ),
    opponent(Turn, Next),
    ( Turn = black -> FN2 is FN + 1 ; FN2 = FN ),
    NewBoard = B2.

% apply_move for a capture
apply_move(state(Board, Turn, Cast, _, HMC, FN), capture(Type, [FR,FC], [TR,TC]),
          state(NewBoard, Next, FinalCast, null, 0, FN2)) :-
    cell_at(Board, FR, FC, P),
    piece_type(P, Type),
    piece_color(P, Turn),
    set_cell(FR, FC, Board, empty, B1),
    set_cell(TR, TC, B1, P, NewBoard),
    update_move_castling(Cast, Turn, Type, FR, FC, Cast1),
    update_capture_castling(Cast1, Board, TR, TC, FinalCast),
    opponent(Turn, Next),
    ( Turn = black -> FN2 is FN + 1 ; FN2 = FN ).

% apply_move for a promotion without capture
apply_move(state(Board, Turn, Cast, _, _, FN), promote(pawn, [FR,FC], [TR,TC], Prom),
          state(NewBoard, Next, Cast, null, 0, FN2)) :-
    cell_at(Board, FR, FC, P0),
    piece_color(P0, Turn),
    promotion_piece(Turn, Prom, P),
    set_cell(FR, FC, Board, empty, B1),
    set_cell(TR, TC, B1, P, NewBoard),
    opponent(Turn, Next),
    ( Turn = black -> FN2 is FN + 1 ; FN2 = FN ).

% apply_move for an en passant capture
apply_move(state(Board, Turn, Cast, _, _, FN), en_passant_capture(pawn, [FR,FC], [TR,TC]),
          state(NewBoard, Next, Cast, null, 0, FN2)) :-
    cell_at(Board, FR, FC, P),
    piece_color(P, Turn),
    set_cell(FR, FC, Board, empty, B1),
    ( Turn = white -> CaptR is FR, CaptC is TC ; CaptR is FR, CaptC is TC ),
    set_cell(CaptR, CaptC, B1, empty, B2),
    set_cell(TR, TC, B2, P, NewBoard),
    opponent(Turn, Next),
    ( Turn = black -> FN2 is FN + 1 ; FN2 = FN ).

% apply_move for castling
apply_move(state(Board, white, Cast, _, HMC, FN), castle(white, kingside),
          state(NewBoard, black, Cast2, null, HMC2, FN)) :-
    set_cell(8,5,Board,empty,B1),
    set_cell(8,8,B1,empty,B2),
    set_cell(8,7,B2,white_king,B3),
    set_cell(8,6,B3,white_rook,NewBoard),
    update_move_castling(Cast, white, king, 8, 5, Cast2),
    HMC2 is HMC + 1.
apply_move(state(Board, white, Cast, _, HMC, FN), castle(white, queenside),
          state(NewBoard, black, Cast2, null, HMC2, FN)) :-
    set_cell(8,5,Board,empty,B1),
    set_cell(8,1,B1,empty,B2),
    set_cell(8,3,B2,white_king,B3),
    set_cell(8,4,B3,white_rook,NewBoard),
    update_move_castling(Cast, white, king, 8, 5, Cast2),
    HMC2 is HMC + 1.
apply_move(state(Board, black, Cast, _, HMC, FN), castle(black, kingside),
          state(NewBoard, white, Cast2, null, HMC2, FN2)) :-
    set_cell(1,5,Board,empty,B1),
    set_cell(1,8,B1,empty,B2),
    set_cell(1,7,B2,black_king,B3),
    set_cell(1,6,B3,black_rook,NewBoard),
    update_move_castling(Cast, black, king, 1, 5, Cast2),
    HMC2 is HMC + 1,
    FN2 is FN + 1.
apply_move(state(Board, black, Cast, _, HMC, FN), castle(black, queenside),
          state(NewBoard, white, Cast2, null, HMC2, FN2)) :-
    set_cell(1,5,Board,empty,B1),
    set_cell(1,1,B1,empty,B2),
    set_cell(1,3,B2,black_king,B3),
    set_cell(1,4,B3,black_rook,NewBoard),
    update_move_castling(Cast, black, king, 1, 5, Cast2),
    HMC2 is HMC + 1,
    FN2 is FN + 1.

% king_piece(Color, KingAtom)
king_piece(white, white_king).
king_piece(black, black_king).

% king_pos(Board, KingAtom, [Row,Col])
king_pos(Board, King, [R,C]) :-
    between(1,8,R),
    between(1,8,C),
    cell_at(Board, R, C, King).

% in_check(State, Player)
in_check(state(Board, _, Cast, EP, HMC, FN), Player) :-
    opponent(Player, Opp),
    king_piece(Player, King),
    king_pos(Board, King, [KR,KC]),
    StateOpp = state(Board, Opp, Cast, EP, HMC, FN),
    legal_move(StateOpp, capture(_, [_FRow,_FCol], [KR,KC])).

% game_over(State, Winner)
game_over(State, Winner) :-
    current_player(State, Player),
    \+ legal_move(State, _),
    ( in_check(State, Player) ->
        opponent(Player, Winner)
    ; Winner = draw ).

% symbol mapping for rendering
symbol(empty,'.').
symbol(white_king,'K').
symbol(white_queen,'Q').
symbol(white_rook,'R').
symbol(white_bishop,'B').
symbol(white_knight,'N').
symbol(white_pawn,'P').
symbol(black_king,'k').
symbol(black_queen,'q').
symbol(black_rook,'r').
symbol(black_bishop,'b').
symbol(black_knight,'n').
symbol(black_pawn,'p').

% render_state(State) prints the board and current player
render_state(state(Board, Turn, _, _, _, _)) :-
    print_rows(Board,1),
    format('    a b c d e f g h~n',[]),
    format('Current player: ~w~n',[Turn]).

% print_rows(Board, Index)
print_rows(_,9) :- !.
print_rows(Board,I) :-
    nth1(I,Board,Row),
    Rank is 9 - I,
    format('~d | ',[Rank]),
    print_row(Row),
    nl,
    I1 is I + 1,
    print_rows(Board,I1).

% print_row(Row)
print_row([]).
print_row([C]) :-
    symbol(C,S),
    format('~w',[S]).
print_row([C|Cs]) :-
    symbol(C,S),
    format('~w ',[S]),
    print_row(Cs).