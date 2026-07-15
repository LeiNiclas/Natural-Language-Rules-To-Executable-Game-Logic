:- use_module(library(lists)).
:- use_module(library(apply)).

% 2D board helpers
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% state(Board, Turn, CastlingRights, EnPassantTarget, HalfmoveClock, FullmoveNumber)

initial_state(state(
    [
      [black_rook,black_knight,black_bishop,black_queen,black_king,black_bishop,black_knight,black_rook],
      [black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn],
      [white_rook,white_knight,white_bishop,white_queen,white_king,white_bishop,white_knight,white_rook]
    ],
    white,
    [white_kingside,white_queenside,black_kingside,black_queenside],
    none,
    0,
    1
)).

current_player(state(_, Turn, _, _, _, _), Turn).

% pseudo-legal move generation
legal_move(State, move(FR,FC,TR,TC,none)) :-
    State = state(Board,Turn,_,EP,_,_),
    between(1,8,FR), between(1,8,FC),
    piece_at(Board,FR,FC,Piece),
    piece_color(Piece,Turn),
    between(1,8,TR), between(1,8,TC),
    (FR \= TR ; FC \= TC),
    valid_destination(Board,Turn,FR,FC,TR,TC,EP),
    piece_moves(Piece,[FR,FC],[TR,TC],Board).

apply_move(State, move(FR,FC,TR,TC,none), NewState) :-
    State = state(Board,Turn,CR,EP,HM,FN),
    do_move(Board,Turn,FR,FC,TR,TC,none,EP,CR,NewBoard,NewEP,Capture),
    switch_turn(Turn,NextTurn),
    update_clocks(HM,Capture,NextTurn,FN,NewHM,NewFN),
    update_castling_rights(CR,FR,FC,TR,TC,NewCR),
    NewState = state(NewBoard,NextTurn,NewCR,NewEP,NewHM,NewFN).

game_over(State, Winner) :-
    current_player(State,Turn),
    \+ legal_move(State,_),
    ( in_check(State,Turn) ->
        switch_turn(Turn,Winner)
    ; Winner = draw
    ).

render_state(state(Board,Turn,_,EP,HM,FN)) :-
    format('Turn: ~w  Halfmoves: ~d  Fullmoves: ~d~n',[Turn,HM,FN]),
    maplist(render_row,Board), nl,
    ( EP = none -> format('EnPassant: -~n') ; EP = [R,C], format('EnPassant: ~d,~d~n',[R,C])).

render_row(Row) :-
    maplist(render_cell,Row),
    nl.
render_cell(Cell) :-
    ( Cell = empty        -> write('. ')
    ; Cell = white_king   -> write('K ')
    ; Cell = white_queen  -> write('Q ')
    ; Cell = white_rook   -> write('R ')
    ; Cell = white_bishop -> write('B ')
    ; Cell = white_knight -> write('N ')
    ; Cell = white_pawn   -> write('P ')
    ; Cell = black_king   -> write('k ')
    ; Cell = black_queen  -> write('q ')
    ; Cell = black_rook   -> write('r ')
    ; Cell = black_bishop -> write('b ')
    ; Cell = black_knight -> write('n ')
    ; Cell = black_pawn   -> write('p ')
    ).

piece_at(Board,R,C,Piece) :-
    nth1(R,Board,Row),
    nth1(C,Row,Piece).

piece_color(white_pawn,white).
piece_color(white_knight,white).
piece_color(white_bishop,white).
piece_color(white_rook,white).
piece_color(white_queen,white).
piece_color(white_king,white).
piece_color(black_pawn,black).
piece_color(black_knight,black).
piece_color(black_bishop,black).
piece_color(black_rook,black).
piece_color(black_queen,black).
piece_color(black_king,black).

valid_destination(Board,Turn,_,_,TR,TC,EP) :-
    nth1(TR,Board,Row),
    nth1(TC,Row,Dest),
    ( Dest = empty
    ; piece_color(Dest,OD), OD \= Turn
    ; EP \= none, EP = [TR,TC]
    ).

% basic moves stub: King, Queen, Rook, Bishop, Knight, Pawn (one square)
piece_moves(white_pawn,[FR,FC],[TR,FC],Board) :-
    TR is FR-1,
    nth1(TR,Board,Row), nth1(FC,Row,empty).
piece_moves(black_pawn,[FR,FC],[TR,FC],Board) :-
    TR is FR+1,
    nth1(TR,Board,Row), nth1(FC,Row,empty).
piece_moves(white_pawn,[FR,FC],[TR,TC],Board) :-
    TR is FR-1, (TC is FC-1; TC is FC+1),
    nth1(TR,Board,Row), nth1(TC,Row,Dest), Dest \= empty.
piece_moves(black_pawn,[FR,FC],[TR,TC],Board) :-
    TR is FR+1, (TC is FC-1; TC is FC+1),
    nth1(TR,Board,Row), nth1(TC,Row,Dest), Dest \= empty.
piece_moves(white_knight,[FR,FC],[TR,TC],_) :-
    DX is abs(FR-TR), DY is abs(FC-TC),
    ((DX = 1, DY = 2) ; (DX = 2, DY = 1)).
piece_moves(black_knight,[FR,FC],[TR,TC],Board) :-
    piece_moves(white_knight,[FR,FC],[TR,TC],Board).
piece_moves(white_king,[FR,FC],[TR,TC],_) :-
    DX is abs(FR-TR), DY is abs(FC-TC), DX =< 1, DY =< 1.
piece_moves(black_king,[FR,FC],[TR,TC],Board) :-
    piece_moves(white_king,[FR,FC],[TR,TC],Board).
piece_moves(white_rook,[FR,FC],[TR,FC],Board) :-
    path_clear([FR,FC],[TR,FC],Board).
piece_moves(white_rook,[FR,FC],[FR,TC],Board) :-
    path_clear([FR,FC],[FR,TC],Board).
piece_moves(black_rook,[FR,FC],[TR,FC],Board) :-
    piece_moves(white_rook,[FR,FC],[TR,FC],Board).
piece_moves(black_rook,[FR,FC],[FR,TC],Board) :-
    piece_moves(white_rook,[FR,FC],[FR,TC],Board).
piece_moves(white_bishop,[FR,FC],[TR,TC],Board) :-
    abs(FR-TR) =:= abs(FC-TC),
    path_clear([FR,FC],[TR,TC],Board).
piece_moves(black_bishop,[FR,FC],[TR,TC],Board) :-
    piece_moves(white_bishop,[FR,FC],[TR,TC],Board).
piece_moves(white_queen,From,To,Board) :-
    (piece_moves(white_rook,From,To,Board) ; piece_moves(white_bishop,From,To,Board)).
piece_moves(black_queen,From,To,Board) :-
    piece_moves(white_queen,From,To,Board).

% clear path excluding endpoints
path_clear([FR,FC],[TR,TC],Board) :-
    DR is sign(TR-FR), DC is sign(TC-FC),
    path_clear_1(FR,FC,DR,DC,TR,TC,Board).
path_clear_1(FR,FC,_,_,FR,FC,_).
path_clear_1(R,C,DR,DC,TR,TC,Board) :-
    (R \= TR ; C \= TC),
    R1 is R+DR, C1 is C+DC,
    (R1 \= TR ; C1 \= TC -> nth1(R1,Board,Row), nth1(C1,Row,empty) ; true),
    path_clear_1(R1,C1,DR,DC,TR,TC,Board).

% apply a move without special cases
do_move(Board,_Turn,FR,FC,TR,TC,_Promo,_OldEP,_OldCR,NewBoard,none,Capture) :-
    piece_at(Board,FR,FC,P),
    nth1(TR,Board,Row), nth1(TC,Row,D),
    ( D = empty -> Capture = false ; Capture = true),
    set_cell(Board,FR,FC,empty,B1),
    set_cell(B1,TR,TC,P,NewBoard).

% stub: castling rights unchanged
update_castling_rights(OldCR,_,_,_,_,OldCR).

% update halfmove clock and fullmove number
update_clocks(HM,Capture,NextTurn,FN,NewHM,NewFN) :-
    ( Capture = true -> NewHM = 0 ; NewHM is HM+1 ),
    ( NextTurn = white -> NewFN is FN+1 ; NewFN = FN ).

switch_turn(white,black).
switch_turn(black,white).

% stub: no check detection
in_check(_State,_Color) :- false.