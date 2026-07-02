:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Value, Board, NewBoard)
set_cell(1, C, V, [Row|Rows], [NewRow|Rows]) :-
    set_nth1(C, Row, V, NewRow).
set_cell(R, C, V, [Row|Rows], [Row|NewRows]) :-
    R > 1,
    R1 is R - 1,
    set_cell(R1, C, V, Rows, NewRows).

% initial_state(State)
initial_state(state(
    [[empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
     [dark_man,empty,dark_man,empty,dark_man,empty,dark_man,empty],
     [empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
     [empty,empty,empty,empty,empty,empty,empty,empty],
     [empty,empty,empty,empty,empty,empty,empty,empty],
     [light_man,empty,light_man,empty,light_man,empty,light_man,empty],
     [empty,light_man,empty,light_man,empty,light_man,empty,light_man],
     [light_man,empty,light_man,empty,light_man,empty,light_man,empty]],
    dark)).

% current_player(State, Player)
current_player(state(_, Player), Player).

% opponent(Player, Opponent)
opponent(light, dark).
opponent(dark, light).

% belongs_to(Player, Piece)
belongs_to(light, light_man).
belongs_to(light, light_king).
belongs_to(dark, dark_man).
belongs_to(dark, dark_king).

% cell(Board, Row, Col, Value)
cell(Board, Row, Col, Value) :-
    nth1(Row, Board, BoardRow),
    nth1(Col, BoardRow, Value).

% within_bounds(Row, Col)
within_bounds(R, C) :-
    R >= 1, R =< 8,
    C >= 1, C =< 8.

% jump_move(Player, Board, Move)
jump_move(Player, Board, move(Fr, Fc, Tr, Tc)) :-
    cell(Board, Fr, Fc, Piece),
    belongs_to(Player, Piece),
    member(DR, [2, -2]),
    member(DC, [2, -2]),
    Tr is Fr + DR,
    Tc is Fc + DC,
    within_bounds(Tr, Tc),
    cell(Board, Tr, Tc, empty),
    MR is Fr + DR//2,
    MC is Fc + DC//2,
    cell(Board, MR, MC, MidPiece),
    opponent(Player, Opp),
    belongs_to(Opp, MidPiece).

% simple_move for man pieces
simple_move(Player, Board, move(Fr, Fc, Tr, Tc)) :-
    cell(Board, Fr, Fc, Piece),
    (Piece = light_man ; Piece = dark_man),
    belongs_to(Player, Piece),
    ( Piece = light_man -> DR = -1 ; DR = 1 ),
    member(DC, [1, -1]),
    Tr is Fr + DR,
    Tc is Fc + DC,
    within_bounds(Tr, Tc),
    cell(Board, Tr, Tc, empty).

% simple_move for king pieces
simple_move(Player, Board, move(Fr, Fc, Tr, Tc)) :-
    cell(Board, Fr, Fc, Piece),
    (Piece = light_king ; Piece = dark_king),
    belongs_to(Player, Piece),
    member(DR, [1, -1]),
    member(DC, [1, -1]),
    Tr is Fr + DR,
    Tc is Fc + DC,
    within_bounds(Tr, Tc),
    cell(Board, Tr, Tc, empty).

% has_any_jump(Player, Board)
has_any_jump(Player, Board) :-
    jump_move(Player, Board, _).

% legal_move(State, Move)
legal_move(state(Board, Player), Move) :-
    ( has_any_jump(Player, Board) ->
        jump_move(Player, Board, Move)
    ;
        ( jump_move(Player, Board, Move)
        ; simple_move(Player, Board, Move) )
    ).

% apply_move(State, Move, NewState)
apply_move(state(Board, Player), move(Fr,Fc,Tr,Tc), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), move(Fr,Fc,Tr,Tc)),
    cell(Board, Fr, Fc, Piece),
    set_cell(Fr, Fc, empty, Board, Board1),
    DR is Tr - Fr,
    AbsDR is abs(DR),
    ( AbsDR =:= 2 ->
        MR is (Fr + Tr) // 2,
        MC is (Fc + Tc) // 2,
        set_cell(MR, MC, empty, Board1, Board2),
        Jumped = true
    ;
        Board2 = Board1,
        Jumped = false
    ),
    ( Piece = dark_man, Tr =:= 8 ->
        Promoted = dark_king
    ; Piece = light_man, Tr =:= 1 ->
        Promoted = light_king
    ; Promoted = Piece
    ),
    set_cell(Tr, Tc, Promoted, Board2, NewBoard),
    ( Jumped = true,
      jump_move(Player, NewBoard, move(Tr, Tc, _, _)) ->
        NextPlayer = Player
    ;
        opponent(Player, NextPlayer)
    ).

% has_pieces(Player, Board)
has_pieces(Player, Board) :-
    cell(Board, _, _, Piece),
    belongs_to(Player, Piece).

% game_over(State, Winner)
% Winner is a player if opponent has no pieces or no legal moves, or 'draw' if no jumps for either.
game_over(state(Board,_), Winner) :-
    opponent(Winner, Opp),
    (   \+ has_pieces(Opp, Board)
    ;   \+ legal_move(state(Board, Opp), _)
    ), !.
game_over(state(Board,_), draw) :-
    \+ has_any_jump(light, Board),
    \+ has_any_jump(dark, Board).

% cell_symbol maps pieces to printable symbols
cell_symbol(empty, '.').
cell_symbol(light_man, 'l').
cell_symbol(light_king, 'L').
cell_symbol(dark_man, 'd').
cell_symbol(dark_king, 'D').

% render_state prints the board and current player
render_state(state(Board, Player)) :-
    render_rows(Board, 1),
    render_col_labels,
    format('Current player: ~w', [Player]), nl.

% render_rows prints each row with its number
render_rows([], _).
render_rows([Row|Rows], N) :-
    format('~w | ', [N]),
    render_row_cells(Row),
    nl,
    N1 is N + 1,
    render_rows(Rows, N1).

% render_row_cells prints each cell in a row
render_row_cells([]).
render_row_cells([C]) :-
    cell_symbol(C, S),
    format('~w', [S]).
render_row_cells([C|Cs]) :-
    cell_symbol(C, S),
    format('~w ', [S]),
    render_row_cells(Cs).

% render_col_labels prints column numbers below the board
render_col_labels :-
    format('   '),
    print_numbers(1,8),
    nl.

% print_numbers prints numbers from N to Max with spaces
print_numbers(N, N) :-
    format('~w', [N]).
print_numbers(N, Max) :-
    N < Max,
    format('~w ', [N]),
    N1 is N + 1,
    print_numbers(N1, Max).