:- use_module(library(lists)).
:- use_module(library(apply)).

% Helpers for 2D board manipulation
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Map piece to owner
piece_owner(light_man, light).
piece_owner(light_king, light).
piece_owner(dark_man, dark).
piece_owner(dark_king, dark).

% Identify man or king
is_man(light_man).
is_man(dark_man).

is_king(light_king).
is_king(dark_king).

% Opponent relation
opponent(light, dark).
opponent(dark, light).

% Promote man if reaching last row
promote_if_needed(Row, dark_man, dark_king) :-
    Row = 8.
promote_if_needed(Row, light_man, light_king) :-
    Row = 1.
promote_if_needed(_, Piece, Piece).

% Access a cell
get_cell(Row, Col, Board, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

% Generate all jump moves for a player
find_jump_moves(Board, Player, move(FR,FC,TR,TC)) :-
    between(1,8,FR), between(1,8,FC),
    get_cell(FR,FC,Board,Piece), piece_owner(Piece, Player),
    ( is_king(Piece) ->
        DRs = [2, -2]
    ; Player = dark ->
        DRs = [2]
    ;
        DRs = [-2]
    ),
    DCs = [2, -2],
    member(DR, DRs), member(DC, DCs),
    TR is FR + DR, TC is FC + DC,
    between(1,8,TR), between(1,8,TC),
    get_cell(TR,TC,Board,empty),
    MR is (FR + TR) // 2, MC is (FC + TC) // 2,
    get_cell(MR,MC,Board,MidPiece), MidPiece \= empty,
    piece_owner(MidPiece, Opp), opponent(Player, Opp).

% Generate a simple diagonal move
find_simple_moves(Board, Player, move(FR,FC,TR,TC)) :-
    between(1,8,FR), between(1,8,FC),
    get_cell(FR,FC,Board,Piece), piece_owner(Piece, Player),
    ( is_king(Piece) ->
        DRs = [1, -1]
    ; Player = dark ->
        DRs = [1]
    ;
        DRs = [-1]
    ),
    DCs = [1, -1],
    member(DR, DRs), member(DC, DCs),
    TR is FR + DR, TC is FC + DC,
    between(1,8,TR), between(1,8,TC),
    get_cell(TR,TC,Board,empty).

% Check if any jump exists for Player
has_jump(Board, Player) :-
    find_jump_moves(Board, Player, _), !.

% initial state
initial_state(state([
    [empty,    dark_man,  empty,    dark_man,  empty,    dark_man,  empty,    dark_man],
    [dark_man, empty,     dark_man, empty,     dark_man, empty,     dark_man, empty],
    [empty,    dark_man,  empty,    dark_man,  empty,    dark_man,  empty,    dark_man],
    [empty,    empty,     empty,    empty,     empty,    empty,     empty,    empty],
    [empty,    empty,     empty,    empty,     empty,    empty,     empty,    empty],
    [light_man,empty,     light_man,empty,     light_man,empty,     light_man,empty],
    [empty,    light_man, empty,    light_man, empty,    light_man, empty,    light_man],
    [light_man,empty,     light_man,empty,     light_man,empty,     light_man,empty]
], dark)).

% current player
current_player(state(_, Player), Player).

% legal moves with mandatory capture
legal_move(state(Board, Player), Move) :-
    has_jump(Board, Player),
    find_jump_moves(Board, Player, Move).
legal_move(state(Board, Player), Move) :-
    \+ has_jump(Board, Player),
    find_simple_moves(Board, Player, Move).

% apply a move
apply_move(state(Board, Player), move(FR,FC,TR,TC), state(NewBoard, NextPlayer)) :-
    get_cell(FR,FC,Board,Piece), piece_owner(Piece, Player),
    AbsDR is abs(TR - FR), AbsDC is abs(TC - FC), AbsDR =:= AbsDC,
    get_cell(TR,TC,Board,empty),
    (
        AbsDR =:= 2 ->
        MR is (FR + TR) // 2, MC is (FC + TC) // 2,
        get_cell(MR,MC,Board,MidPiece), MidPiece \= empty,
        piece_owner(MidPiece, MP), opponent(Player, MP),
        set_cell(MR,MC,Board,empty,B1),
        set_cell(FR,FC,B1,empty,B2)
    ;
        AbsDR =:= 1 ->
        \+ has_jump(Board, Player),
        set_cell(FR,FC,Board,empty,B2)
    ),
    promote_if_needed(TR, Piece, NewPiece),
    set_cell(TR,TC,B2,NewPiece,B3),
    (
        AbsDR =:= 2,
        find_jump_moves(B3, Player, move(TR,TC,_,_))
    ->  NextPlayer = Player
    ;   opponent(Player, NextPlayer)
    ),
    NewBoard = B3.

% game over by win or draw
game_over(state(Board,_), light) :-
    \+ (member(Row, Board), member(Cell, Row), piece_owner(Cell, dark)).
game_over(state(Board,_), light) :-
    \+ legal_move(state(Board, dark), _).
game_over(state(Board,_), dark) :-
    \+ (member(Row, Board), member(Cell, Row), piece_owner(Cell, light)).
game_over(state(Board,_), dark) :-
    \+ legal_move(state(Board, light), _).
game_over(state(Board,_), draw) :-
    \+ has_jump(Board, light),
    \+ has_jump(Board, dark).

% cell symbol helper
cell_symbol(empty,    '.').
cell_symbol(light_man,'l').
cell_symbol(dark_man, 'd').
cell_symbol(light_king,'L').
cell_symbol(dark_king, 'D').

% render row
print_row(Row) :-
    forall(nth1(_, Row, Cell),
        (cell_symbol(Cell, Sym), format('~w ', [Sym]))).

% render state to stdout
render_state(state(Board,_)) :-
    forall(nth1(_, Board, Row),
        (print_row(Row), nl)).
