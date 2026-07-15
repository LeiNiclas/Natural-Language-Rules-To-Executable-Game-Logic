:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Board, Value, NewBoard)
set_cell(1, Col, [Row|Rows], Value, [NewRow|Rows]) :-
    set_nth1(Col, Row, Value, NewRow).
set_cell(Row, Col, [Head|Rows], Value, [Head|NewRows]) :-
    Row > 1,
    Row1 is Row - 1,
    set_cell(Row1, Col, Rows, Value, NewRows).

% initial_state(-State)
initial_state(state([
    [empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
    [dark_man,empty,dark_man,empty,dark_man,empty,dark_man,empty],
    [empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [light_man,empty,light_man,empty,light_man,empty,light_man,empty],
    [empty,light_man,empty,light_man,empty,light_man,empty,light_man],
    [light_man,empty,light_man,empty,light_man,empty,light_man,empty]
], dark)).

% current_player(+State, -Player)
current_player(state(_, P), P).

% legal jump moves: move two squares diagonally over opponent piece
legal_move(state(Board, Player), move(FR,FC,TR,TC)) :-
    nth1(FR, Board, Row),
    nth1(FC, Row, Piece),
    (Player = dark -> (Piece = dark_man; Piece = dark_king) ; Player = light -> (Piece = light_man; Piece = light_king)),
    member(SignR, [1,-1]),
    member(SignC, [1,-1]),
    TR is FR + SignR*2,
    TC is FC + SignC*2,
    TR >= 1, TR =< 8, TC >= 1, TC =< 8,
    MidR is FR + SignR,
    MidC is FC + SignC,
    nth1(MidR, Board, MidRow),
    nth1(MidC, MidRow, MidPiece),
    (Player = dark -> (MidPiece = light_man; MidPiece = light_king) ; Player = light -> (MidPiece = dark_man; MidPiece = dark_king)),
    nth1(TR, Board, TRRow),
    nth1(TC, TRRow, empty).

% legal simple moves: move one square diagonally forward for men, any for kings, only if no jumps exist
legal_move(state(Board, Player), move(FR,FC,TR,TC)) :-
    \+ ( % no capture anywhere
        nth1(FR0, Board, Row0),
        nth1(FC0, Row0, P0),
        (Player = dark -> (P0 = dark_man; P0 = dark_king) ; Player = light -> (P0 = light_man; P0 = light_king)),
        member(SignR0, [1,-1]),
        member(SignC0, [1,-1]),
        TR0 is FR0 + SignR0*2,
        TC0 is FC0 + SignC0*2,
        TR0 >= 1, TR0 =< 8, TC0 >= 1, TC0 =< 8,
        MidR0 is FR0 + SignR0,
        MidC0 is FC0 + SignC0,
        nth1(MidR0, Board, MidRow0),
        nth1(MidC0, MidRow0, MidPiece0),
        (Player = dark -> (MidPiece0 = light_man; MidPiece0 = light_king) ; Player = light -> (MidPiece0 = dark_man; MidPiece0 = dark_king)),
        nth1(TR0, Board, TRRow0),
        nth1(TC0, TRRow0, empty)
    ),
    nth1(FR, Board, Row),
    nth1(FC, Row, Piece),
    (Player = dark -> (Piece = dark_man; Piece = dark_king) ; Player = light -> (Piece = light_man; Piece = light_king)),
    member(SignR, [1,-1]),
    member(SignC, [1,-1]),
    TR is FR + SignR,
    TC is FC + SignC,
    TR >= 1, TR =< 8, TC >= 1, TC =< 8,
    nth1(TR, Board, TRRow2),
    nth1(TC, TRRow2, empty),
    ( Piece = dark_man -> TR =:= FR + 1
    ; Piece = light_man -> TR =:= FR - 1
    ; true
    ).

% apply_move(+State, +Move, -NewState)
apply_move(state(Board, Player), move(FR,FC,TR,TC), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), move(FR,FC,TR,TC)),
    nth1(FR, Board, FromRow1),
    nth1(FC, FromRow1, Piece),
    set_cell(FR, FC, Board, empty, Board1),
    DR is TR - FR,
    AbsDR is abs(DR),
    ( AbsDR =:= 2 ->
        MidR is (FR + TR) // 2,
        MidC is (FC + TC) // 2,
        set_cell(MidR, MidC, Board1, empty, Board2)
    ;
        Board2 = Board1
    ),
    ( Piece = dark_man, TR =:= 8 ->
        NewPiece = dark_king
    ; Piece = light_man, TR =:= 1 ->
        NewPiece = light_king
    ;
        NewPiece = Piece
    ),
    set_cell(TR, TC, Board2, NewPiece, NewBoard),
    ( AbsDR =:= 2 ->
        ( member(SignR2, [1,-1]),
          member(SignC2, [1,-1]),
          TR2 is TR + SignR2*2,
          TC2 is TC + SignC2*2,
          TR2 >= 1, TR2 =< 8, TC2 >= 1, TC2 =< 8,
          MidR2 is TR + SignR2,
          MidC2 is TC + SignC2,
          nth1(MidR2, NewBoard, MidRow2),
          nth1(MidC2, MidRow2, MidPiece2),
          ( Player = dark -> (MidPiece2 = light_man; MidPiece2 = light_king)
          ; Player = light -> (MidPiece2 = dark_man; MidPiece2 = dark_king)
          ),
          nth1(TR2, NewBoard, TRRow2),
          nth1(TC2, TRRow2, empty),
          ( NewPiece = dark_man -> SignR2 =:= 1
          ; NewPiece = light_man -> SignR2 =:= -1
          ; true
          )
        -> NextPlayer = Player
        ; ( Player = dark -> NextPlayer = light ; NextPlayer = dark )
        )
    ;
        ( Player = dark -> NextPlayer = light ; NextPlayer = dark )
    ).

% other(+Player, -Opponent)
other(dark, light).
other(light, dark).

% capture_available(+Board, +Player) - true if Player has any jump move
capture_available(Board, Player) :-
    legal_move(state(Board, Player), move(FR,_,TR,_)),
    DR is TR - FR,
    AbsDR is abs(DR),
    AbsDR =:= 2.

% game_over(+State, -Winner) - Winner is player or draw
game_over(state(Board, Current), Current) :-
    other(Current, Opp),
    (
        \+ ( nth1(_, Board, Row), nth1(_, Row, Piece),
             ( Opp = dark -> (Piece = dark_man; Piece = dark_king)
             ; Opp = light -> (Piece = light_man; Piece = light_king)
             )
        )
    ;
        \+ legal_move(state(Board, Opp), _)
    ).

game_over(state(Board, _), draw) :-
    \+ capture_available(Board, dark),
    \+ capture_available(Board, light).

% render_state(+State)
render_state(state(Board, Current)) :-
    print_rows(Board, 1),
    print_cols,
    format('Current player: ~w~n', [Current]).

% print_rows(+Rows, +RowNum)
print_rows([], _).
print_rows([Row|Rest], N) :-
    format('~w |', [N]),
    print_row_cells(Row),
    nl,
    N1 is N+1,
    print_rows(Rest, N1).

% print_row_cells(+Row)
print_row_cells([]).
print_row_cells([C|Cs]) :-
    format(' '),
    render_cell(C),
    print_row_cells(Cs).

% print_cols
print_cols :-
    format('   '),
    print_col_numbers(1),
    nl.

% print_col_numbers(+N)
print_col_numbers(9).
print_col_numbers(N) :-
    N =< 8,
    format(' ~w', [N]),
    N1 is N+1,
    print_col_numbers(N1).

% render_cell(+Cell)
render_cell(empty) :-
    format('.').
render_cell(dark_man) :-
    format('b').
render_cell(dark_king) :-
    format('B').
render_cell(light_man) :-
    format('w').
render_cell(light_king) :-
    format('W').

