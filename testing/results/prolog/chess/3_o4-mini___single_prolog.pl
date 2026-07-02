:- use_module(library(lists)).
:- use_module(library(apply)).

% 2D board helpers
set_nth1(1,[_|T],V,[V|T]).
set_nth1(N,[H|T],V,[H|R]):- N>1, N1 is N-1, set_nth1(N1,T,V,R).
set_cell(Row,Col,Board,Value,NewBoard):-
    nth1(Row,Board,OldRow),
    set_nth1(Col,OldRow,Value,NewRow),
    set_nth1(Row,Board,NewRow,NewBoard).

% state(Board,Turn,CastlingRights,EnPassantTarget,HalfmoveClock,FullmoveNumber)
initial_state(state([
  [black_rook,black_knight,black_bishop,black_queen,black_king,black_bishop,black_knight,black_rook],
  [black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn],
  [white_rook,white_knight,white_bishop,white_queen,white_king,white_bishop,white_knight,white_rook]
], white,
  [white_kingside,white_queenside,black_kingside,black_queenside],
  null, 0, 1)).

current_player(state(_,P,_,_,_,_),P).

piece_color(P,white):- member(P,[white_king,white_queen,white_rook,white_bishop,white_knight,white_pawn]).
piece_color(P,black):- member(P,[black_king,black_queen,black_rook,black_bishop,black_knight,black_pawn]).

piece_type(P,pawn)  :- member(P,[white_pawn,black_pawn]).
piece_type(P,knight):- member(P,[white_knight,black_knight]).
piece_type(P,bishop):- member(P,[white_bishop,black_bishop]).
piece_type(P,rook)  :- member(P,[white_rook,black_rook]).
piece_type(P,queen) :- member(P,[white_queen,black_queen]).
piece_type(P,king)  :- member(P,[white_king,black_king]).

piece_at(Board,R,C,P):- nth1(R,Board,Row), nth1(C,Row,P).

% simplified valid moves: no castling, en passant, or promotion
valid_move(Board,white,Fr,Fc,Tr,Tc):-
    piece_at(Board,Fr,Fc,white_pawn),
    Dr is Tr-Fr, Dc is Tc-Fc,
    ((Dc=:=0,Dr=:= -1, piece_at(Board,Tr,Tc,empty))
    ;(Dc=:=0,Fr=:=7,Dr=:= -2, R1 is Fr-1, piece_at(Board,R1,Fc,empty), piece_at(Board,Tr,Tc,empty))
    ;(abs(Dc)=:=1,Dr=:= -1, piece_at(Board,Tr,Tc,P2),P2\=empty,piece_color(P2,black))
    ).
valid_move(Board,black,Fr,Fc,Tr,Tc):-
    piece_at(Board,Fr,Fc,black_pawn),
    Dr is Tr-Fr, Dc is Tc-Fc,
    ((Dc=:=0,Dr=:=1, piece_at(Board,Tr,Tc,empty))
    ;(Dc=:=0,Fr=:=2,Dr=:=2, R1 is Fr+1, piece_at(Board,R1,Fc,empty), piece_at(Board,Tr,Tc,empty))
    ;(abs(Dc)=:=1,Dr=:=1, piece_at(Board,Tr,Tc,P2),P2\=empty,piece_color(P2,white))
    ).
valid_move(Board,_,Fr,Fc,Tr,Tc):-
    piece_at(Board,Fr,Fc,P), member(P,[white_knight,black_knight]),
    Dr is Tr-Fr, Dc is Tc-Fc,
    ((abs(Dr)=:=2,abs(Dc)=:=1);(abs(Dr)=:=1,abs(Dc)=:=2)),
    (piece_at(Board,Tr,Tc,empty)
     ;(piece_at(Board,Tr,Tc,P2),piece_color(P2,C2),piece_color(P,C1),C1\=C2)
    ).
valid_move(Board,_,Fr,Fc,Tr,Tc):-
    piece_at(Board,Fr,Fc,P), member(P,[white_bishop,black_bishop]),
    Dr is Tr-Fr, Dc is Tc-Fc, abs(Dr)=:=abs(Dc), path_clear(Board,Fr,Fc,Tr,Tc),
    (piece_at(Board,Tr,Tc,empty)
     ;(piece_at(Board,Tr,Tc,P2),piece_color(P2,C2),piece_color(P,C1),C1\=C2)
    ).
valid_move(Board,_,Fr,Fc,Tr,Tc):-
    piece_at(Board,Fr,Fc,P), member(P,[white_rook,black_rook]),
    Dr is Tr-Fr, Dc is Tc-Fc, (Dr=:=0;Dc=:=0), path_clear(Board,Fr,Fc,Tr,Tc),
    (piece_at(Board,Tr,Tc,empty)
     ;(piece_at(Board,Tr,Tc,P2),piece_color(P2,C2),piece_color(P,C1),C1\=C2)
    ).
valid_move(Board,_,Fr,Fc,Tr,Tc):-
    piece_at(Board,Fr,Fc,P), member(P,[white_queen,black_queen]),
    Dr is Tr-Fr, Dc is Tc-Fc,
    ((abs(Dr)=:=abs(Dc));(Dr=:=0;Dc=:=0)), path_clear(Board,Fr,Fc,Tr,Tc),
    (piece_at(Board,Tr,Tc,empty)
     ;(piece_at(Board,Tr,Tc,P2),piece_color(P2,C2),piece_color(P,C1),C1\=C2)
    ).
valid_move(Board,_,Fr,Fc,Tr,Tc):-
    piece_at(Board,Fr,Fc,P), member(P,[white_king,black_king]),
    Dr is Tr-Fr, Dc is Tc-Fc, abs(Dr)=<1, abs(Dc)=<1,
    (piece_at(Board,Tr,Tc,empty)
     ;(piece_at(Board,Tr,Tc,P2),piece_color(P2,C2),piece_color(P,C1),C1\=C2)
    ).

path_clear(_,Fr,Fc,Tr,Tc):- Dr is Tr-Fr, Dc is Tc-Fc, abs(Dr)=<1, abs(Dc)=<1, !.
path_clear(Board,Fr,Fc,Tr,Tc):-
    Dr is Tr-Fr, Dc is Tc-Fc, Sdr is sign(Dr), Sdc is sign(Dc),
    Fr1 is Fr+Sdr, Fc1 is Fc+Sdc,
    (Fr1=Tr, Fc1=Tc ; piece_at(Board,Fr1,Fc1,empty), path_clear(Board,Fr1,Fc1,Tr,Tc)).

legal_move(State,move(Fr,Fc,Tr,Tc,none)):-
    State=state(Board,Turn,CR,EP,HM,FM),
    piece_at(Board,Fr,Fc,Piece),Piece\=empty,piece_color(Piece,Turn),
    valid_move(Board,Turn,Fr,Fc,Tr,Tc),
    apply_move(State,move(Fr,Fc,Tr,Tc,none),_).

apply_move(state(Board,Turn,CR,_,HM,FM),
           move(Fr,Fc,Tr,Tc,none),
           state(NewBoard,Next,CR,null,HM2,FM2)):-
    piece_at(Board,Fr,Fc,Piece),
    set_cell(Fr,Fc,Board,empty,B1),
    set_cell(Tr,Tc,B1,Piece,NewBoard),
    ( piece_type(Piece,pawn) ; piece_at(Board,Tr,Tc,P2),P2\=empty -> HM2=0 ; HM2 is HM+1 ),
    ( Turn=black -> FM2 is FM+1 ; FM2=FM ),
    ( Turn=white -> Next=black ; Next=white ).

game_over(state(Board,_,_,_,_,_),Winner):-
    flatten(Board,Flat),
    (\+ member(white_king,Flat) -> Winner=black
    ; \+ member(black_king,Flat) -> Winner=white).

render_state(state(Board,_,_,_,_,_)):- maplist(render_row,Board).
render_row(Row):- maplist(render_cell,Row), nl.
render_cell(C):-
    (C=empty        -> format(". ")
    ;C=white_king   -> format("K ")
    ;C=white_queen  -> format("Q ")
    ;C=white_rook   -> format("R ")
    ;C=white_bishop -> format("B ")
    ;C=white_knight -> format("N ")
    ;C=white_pawn   -> format("P ")
    ;C=black_king   -> format("k ")
    ;C=black_queen  -> format("q ")
    ;C=black_rook   -> format("r ")
    ;C=black_bishop -> format("b ")
    ;C=black_knight -> format("n ")
    ;C=black_pawn   -> format("p ")
    ).