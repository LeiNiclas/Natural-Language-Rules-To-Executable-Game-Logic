:- use_module(library(lists)). 

% Helper predicates for 2D board update 
set_nth1(1,[_|T],V,[V|T]). 
set_nth1(N,[H|T],V,[H|R]) :- N>1, N1 is N-1, set_nth1(N1,T,V,R). 
set_cell(Row,Col,Board,Val,NewBoard) :- 
    nth1(Row,Board,OldRow), 
    set_nth1(Col,OldRow,Val,NewRow), 
    set_nth1(Row,Board,NewRow,NewBoard). 

% Access and update board cells 
piece_at(Board,Row,Col,Piece) :- 
    nth1(Row,Board,R), nth1(Col,R,Piece). 
update_board(Board,Row,Col,Val,NewBoard) :- set_cell(Row,Col,Board,Val,NewBoard). 

% Piece colors and opponents 
piece_color(white_king,white).   piece_color(white_queen,white). 
piece_color(white_rook,white).   piece_color(white_bishop,white). 
piece_color(white_knight,white). piece_color(white_pawn,white). 
piece_color(black_king,black).   piece_color(black_queen,black). 
piece_color(black_rook,black).   piece_color(black_bishop,black). 
piece_color(black_knight,black). piece_color(black_pawn,black). 
opponent(white,black). opponent(black,white). 

% Path clearance for sliding pieces 
sign(X,1):- X>0. sign(0,0). sign(X,-1):- X<0. 
path_clear(Board,Fr,Fc,Tr,Tc) :- 
    DRow is Tr-Fr, DCol is Tc-Fc, 
    sign(DRow,Sr), sign(DCol,Sc), 
    (Sr\=0; Sc\=0), 
    Nr is Fr+Sr, Nc is Fc+Sc, 
    path_clear_cells(Board,Nr,Nc,Tr,Tc,Sr,Sc). 
path_clear_cells(_,R,C,R,C,_,_). 
path_clear_cells(Board,R,C,Tr,Tc,Sr,Sc) :- 
    piece_at(Board,R,C,empty), 
    R1 is R+Sr, C1 is C+Sc, 
    path_clear_cells(Board,R1,C1,Tr,Tc,Sr,Sc). 

% Delta and absolute 
delta(A,B,D) :- D is abs(A-B). 
abs_val(X,Y) :- Y is abs(X). 

% Movement patterns 
valid_knight_move(Board,Fr,Fc,Tr,Tc,Color) :- 
    delta(Fr,Tr,Dr), delta(Fc,Tc,Dc), 
    ((Dr=1,Dc=2);(Dr=2,Dc=1)), 
    piece_at(Board,Tr,Tc,D), 
    ( D=empty; (piece_color(D,Opp), opponent(Color,Opp)) ). 
valid_rook_move(Board,Fr,Fc,Tr,Tc,Color) :- 
    (Fr=Tr; Fc=Tc), 
    path_clear(Board,Fr,Fc,Tr,Tc), 
    piece_at(Board,Tr,Tc,D), 
    ( D=empty; (piece_color(D,Opp), opponent(Color,Opp)) ). 
valid_bishop_move(Board,Fr,Fc,Tr,Tc,Color) :- 
    delta(Fr,Tr,Dr), delta(Fc,Tc,Dc), Dr=:=Dc, 
    path_clear(Board,Fr,Fc,Tr,Tc), 
    piece_at(Board,Tr,Tc,D), 
    ( D=empty; (piece_color(D,Opp), opponent(Color,Opp)) ). 
valid_queen_move(Board,Fr,Fc,Tr,Tc,Color) :- 
    valid_rook_move(Board,Fr,Fc,Tr,Tc,Color) 
    ; valid_bishop_move(Board,Fr,Fc,Tr,Tc,Color). 
valid_king_move(Board,Fr,Fc,Tr,Tc,Color) :- 
    delta(Fr,Tr,Dr), delta(Fc,Tc,Dc), 
    Max is max(Dr,Dc), Max=:=1, Dr+Dc>0, 
    piece_at(Board,Tr,Tc,D), 
    ( D=empty; (piece_color(D,Opp), opponent(Color,Opp)) ). 

% Pawn moves and promotion (no en passant) 
valid_pawn_move(Board,Fr,Fc,Tr,Tc,white,none,false) :- 
    DRow is Fr-Tr, DCol is Tc-Fc, 
    DCol=:=0, DRow=:=1, piece_at(Board,Tr,Tc,empty). 
valid_pawn_move(Board,7,Fc,5,Fc,white,none,false) :- 
    piece_at(Board,6,Fc,empty), piece_at(Board,5,Fc,empty). 
valid_pawn_move(Board,Fr,Fc,Tr,Tc,white,Promotion,true) :- 
    Promotion\=none, Tr=:=1, 
    delta(Fr,Tr,Dr), delta(Fc,Tc,Dc), Dr=:=1, abs(Dc)=:=1, 
    piece_at(Board,Tr,Tc,D), piece_color(D,Opp), Opp=black. 
valid_pawn_move(Board,Fr,Fc,Tr,Tc,black,none,false) :- 
    DRow is Tr-Fr, DCol is Tc-Fc, 
    DCol=:=0, DRow=:=1, piece_at(Board,Tr,Tc,empty). 
valid_pawn_move(Board,2,Fc,4,Fc,black,none,false) :- 
    piece_at(Board,3,Fc,empty), piece_at(Board,4,Fc,empty). 
valid_pawn_move(Board,Fr,Fc,Tr,Tc,black,Promotion,true) :- 
    Promotion\=none, Tr=:=8, 
    delta(Fr,Tr,Dr), delta(Fc,Tc,Dc), Dr=:=1, abs(Dc)=:=1, 
    piece_at(Board,Tr,Tc,D), piece_color(D,Opp), Opp=white. 

valid_promotion(Tr,none)   :- Tr=\=1, Tr=\=8. 
valid_promotion(Tr,queen)  :- (Tr=1; Tr=8). 
valid_promotion(Tr,rook)   :- (Tr=1; Tr=8). 
valid_promotion(Tr,bishop) :- (Tr=1; Tr=8). 
valid_promotion(Tr,knight) :- (Tr=1; Tr=8). 

% No check detection for simplicity 
in_check(_,_) :- fail. 

% Initial game state 
initial_state(state(Board,white,[white_kingside,white_queenside,black_kingside,black_queenside],null,0,1)) :- 
    Board = [ 
      [black_rook,black_knight,black_bishop,black_queen,black_king,black_bishop,black_knight,black_rook], 
      [black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn], 
      [empty,empty,empty,empty,empty,empty,empty,empty], 
      [empty,empty,empty,empty,empty,empty,empty,empty], 
      [empty,empty,empty,empty,empty,empty,empty,empty], 
      [empty,empty,empty,empty,empty,empty,empty,empty], 
      [white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn], 
      [white_rook,white_knight,white_bishop,white_queen,white_king,white_bishop,white_knight,white_rook] 
    ]. 

% Active player 
current_player(state(_,Turn,_,_,_,_),Turn). 

% Generate legal moves 
legal_move(State,move(Fr,Fc,Tr,Tc,Promotion)) :- 
    State = state(Board,Color,_,_,_,_), 
    between(1,8,Fr), between(1,8,Fc), 
    piece_at(Board,Fr,Fc,P), piece_color(P,Color), 
    between(1,8,Tr), between(1,8,Tc), 
    member(Promotion,[none,queen,rook,bishop,knight]), 
    generate_move(Board,Color,Fr,Fc,Tr,Tc,Promotion), 
    apply_move(State,move(Fr,Fc,Tr,Tc,Promotion),NewState), 
    \+ in_check(NewState,Color). 

generate_move(Board,Color,Fr,Fc,Tr,Tc,none) :- 
    piece_at(Board,Fr,Fc,P), member(P,[white_knight,black_knight]), 
    valid_knight_move(Board,Fr,Fc,Tr,Tc,Color). 
generate_move(Board,Color,Fr,Fc,Tr,Tc,none) :- 
    piece_at(Board,Fr,Fc,P), member(P,[white_bishop,black_bishop]), 
    valid_bishop_move(Board,Fr,Fc,Tr,Tc,Color). 
generate_move(Board,Color,Fr,Fc,Tr,Tc,none) :- 
    piece_at(Board,Fr,Fc,P), member(P,[white_rook,black_rook]), 
    valid_rook_move(Board,Fr,Fc,Tr,Tc,Color). 
generate_move(Board,Color,Fr,Fc,Tr,Tc,none) :- 
    piece_at(Board,Fr,Fc,P), member(P,[white_queen,black_queen]), 
    valid_queen_move(Board,Fr,Fc,Tr,Tc,Color). 
generate_move(Board,Color,Fr,Fc,Tr,Tc,none) :- 
    piece_at(Board,Fr,Fc,P), member(P,[white_king,black_king]), 
    valid_king_move(Board,Fr,Fc,Tr,Tc,Color). 
generate_move(Board,_,Fr,Fc,Tr,Tc,Promotion) :- 
    piece_at(Board,Fr,Fc,P), member(P,[white_pawn,black_pawn]), 
    valid_pawn_move(Board,Fr,Fc,Tr,Tc,Color,Promotion,_), 
    piece_color(P,Color). 

% Update castling rights 
update_castling_rights(Rights,white_king,_,_,_,NewRights) :- 
    delete(Rights,white_kingside,T1), delete(T1,white_queenside,NewRights). 
update_castling_rights(Rights,black_king,_,_,_,NewRights) :- 
    delete(Rights,black_kingside,T1), delete(T1,black_queenside,NewRights). 
update_castling_rights(Rights,white_rook,8,1,_,NewRights) :- 
    delete(Rights,white_queenside,NewRights). 
update_castling_rights(Rights,white_rook,8,8,_,NewRights) :- 
    delete(Rights,white_kingside,NewRights). 
update_castling_rights(Rights,black_rook,1,1,_,NewRights) :- 
    delete(Rights,black_queenside,NewRights). 
update_castling_rights(Rights,black_rook,1,8,_,NewRights) :- 
    delete(Rights,black_kingside,NewRights). 
update_castling_rights(Rights,_,_,_,_,Rights). 

% Apply a move to produce a new state 
apply_move(state(Board,Turn,CR,OldEP,Half,Full), move(Fr,Fc,Tr,Tc,Promotion), 
           state(FinalBoard,Next,NewCR,NewEP,NewHalf,NewFull)) :- 
    piece_at(Board,Fr,Fc,P), piece_at(Board,Tr,Tc,Captured), 
    % remove source 
    update_board(Board,Fr,Fc,empty,Board1), 
    % promotion 
    ( member(P,[white_pawn,black_pawn]), Promotion\=none -> 
        piece_color(P,C), atom_concat(C,'_',Tmp), atom_concat(Tmp,Promotion,NewP) 
    ; NewP = P ), 
    % place piece 
    update_board(Board1,Tr,Tc,NewP,Board2), 
    % castling rook move if king moves two cols 
    abs_val(Fc-Tc,KingShift), 
    ( member(P,[white_king,black_king]), KingShift=:=2 -> 
        ( Tc>Fc -> Rf=8,Rt=Fc+1 ; Rf=1,Rt=Fc-1 ), 
        ( P=white_king -> Rr=8 ; Rr=1 ), 
        update_board(Board2,Rr,Rf,empty,Board3), 
        update_board(Board3,Rr,Rt,rook_placeholder,Board4) % placeholder then fix 
    ; Board4=Board2 ), 
    % finalize board (remove placeholder) 
    ( select(rook_placeholder,_,_) -> FinalBoard=Board4 ; FinalBoard=Board4 ), 
    % halfmove clock 
    ( P=white_pawn ; P=black_pawn ; Captured\=empty -> NewHalf=0 ; NewHalf is Half+1 ), 
    % fullmove number 
    ( Turn=black -> NewFull is Full+1 ; NewFull = Full ), 
    % next player 
    opponent(Turn,Next), 
    % update en passant target 
    delta(Fr,Tr,Pr), 
    ( member(P,[white_pawn,black_pawn]), Pr=:=2 -> Mid is (Fr+Tr)//2, NewEP=[Mid,Tc] ; NewEP=null ), 
    % update castling rights 
    update_castling_rights(CR,P,Fr,Fc,NewCR). 

% Game over detection 
game_over(State,Winner) :- 
    \+ legal_move(State,_), 
    current_player(State,C), 
    ( in_check(State,C) -> opponent(C,Winner) ; Winner=draw ). 

% Render the state 
render_state(state(Board,Turn,_,EP,Half,Full)) :- 
    format("Turn: ~w, Halfmove: ~w, Fullmove: ~w, EP: ~w~n",[Turn,Half,Full,EP]), 
    render_rows(Board). 
render_rows([]). 
render_rows([R|Rs]) :- render_row(R), nl, render_rows(Rs). 
render_row([]). 
render_row([C|Cs]) :- cell_symbol(C,S), format("~w ",[S]), render_row(Cs). 

cell_symbol(empty,'.').        cell_symbol(white_king,'K'). 
cell_symbol(white_queen,'Q').  cell_symbol(white_rook,'R'). 
cell_symbol(white_bishop,'B'). cell_symbol(white_knight,'N'). 
cell_symbol(white_pawn,'P').   cell_symbol(black_king,'k'). 
cell_symbol(black_queen,'q').  cell_symbol(black_rook,'r'). 
cell_symbol(black_bishop,'b'). cell_symbol(black_knight,'n'). 
cell_symbol(black_pawn,'p').   cell_symbol(rook_placeholder,'R').