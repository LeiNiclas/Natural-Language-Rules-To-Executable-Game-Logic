:- use_module(library(lists)).

% Helpers for 2D board updates
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Ownership and kind of pieces
piece_owner(light_man, light).
piece_owner(light_king, light).
piece_owner(dark_man, dark).
piece_owner(dark_king, dark).

piece_kind(Piece, man) :-
    (Piece = light_man; Piece = dark_man).
piece_kind(Piece, king) :-
    (Piece = light_king; Piece = dark_king).

opponent(light, dark).
opponent(dark, light).
next_player(light, dark).
next_player(dark, light).

% Access a cell
get_cell(R, C, Board, Cell) :-
    nth1(R, Board, Row),
    nth1(C, Row, Cell).

% Generate simple (non-capture) moves
simple_move(state(Board, Player), move(FR, FC, TR, TC)) :-
    \+ any_jump(state(Board, Player)),
    between(1,8,FR), between(1,8,FC),
    get_cell(FR, FC, Board, Piece), piece_owner(Piece, Player),
    between(1,8,TR), between(1,8,TC),
    get_cell(TR, TC, Board, empty),
    DR is TR - FR, DC is TC - FC, abs(DR) =:= 1, abs(DC) =:= 1,
    ( piece_kind(Piece, king)
    ; piece_kind(Piece, man),
      ((Player = dark, DR =:= 1) ; (Player = light, DR =:= -1))
    ).

% Generate jump (capture) moves
jump_move(state(Board, Player), move(FR, FC, TR, TC)) :-
    between(1,8,FR), between(1,8,FC),
    get_cell(FR, FC, Board, Piece), piece_owner(Piece, Player),
    between(1,8,TR), between(1,8,TC),
    get_cell(TR, TC, Board, empty),
    DR is TR - FR, DC is TC - FC, abs(DR) =:= 2, abs(DC) =:= 2,
    MR is (FR + TR) // 2, MC is (FC + TC) // 2,
    get_cell(MR, MC, Board, OppPiece), piece_owner(OppPiece, Opp), opponent(Player, Opp),
    ( piece_kind(Piece, king)
    ; piece_kind(Piece, man),
      ((Player = dark, DR =:= 2) ; (Player = light, DR =:= -2))
    ).

% Capture availability
any_jump(State) :- jump_move(State, _), !.

% Legal move respects mandatory captures
legal_move(State, Move) :-
    any_jump(State) -> jump_move(State, Move) ; simple_move(State, Move).

% Check if further jump exists from a position
jump_exists(Board, Player, FR, FC) :-
    jump_move(state(Board, Player), move(FR, FC, _, _)), !.

% Promotion
promote(Piece, Row, NewPiece) :-
    piece_kind(Piece, man),
    ((Piece = dark_man, Row =:= 8, NewPiece = dark_king)
    ; (Piece = light_man, Row =:= 1, NewPiece = light_king)
    ), !.
promote(Piece, _, Piece).

% Apply a simple move
apply_move(state(Board, Player), move(FR, FC, TR, TC), state(NewBoard, Next)) :-
    simple_move(state(Board, Player), move(FR, FC, TR, TC)),
    get_cell(FR, FC, Board, Piece),
    set_cell(FR, FC, Board, empty, B1),
    promote(Piece, TR, NewPiece),
    set_cell(TR, TC, B1, NewPiece, B2),
    next_player(Player, Next),
    NewBoard = B2.

% Apply a jump move with multi-jump handling
apply_move(state(Board, Player), move(FR, FC, TR, TC), state(NewBoard, Next)) :-
    jump_move(state(Board, Player), move(FR, FC, TR, TC)),
    get_cell(FR, FC, Board, Piece),
    MR is (FR + TR) // 2, MC is (FC + TC) // 2,
    set_cell(MR, MC, Board, empty, B1),
    set_cell(FR, FC, B1, empty, B2),
    promote(Piece, TR, NewPiece),
    set_cell(TR, TC, B2, NewPiece, B3),
    ( jump_exists(B3, Player, TR, TC) -> Next = Player ; next_player(Player, Next) ),
    NewBoard = B3.

% Initial state
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

% Current player
current_player(state(_, P), P).

% Game over detection
game_over(state(Board, _), Winner) :-
    flatten(Board, Flat),
    ( \+ (member(P, Flat), piece_owner(P, dark)) -> Winner = light
    ; \+ (member(P2, Flat), piece_owner(P2, light)) -> Winner = dark
    ; \+ legal_move(state(Board, dark), _) -> Winner = light
    ; \+ legal_move(state(Board, light), _) -> Winner = dark
    ; \+ jump_move(state(Board, light), _), \+ jump_move(state(Board, dark), _) -> Winner = draw
    ), !.

% Render the board
render_state(state(Board, _)) :-
    forall(nth1(_, Board, Row),
        ( forall(nth1(_, Row, Cell),
            ( cell_char(Cell, C), format("~w ", [C]) )),
          nl )).

% Display characters
cell_char(empty, '.').
cell_char(light_man, 'l').
cell_char(light_king, 'L').
cell_char(dark_man, 'd').
cell_char(dark_king, 'D').