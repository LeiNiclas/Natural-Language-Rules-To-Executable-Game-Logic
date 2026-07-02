:- use_module(library(lists)).
:- use_module(library(apply)).

% 2D board helpers
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

in_bounds(R, C) :- between(1, 8, R), between(1, 8, C).

get_piece(Board, R, C, Piece) :- nth1(R, Board, Row), nth1(C, Row, Piece).
set_piece(Board, R, C, Piece, NewBoard) :- set_cell(R, C, Board, Piece, NewBoard).

opponent(light, dark).
opponent(dark, light).

piece_belongs_to(light, light_man).
piece_belongs_to(light, light_king).
piece_belongs_to(dark, dark_man).
piece_belongs_to(dark, dark_king).

is_opponent_piece(P, Piece) :- opponent(P, O), piece_belongs_to(O, Piece).

% simple (non-capture) move generator
simple_move(Board, P, R, C, TR, TC) :-
    in_bounds(R, C), in_bounds(TR, TC),
    get_piece(Board, R, C, Piece), piece_belongs_to(P, Piece),
    get_piece(Board, TR, TC, empty),
    DR1 is TR - R, DC1 is TC - C,
    DAbsR is abs(DR1), DAbsC is abs(DC1),
    DAbsR =:= 1, DAbsC =:= 1,
    ( Piece = dark_man -> DR1 =:= 1
    ; Piece = light_man -> DR1 =:= -1
    ; member(Piece, [dark_king, light_king])
    ).

% single jump (capture) move generator
jump_move(Board, P, R, C, TR, TC) :-
    in_bounds(R, C), in_bounds(TR, TC),
    get_piece(Board, R, C, Piece), piece_belongs_to(P, Piece),
    get_piece(Board, TR, TC, empty),
    DR1 is TR - R, DC1 is TC - C,
    DAbsR is abs(DR1), DAbsC is abs(DC1),
    DAbsR =:= 2, DAbsC =:= 2,
    MR is (R + TR) // 2, MC is (C + TC) // 2,
    get_piece(Board, MR, MC, Mid), is_opponent_piece(P, Mid).

simple_moves_for(Board, P, R, C, Dests) :-
    findall(TR-TC, simple_move(Board, P, R, C, TR, TC), Dests).

jump_moves_for(Board, P, R, C, Dests) :-
    findall(TR-TC, jump_move(Board, P, R, C, TR, TC), Dests).

any_capture_exists(Board, P) :-
    between(1,8,R), between(1,8,C),
    jump_move(Board, P, R, C, _, _), !.

further_jumps_exist(Board, P, R, C) :-
    jump_move(Board, P, R, C, _, _).

flatten_board(Board, Flat) :- flatten(Board, Flat).

count_pieces_flat([], _, 0).
count_pieces_flat([H|T], P, N) :-
    piece_belongs_to(P, H), !,
    count_pieces_flat(T, P, N1), N is N1 + 1.
count_pieces_flat([_|T], P, N) :- count_pieces_flat(T, P, N).

count_pieces(Board, P, N) :-
    flatten_board(Board, Flat),
    count_pieces_flat(Flat, P, N).

has_any_legal_move(Board, P) :-
    ( any_capture_exists(Board, P)
    ; between(1,8,R), between(1,8,C),
      simple_moves_for(Board, P, R, C, D), D \= []
    ).

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

current_player(state(_, P), P).

legal_move(state(Board, P), move(R, C, TR, TC)) :-
    any_capture_exists(Board, P),
    jump_move(Board, P, R, C, TR, TC).
legal_move(state(Board, P), move(R, C, TR, TC)) :-
    \+ any_capture_exists(Board, P),
    simple_move(Board, P, R, C, TR, TC).

apply_move(state(Board, P), move(R, C, TR, TC), state(NewBoardFinal, NextP)) :-
    jump_move(Board, P, R, C, TR, TC),
    MR is (R + TR) // 2, MC is (C + TC) // 2,
    set_piece(Board, MR, MC, empty, B1),
    get_piece(B1, R, C, Piece0),
    ( Piece0 = dark_man, TR =:= 8 -> Piece1 = dark_king
    ; Piece0 = light_man, TR =:= 1 -> Piece1 = light_king
    ; Piece1 = Piece0
    ),
    set_piece(B1, R, C, empty, B2),
    set_piece(B2, TR, TC, Piece1, NewBoardJump),
    ( further_jumps_exist(NewBoardJump, P, TR, TC)
      -> NewBoardFinal = NewBoardJump, NextP = P
      ;  NewBoardFinal = NewBoardJump, opponent(P, NextP)
    ).
apply_move(state(Board, P), move(R, C, TR, TC), state(NewBoardFinal, NextP)) :-
    simple_move(Board, P, R, C, TR, TC),
    get_piece(Board, R, C, Piece0),
    ( Piece0 = dark_man, TR =:= 8 -> Piece1 = dark_king
    ; Piece0 = light_man, TR =:= 1 -> Piece1 = light_king
    ; Piece1 = Piece0
    ),
    set_piece(Board, R, C, empty, B1),
    set_piece(B1, TR, TC, Piece1, NewBoardFinal),
    opponent(P, NextP).

game_over(state(Board, _), light) :-
    opponent(light, Opp), ( count_pieces(Board, Opp, 0) ; \+ has_any_legal_move(Board, Opp) ).
game_over(state(Board, _), dark) :-
    opponent(dark, Opp), ( count_pieces(Board, Opp, 0) ; \+ has_any_legal_move(Board, Opp) ).
game_over(state(Board, _), draw) :-
    \+ any_capture_exists(Board, light),
    \+ any_capture_exists(Board, dark),
    \+ ( opponent(light, O1), ( count_pieces(Board, O1, 0) ; \+ has_any_legal_move(Board, O1) ) ),
    \+ ( opponent(dark, O2), ( count_pieces(Board, O2, 0) ; \+ has_any_legal_move(Board, O2) ) ).

render_state(state(Board, P)) :-
    forall(nth1(_, Board, Row), (
        forall(nth1(_, Row, C), (
            ( C = empty -> format(". ")
            ; C = light_man -> format("l ")
            ; C = dark_man -> format("d ")
            ; C = light_king -> format("L ")
            ; C = dark_king -> format("D ")
            )
        )),
        nl
    )),
    format("Player: ~w~n", [P]).