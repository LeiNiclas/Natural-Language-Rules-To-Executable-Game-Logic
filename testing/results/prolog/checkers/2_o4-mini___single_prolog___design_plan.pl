:- use_module(library(lists)).
:- use_module(library(apply)).

% Helpers for 2D board manipulation
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial_state(State)
% State = state(Board, CurrentPlayer)
% Board is 8x8 list of rows 1..8, each element empty|dark_man|dark_king|light_man|light_king
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

% current_player(State, Player)
current_player(state(_, Player), Player).

% piece_at(Board, Row, Col, Piece)
piece_at(Board, Row, Col, Piece) :-
    nth1(Row, Board, R),
    nth1(Col, R, Piece).

% belongs_to(Piece, Player)
belongs_to(light_man, light).
belongs_to(light_king, light).
belongs_to(dark_man, dark).
belongs_to(dark_king, dark).

% empty_square(Board, Row, Col)
empty_square(Board, Row, Col) :-
    piece_at(Board, Row, Col, empty).

% opponent(Player, Opp)
opponent(light, dark).
opponent(dark, light).

% diagonal_distance(FromR,FromC,ToR,ToC,D)
diagonal_distance(FR, FC, TR, TC, D) :-
    DR is abs(TR-FR),
    DC is abs(TC-FC),
    DR =:= DC,
    D = DR.

% simple_move(Board, Player, FR, FC, TR, TC)
simple_move(Board, Player, FR, FC, TR, TC) :-
    piece_at(Board, FR, FC, Piece),
    belongs_to(Piece, Player),
    empty_square(Board, TR, TC),
    diagonal_distance(FR, FC, TR, TC, 1),
    ( Piece = light_king
    ; Piece = dark_king
    ; (Piece = light_man, TR is FR-1)
    ; (Piece = dark_man,  TR is FR+1)
    ).

% jump_move(Board, Player, FR, FC, TR, TC)
jump_move(Board, Player, FR, FC, TR, TC) :-
    piece_at(Board, FR, FC, Piece),
    belongs_to(Piece, Player),
    empty_square(Board, TR, TC),
    diagonal_distance(FR, FC, TR, TC, 2),
    MidR is (FR+TR)//2,
    MidC is (FC+TC)//2,
    piece_at(Board, MidR, MidC, MidPiece),
    opponent(Player, Opp),
    belongs_to(MidPiece, Opp).

% any_capture_available(Board, Player)
any_capture_available(Board, Player) :-
    jump_move(Board, Player, _, _, _, _).

% further_jumps(Board, Player, Row, Col)
further_jumps(Board, Player, Row, Col) :-
    jump_move(Board, Player, Row, Col, _, _).

% legal_move(State, Move)
% Move = move(FR,FC,TR,TC)
legal_move(state(Board, Player), move(FR, FC, TR, TC)) :-
    any_capture_available(Board, Player),
    jump_move(Board, Player, FR, FC, TR, TC).
legal_move(state(Board, Player), move(FR, FC, TR, TC)) :-
    \+ any_capture_available(Board, Player),
    ( simple_move(Board, Player, FR, FC, TR, TC)
    ; jump_move(Board, Player, FR, FC, TR, TC)
    ).

% apply_move(State, Move, NewState)
apply_move(state(Board, Player), move(FR, FC, TR, TC), state(FinalBoard, NextPlayer)) :-
    legal_move(state(Board, Player), move(FR, FC, TR, TC)),
    piece_at(Board, FR, FC, Piece),
    set_cell(FR, FC, Board, empty, Board1),
    diagonal_distance(FR, FC, TR, TC, D),
    ( D =:= 2 ->
        MidR is (FR+TR)//2,
        MidC is (FC+TC)//2,
        set_cell(MidR, MidC, Board1, empty, Board2),
        TempBoard = Board2,
        Jumped = true
    ; TempBoard = Board1,
      Jumped = false
    ),
    ( Piece = light_man, TR =:= 1 -> NewPiece = light_king
    ; Piece = dark_man,  TR =:= 8 -> NewPiece = dark_king
    ; NewPiece = Piece
    ),
    set_cell(TR, TC, TempBoard, NewPiece, FinalBoard),
    ( Jumped = true,
      further_jumps(FinalBoard, Player, TR, TC) ->
        NextPlayer = Player
    ; opponent(Player, NextPlayer)
    ).

% count_pieces(Board, Player, Count)
count_pieces(Board, Player, Count) :-
    flatten(Board, Flat),
    count_pieces_list(Flat, Player, Count).
count_pieces_list([], _, 0).
count_pieces_list([H|T], Player, Count) :-
    count_pieces_list(T, Player, CountT),
    ( belongs_to(H, Player) ->
        Count is CountT + 1
    ; Count = CountT
    ).

% no_legal_moves(Board, Player)
no_legal_moves(Board, Player) :-
    \+ legal_move(state(Board, Player), _).

% game_over(State, Winner)
game_over(state(Board, Player), Winner) :-
    opponent(Player, Opp),
    count_pieces(Board, Opp, 0),
    Winner = Player.
game_over(state(Board, Player), Winner) :-
    opponent(Player, Opp),
    no_legal_moves(Board, Opp),
    Winner = Player.
game_over(state(Board, _), draw) :-
    \+ any_capture_available(Board, light),
    \+ any_capture_available(Board, dark).

% render_state(State)
render_state(state(Board, _)) :-
    maplist(print_row, Board).

print_row(Row) :-
    maplist(print_cell, Row),
    nl.

print_cell(Cell) :-
    ( Cell = empty      -> C = '.'
    ; Cell = light_man  -> C = 'l'
    ; Cell = light_king -> C = 'L'
    ; Cell = dark_man   -> C = 'd'
    ; Cell = dark_king  -> C = 'D'
    ),
    format("~w ", [C]).