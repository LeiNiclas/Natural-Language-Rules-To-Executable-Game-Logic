:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper to update 1D list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Helper to update 2D board cell
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Owner relation: which pieces belong to which player
owner(light, light_man).
owner(light, light_king).
owner(dark, dark_man).
owner(dark, dark_king).

% Opponent relation
opponent(light, dark).
opponent(dark, light).

% Opponent piece check
opponent_piece(light, dark_man).
opponent_piece(light, dark_king).
opponent_piece(dark, light_man).
opponent_piece(dark, light_king).

% Valid board coordinates
valid_coord(R,C) :- between(1,8,R), between(1,8,C).

% Retrieve piece at given location
piece_at(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Set piece at given location
set_piece(Board, Row, Col, Piece, NewBoard) :-
    set_cell(Row, Col, Board, Piece, NewBoard).

% Initial game state
initial_state(state([
  [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
  [dark_man, empty, dark_man, empty, dark_man, empty, dark_man, empty],
  [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
  [empty, empty, empty, empty, empty, empty, empty, empty],
  [empty, empty, empty, empty, empty, empty, empty, empty],
  [light_man, empty, light_man, empty, light_man, empty, light_man, empty],
  [empty, light_man, empty, light_man, empty, light_man, empty, light_man],
  [light_man, empty, light_man, empty, light_man, empty, light_man, empty]
], dark)).

% Current player to move
current_player(state(_, P), P).

% Find all capture moves for player
find_all_captures(Board, Player, Moves) :-
    findall(move(FR,FC,TR,TC),
        ( piece_at(Board, FR, FC, Piece), owner(Player, Piece),
          valid_coord(TR,TC),
          DR is TR-FR, DC is TC-FC, AD is abs(DR), AC is abs(DC), AD=:=2, AC=:=2,
          piece_at(Board, TR, TC, empty),
          MidR is (FR+TR)//2, MidC is (FC+TC)//2,
          piece_at(Board, MidR, MidC, MidPiece),
          opponent_piece(Player, MidPiece)
        ),
    Moves).

% Legal capture moves if any exist, else simple moves
legal_move(state(Board, Player), move(FR,FC,TR,TC)) :-
    find_all_captures(Board, Player, Caps), Caps \= [],
    member(move(FR,FC,TR,TC), Caps).

legal_move(state(Board, Player), move(FR,FC,TR,TC)) :-
    find_all_captures(Board, Player, []),
    piece_at(Board, FR, FC, Piece), owner(Player, Piece),
    piece_at(Board, TR, TC, empty),
    DR is TR-FR, DC is TC-FC, AR is abs(DR), AC is abs(DC),
    AR=:=1, AC=:=1,
    ( Piece = dark_man -> DR=:=1
    ; Piece = light_man -> DR=:= -1
    ; (Piece = light_king; Piece = dark_king)
    ).

% Check if any move exists for player
has_any_move(Board, Player) :-
    legal_move(state(Board, Player), _), !.

% Check if further jump available for piece at location
can_continue_jump(Board, R, C, Player) :-
    find_all_captures(Board, Player, Caps),
    member(move(R, C, _, _), Caps).

% Apply a move to state
apply_move(state(Board, Player), move(FR,FC,TR,TC), state(NewBoard, NextPlayer)) :-
    piece_at(Board, FR, FC, Piece),
    DR is TR-FR, AD is abs(DR),
    set_piece(Board, FR, FC, empty, B1),
    ( AD=:=2 ->
        MidR is (FR+TR)//2, MidC is (FC+TC)//2,
        set_piece(B1, MidR, MidC, empty, B2)
    ; B2 = B1
    ),
    ( Piece = dark_man, TR=:=8 -> Promoted = dark_king
    ; Piece = light_man, TR=:=1 -> Promoted = light_king
    ; Promoted = Piece
    ),
    set_piece(B2, TR, TC, Promoted, B3),
    ( AD=:=2, can_continue_jump(B3, TR, TC, Player) ->
        NextPlayer = Player
    ; opponent(Player, NextPlayer)
    ),
    NewBoard = B3.

% Game over: win condition
game_over(state(Board, Player), Player) :-
    opponent(Player, Opp),
    ( \+ (piece_at(Board,_,_,M), owner(Opp,M))
    ; \+ has_any_move(Board, Opp)
    ).

% Game over: draw condition
game_over(state(Board,_), draw) :-
    find_all_captures(Board, light, CL), CL = [],
    find_all_captures(Board, dark, CD), CD = [],
    piece_at(Board, _, _, M1), owner(light, M1),
    has_any_move(Board, light),
    piece_at(Board, _, _, M2), owner(dark, M2),
    has_any_move(Board, dark).

% Render board state to stdout
render_state(state(Board,_)) :-
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(Cell) :-
    ( Cell = empty -> Sym = '.'
    ; Cell = light_man -> Sym = 'l'
    ; Cell = dark_man -> Sym = 'd'
    ; Cell = light_king -> Sym = 'L'
    ; Cell = dark_king -> Sym = 'D'
    ),
    format('~w ', [Sym]).