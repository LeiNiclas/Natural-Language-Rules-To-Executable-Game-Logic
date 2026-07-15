:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(+Index, +List, +Value, -NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% set_cell(+Row, +Col, +Value, +Board, -NewBoard)
set_cell(1, Col, V, [RowList|Rest], [NewRow|Rest]) :-
    set_nth1(Col, RowList, V, NewRow).
set_cell(Row, Col, V, [R|Rs], [R|NewRs]) :-
    Row > 1,
    Row1 is Row-1,
    set_cell(Row1, Col, V, Rs, NewRs).

% initial_state(-State)
initial_state(state(
    [
        [empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
        [dark_man,empty,dark_man,empty,dark_man,empty,dark_man,empty],
        [empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [light_man,empty,light_man,empty,light_man,empty,light_man,empty],
        [empty,light_man,empty,light_man,empty,light_man,empty,light_man],
        [light_man,empty,light_man,empty,light_man,empty,light_man,empty]
    ],
    dark
)).

% current_player(+State, -Player)
current_player(state(_, Player), Player).

% valid_pos(+Row, +Col)
valid_pos(R, C) :-
    between(1, 8, R),
    between(1, 8, C).

% piece_at(+Board, +Row, +Col, -Piece)
piece_at(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% belongs_to(+Player, +Piece)
belongs_to(dark, dark_man).
belongs_to(dark, dark_king).
belongs_to(light, light_man).
belongs_to(light, light_king).

% opponent(+Player, -Opponent)
opponent(dark, light).
opponent(light, dark).

% piece_positions(+Board, +Player, -Row, -Col)
piece_positions(Board, Player, Row, Col) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece),
    belongs_to(Player, Piece).

% simple_move(+Board, +Player, +FromRow, +FromCol, +ToRow, +ToCol)
simple_move(Board, Player, FR, FC, TR, TC) :-
    DeltaR is TR - FR,
    DeltaC is TC - FC,
    abs(DeltaR) =:= 1,
    abs(DeltaC) =:= 1,
    piece_at(Board, FR, FC, Piece),
    ( Piece = dark_man ->
        DeltaR =:= 1
    ; Piece = light_man ->
        DeltaR =:= -1
    ; Piece = dark_king ; Piece = light_king ).

% jump_move(+Board, +Player, +FromRow, +FromCol, +ToRow, +ToCol)
jump_move(Board, Player, FR, FC, TR, TC) :-
    DeltaR is TR - FR,
    DeltaC is TC - FC,
    abs(DeltaR) =:= 2,
    abs(DeltaC) =:= 2,
    piece_at(Board, FR, FC, Piece),
    ( Piece = dark_man ->
        DeltaR =:= 2
    ; Piece = light_man ->
        DeltaR =:= -2
    ; Piece = dark_king ; Piece = light_king ),
    MR is FR + DeltaR // 2,
    MC is FC + DeltaC // 2,
    piece_at(Board, MR, MC, MidPiece),
    opponent(Player, Opp),
    belongs_to(Opp, MidPiece).

% any_capture(+Board, +Player)
any_capture(Board, Player) :-
    piece_positions(Board, Player, FR, FC),
    member(DR, [2, -2]),
    member(DC, [2, -2]),
    TR is FR + DR,
    TC is FC + DC,
    valid_pos(TR, TC),
    piece_at(Board, TR, TC, empty),
    MR is FR + DR // 2,
    MC is FC + DC // 2,
    piece_at(Board, MR, MC, MidPiece),
    opponent(Player, Opp),
    belongs_to(Opp, MidPiece).

% legal_move(+State, -Move)
legal_move(state(Board, Player), move(FR, FC, TR, TC)) :-
    valid_pos(FR, FC),
    valid_pos(TR, TC),
    piece_at(Board, FR, FC, Piece),
    belongs_to(Player, Piece),
    piece_at(Board, TR, TC, empty),
    DeltaR is TR - FR,
    DeltaC is TC - FC,
    abs(DeltaR) =:= abs(DeltaC),
    (   any_capture(Board, Player)
    ->  jump_move(Board, Player, FR, FC, TR, TC)
    ;   ( simple_move(Board, Player, FR, FC, TR, TC)
        ; jump_move(Board, Player, FR, FC, TR, TC)
        )
    ).

% apply_move(+State, +Move, -NewState)
apply_move(state(Board,Player),move(FR,FC,TR,TC),state(NewBoard,NextPlayer)) :-
    legal_move(state(Board,Player),move(FR,FC,TR,TC)),
    piece_at(Board,FR,FC,Piece),
    DeltaR is TR-FR,
    DeltaC is TC-FC,
    set_cell(FR,FC,empty,Board,Board1),
    ( abs(DeltaR)=:=2 ->
        MR is FR + DeltaR//2,
        MC is FC + DeltaC//2,
        set_cell(MR,MC,empty,Board1,Board2),
        TempBoard = Board2,
        Jump=true
    ; TempBoard = Board1,
      Jump=false
    ),
    ( Piece = dark_man, TR=:=8 ->
        Promoted=dark_king
    ; Piece = light_man, TR=:=1 ->
        Promoted=light_king
    ; Promoted=Piece
    ),
    set_cell(TR,TC,Promoted,TempBoard,NewBoard),
    ( Jump,
      jump_move(NewBoard,Player,TR,TC,_,_)
    -> NextPlayer=Player
    ; opponent(Player,NextPlayer)
    ).

% win if opponent has no pieces
game_over(state(Board, Player), Player) :-
    opponent(Player, Opp),
    \+ piece_positions(Board, Opp, _, _).

% win if opponent has no legal moves
game_over(state(Board, Player), Player) :-
    opponent(Player, Opp),
    \+ legal_move(state(Board, Opp), _).

% draw if no captures available for either player
game_over(state(Board, _), draw) :-
    \+ any_capture(Board, light),
    \+ any_capture(Board, dark).

% render_state(+State)
render_state(state(Board, Player)) :-
    forall(nth1(RowNum, Board, Row),
           ( format('~w | ', [RowNum]),
             print_row(Row),
             nl
           )),
    format('  '),
    forall(between(1,8,Col), format('~w ', [Col])),
    nl,
    format('Current player: ~w', [Player]),
    nl.

% print_row(+Row)
print_row([Cell]) :-
    cell_char(Cell, Char),
    format('~w', [Char]).
print_row([Cell|Rest]) :-
    cell_char(Cell, Char),
    format('~w ', [Char]),
    print_row(Rest).

% cell_char(+Piece, -Char)
cell_char(empty, '.').
cell_char(dark_man, d).
cell_char(dark_king, 'D').
cell_char(light_man, l).
cell_char(light_king, 'L').

