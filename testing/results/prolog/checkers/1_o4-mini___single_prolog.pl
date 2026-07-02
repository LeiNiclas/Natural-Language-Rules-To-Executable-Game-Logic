:- use_module(library(lists)).
:- use_module(library(apply)).

% Helpers for 2D board manipulation
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Initial game state: standard 8x8 checkers setup, dark starts
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

% Current player accessor
current_player(state(_, P), P).

% Piece ownership
piece_owner(light_man, light).
piece_owner(light_king, light).
piece_owner(dark_man, dark).
piece_owner(dark_king, dark).

% Opponent relation
opponent(light, dark).
opponent(dark, light).

% Piece type checks
king(light_king).
king(dark_king).
man(light_man).
man(dark_man).

% Next player
next_player(light, dark).
next_player(dark, light).

% Get cell value
get_cell(R, C, Board, V) :-
    nth1(R, Board, Row),
    nth1(C, Row, V).

% Possible simple step for a piece
possible_step(Piece, DR, DC) :-
    king(Piece), member(DR, [1,-1]), member(DC, [1,-1]);
    Piece = dark_man, DR = 1, member(DC, [1,-1]);
    Piece = light_man, DR = -1, member(DC, [1,-1]).

% Possible jump for a piece
possible_jump(Piece, DR, DC) :-
    king(Piece), member(DR, [2,-2]), member(DC, [2,-2]);
    Piece = dark_man, DR = 2, member(DC, [2,-2]);
    Piece = light_man, DR = -2, member(DC, [2,-2]).

% Check if a specific piece can jump again
can_jump(Board, CP, FR, FC) :-
    get_cell(FR, FC, Board, Piece),
    piece_owner(Piece, CP),
    possible_jump(Piece, DR, DC),
    TR is FR+DR, TC is FC+DC,
    between(1,8,TR), between(1,8,TC),
    get_cell(TR, TC, Board, empty),
    MR is FR + DR//2, MC is FC + DC//2,
    get_cell(MR, MC, Board, Mid),
    piece_owner(Mid, OP), opponent(CP, OP).

% Collect any capture move exists
capture_exist(State) :-
    capture_move(State, _).

% Generate a capture move
capture_move(state(Board, CP), move(FR,FC,TR,TC)) :-
    between(1,8,FR), between(1,8,FC),
    get_cell(FR, FC, Board, Piece),
    piece_owner(Piece, CP),
    possible_jump(Piece, DR, DC),
    TR is FR+DR, TC is FC+DC,
    between(1,8,TR), between(1,8,TC),
    get_cell(TR, TC, Board, empty),
    MR is FR + DR//2, MC is FC + DC//2,
    get_cell(MR, MC, Board, Mid),
    piece_owner(Mid, OP), opponent(CP, OP).

% Generate a simple non-capturing move
simple_move(state(Board, CP), move(FR,FC,TR,TC)) :-
    \+ capture_exist(state(Board, CP)),
    between(1,8,FR), between(1,8,FC),
    get_cell(FR, FC, Board, Piece),
    piece_owner(Piece, CP),
    possible_step(Piece, DR, DC),
    TR is FR+DR, TC is FC+DC,
    between(1,8,TR), between(1,8,TC),
    get_cell(TR, TC, Board, empty).

% Legal moves: enforce forced captures
legal_move(State, Move) :-
    capture_exist(State),
    capture_move(State, Move).
legal_move(State, Move) :-
    \+ capture_exist(State),
    simple_move(State, Move).

% Apply a move to produce a new state
apply_move(state(Board, CP), move(FR,FC,TR,TC), state(NewBoard, NextCP)) :-
    get_cell(FR, FC, Board, Piece),
    piece_owner(Piece, CP),
    get_cell(TR, TC, Board, empty),
    DR is TR-FR, AbsDR is abs(DR),
    (AbsDR =:= 2 -> Jump = true ; Jump = false),
    % Remove moving piece from origin
    set_cell(FR, FC, Board, empty, B1),
    % If jump, remove captured piece
    ( Jump ->
        MR is FR + DR//2, MC is FC + (TC-FC)//2,
        set_cell(MR, MC, B1, empty, B2)
    ; B2 = B1 ),
    % Promotion for men
    ( Piece = light_man, TR =:= 1 -> NewPiece = light_king
    ; Piece = dark_man, TR =:= 8 -> NewPiece = dark_king
    ; NewPiece = Piece ),
    % Place piece at destination
    set_cell(TR, TC, B2, NewPiece, B3),
    % Determine next player (multi-jump)
    ( Jump, can_jump(B3, CP, TR, TC) -> NextCP = CP ; next_player(CP, NextCP) ),
    NewBoard = B3.

% Check if a player has any pieces
has_piece(Board, P) :-
    member(Row, Board),
    member(Cell, Row),
    piece_owner(Cell, P).

% Draw condition: neither player has capture moves
draw_condition(state(Board, _)) :-
    \+ capture_exist(state(Board, light)),
    \+ capture_exist(state(Board, dark)).

% Game over: win or draw
game_over(state(Board, CP), Winner) :-
    opponent(CP, OP),
    ( \+ has_piece(Board, OP) -> Winner = CP
    ; \+ legal_move(state(Board, CP), _) -> Winner = OP
    ; draw_condition(state(Board, CP)) -> Winner = draw ).

% Render the board and current player
render_state(state(Board, CP)) :-
    format("Player: ~w~n", [CP]),
    maplist(print_row, Board).

print_row(Row) :-
    maplist(print_cell, Row),
    nl.

print_cell(Cell) :-
    ( Cell = empty       -> format(". ")
    ; Cell = light_man   -> format("l ")
    ; Cell = light_king  -> format("L ")
    ; Cell = dark_man    -> format("d ")
    ; Cell = dark_king   -> format("D ") ).
