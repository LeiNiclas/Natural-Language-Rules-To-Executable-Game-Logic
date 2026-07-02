:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

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

piece_belongs(Piece, Player) :-
    valid_man(Player, Piece).
piece_belongs(Piece, Player) :-
    valid_king(Player, Piece).

valid_man(dark, dark_man).
valid_man(light, light_man).

valid_king(dark, dark_king).
valid_king(light, light_king).

opponent(dark, light).
opponent(light, dark).

opponent_piece(Piece, Player) :-
    opponent(Player, Opp),
    piece_belongs(Piece, Opp).

valid_simple_dir(dark_man, FromRow, ToRow) :-
    ToRow =:= FromRow + 1.
valid_simple_dir(light_man, FromRow, ToRow) :-
    ToRow =:= FromRow - 1.
valid_simple_dir(dark_king, _, _).
valid_simple_dir(light_king, _, _).

valid_jump_dir(dark_man, FromRow, ToRow) :-
    ToRow =:= FromRow + 2.
valid_jump_dir(light_man, FromRow, ToRow) :-
    ToRow =:= FromRow - 2.
valid_jump_dir(dark_king, _, _).
valid_jump_dir(light_king, _, _).

has_capture(State) :-
    jump_move(State, _),
    !.

simple_move(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)) :-
    between(1,8,FromRow),
    between(1,8,FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    piece_belongs(Piece, Player),
    between(1,8,ToRow),
    between(1,8,ToCol),
    abs(ToRow - FromRow) =:= 1,
    abs(ToCol - FromCol) =:= 1,
    valid_simple_dir(Piece, FromRow, ToRow),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty).

jump_move(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)) :-
    between(1,8,FromRow),
    between(1,8,FromCol),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    piece_belongs(Piece, Player),
    between(1,8,ToRow),
    between(1,8,ToCol),
    abs(ToRow - FromRow) =:= 2,
    abs(ToCol - FromCol) =:= 2,
    valid_jump_dir(Piece, FromRow, ToRow),
    MidRow is (FromRow + ToRow) // 2,
    MidCol is (FromCol + ToCol) // 2,
    nth1(MidRow, Board, MidRowList),
    nth1(MidCol, MidRowList, MidPiece),
    opponent_piece(MidPiece, Player),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty).

legal_move(State, Move) :-
    has_capture(State) ->
    jump_move(State, Move) ;
    simple_move(State, Move).

promotion(dark_man, 8, dark_king).
promotion(light_man, 1, light_king).
promotion(P, _, P).

apply_move(state(Board, Player), move(FR, FC, TR, TC), state(NewBoard, NextPlayer)) :-
    jump_move(state(Board, Player), move(FR, FC, TR, TC)),
    nth1(FR, Board, FromRowList),
    nth1(FC, FromRowList, Piece),
    MidRow is (FR + TR) // 2,
    MidCol is (FC + TC) // 2,
    set_cell(MidRow, MidCol, Board, empty, B1),
    set_cell(FR, FC, B1, empty, B2),
    promotion(Piece, TR, NewPiece),
    set_cell(TR, TC, B2, NewPiece, B3),
    ( jump_move(state(B3, Player), move(TR, TC, _, _)) ->
        NextPlayer = Player,
        NewBoard = B3
    ;
        opponent(Player, NextPlayer),
        NewBoard = B3
    ).

apply_move(state(Board, Player), move(FR, FC, TR, TC), state(NewBoard, NextPlayer)) :-
    \+ has_capture(state(Board, Player)),
    simple_move(state(Board, Player), move(FR, FC, TR, TC)),
    nth1(FR, Board, FromRowList),
    nth1(FC, FromRowList, Piece),
    promotion(Piece, TR, NewPiece),
    set_cell(FR, FC, Board, empty, B1),
    set_cell(TR, TC, B1, NewPiece, B2),
    opponent(Player, NextPlayer),
    NewBoard = B2.

player_has_piece(Board, Player) :-
    flatten(Board, Flat),
    member(Piece, Flat),
    piece_belongs(Piece, Player).

game_over(state(Board, Player), Opp) :-
    opponent(Player, Opp),
    \+ player_has_piece(Board, Player).

game_over(state(Board, Player), Opp) :-
    opponent(Player, Opp),
    \+ legal_move(state(Board, Player), _).

game_over(state(Board, Player), draw) :-
    opponent(Player, Opp),
    \+ has_capture(state(Board, Player)),
    \+ has_capture(state(Board, Opp)).

% render_state prints the board and current player
render_state(state(Board, Player)) :-
    print_rows(Board, 1),
    format('    1 2 3 4 5 6 7 8~n'),
    format('Current player: ~w~n', [Player]).

% print_rows prints each row with its number
print_rows([], _).
print_rows([Row|Rows], N) :-
    N =< 8,
    format('~w | ', [N]),
    print_row(Row),
    N1 is N + 1,
    print_rows(Rows, N1).

% print_row prints each cell in a row
print_row([]) :-
    format('~n').
print_row([Cell|Cells]) :-
    symbol(Cell, Sym),
    format('~w ', [Sym]),
    print_row(Cells).

% symbol maps internal atoms to printable symbols
symbol(empty, '.').
symbol(dark_man, b).
symbol(dark_king, 'B').
symbol(light_man, w).
symbol(light_king, 'W').
