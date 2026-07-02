:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 8x8 list of lists
% Rows: 1-8 top to bottom, Cols: 1-8 left to right
% Pieces: empty, light_man, dark_man, light_king, dark_king

% Helper to set a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial board state
initial_board([
    [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
    [dark_man, empty, dark_man, empty, dark_man, empty, dark_man, empty],
    [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [light_man, empty, light_man, empty, light_man, empty, light_man, empty],
    [empty, light_man, empty, light_man, empty, light_man, empty, light_man],
    [light_man, empty, light_man, empty, light_man, empty, light_man, empty]
]).

% Initial state: board and starting player
initial_state(state(Board, dark)) :- initial_board(Board).

% Current player
current_player(state(_, Player), Player).

% Legal moves
legal_move(State, move(FromRow, FromCol, ToRow, ToCol)) :-
    State = state(Board, Player),
    % Select a piece belonging to the current player
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),

    % Try all possible destinations
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),

    % Check move legality
    (   legal_simple_move(Board, Player, FromRow, FromCol, ToRow, ToCol)
    ;   legal_jump_move(Board, Player, FromRow, FromCol, ToRow, ToCol)
    ),

    % If any capture is available, must capture
    (   capture_available(Board, Player) ->
        legal_jump_move(Board, Player, FromRow, FromCol, ToRow, ToCol)
    ;   true
    ).

% Player piece mapping
player_piece(light, light_man).
player_piece(light, light_king).
player_piece(dark, dark_man).
player_piece(dark, dark_king).

% Simple move legality
legal_simple_move(Board, Player, FromRow, FromCol, ToRow, ToCol) :-
    % Diagonal move
    DR is ToRow - FromRow,
    DC is ToCol - FromCol,
    abs(DR) =:= 1,
    abs(DC) =:= 1,

    % Check forward direction for men
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    (   Piece = light_man -> DR =:= -1
    ;   Piece = dark_man -> DR =:= 1
    ;   true % kings can move in any diagonal direction
    ).

% Jump move legality
legal_jump_move(Board, Player, FromRow, FromCol, ToRow, ToCol) :-
    % Must be a jump (distance 2)
    DR is ToRow - FromRow,
    DC is ToCol - FromCol,
    abs(DR) =:= 2,
    abs(DC) =:= 2,

    % Intermediate square must contain opponent piece
    IR is FromRow + DR // 2,
    IC is FromCol + DC // 2,
    nth1(IR, Board, IRow),
    nth1(IC, IRow, IPiece),
    opponent_piece(Player, IPiece).

% Opponent piece mapping
opponent_piece(light, dark_man).
opponent_piece(light, dark_king).
opponent_piece(dark, light_man).
opponent_piece(dark, light_king).

% Check if any capture is available for player
capture_available(Board, Player) :-
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    player_piece(Player, Piece),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    legal_jump_move(Board, Player, FromRow, FromCol, ToRow, ToCol),
    !.

% Apply move
apply_move(State, move(FromRow, FromCol, ToRow, ToCol), NewState) :-
    State = state(Board, Player),
    legal_move(State, move(FromRow, FromCol, ToRow, ToCol)),
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),

    % Remove piece from original position
    set_cell(FromRow, FromCol, Board, empty, Board1),

    % Place piece in new position (promote if needed)
    (   (Player = dark, ToRow = 8, Piece = dark_man) ->
        NewPiece = dark_king
    ;   (Player = light, ToRow = 1, Piece = light_man) ->
        NewPiece = light_king
    ;   NewPiece = Piece
    ),
    set_cell(ToRow, ToCol, Board1, NewPiece, Board2),

    % Remove jumped piece if it was a jump
    (   abs(ToRow - FromRow) =:= 2 ->
        IR is (FromRow + ToRow) // 2,
        IC is (FromCol + ToCol) // 2,
        set_cell(IR, IC, Board2, empty, Board3)
    ;   Board3 = Board2
    ),

    % Determine next player
    (   abs(ToRow - FromRow) =:= 2,
        further_jumps(Board3, Player, ToRow, ToCol) ->
        NextPlayer = Player
    ;   (Player = light -> NextPlayer = dark ; NextPlayer = light)
    ),

    NewState = state(Board3, NextPlayer).

% Check for further jumps from a position
further_jumps(Board, Player, Row, Col) :-
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    legal_jump_move(Board, Player, Row, Col, ToRow, ToCol).

% Game over conditions
game_over(state(Board, _), Winner) :-
    % No pieces left for one player
    (   \+ (member(Row, Board), member(Piece, Row), (Piece = dark_man ; Piece = dark_king))) ->
        Winner = light
    ;   \+ (member(Row, Board), member(Piece, Row), (Piece = light_man ; Piece = light_king))) ->
        Winner = dark
    ;   % No legal moves for current player
        \+ (legal_move(state(Board, light), _)) ->
        Winner = dark
    ;   \+ (legal_move(state(Board, dark), _)) ->
        Winner = light
    ;   % Draw condition: no captures available for either player
        \+ capture_available(Board, light),
        \+ capture_available(Board, dark) ->
        Winner = draw
    ).

% Render state
render_state(state(Board, Player)) :-
    format('Current player: ~w~n', [Player]),
    format('  1 2 3 4 5 6 7 8~n'),
    render_rows(Board, 1).

render_rows([], _).
render_rows([Row|Rows], N) :-
    format('~w ', [N]),
    render_row(Row),
    nl,
    N1 is N + 1,
    render_rows(Rows, N1).

render_row([]).
render_row([Cell|Rest]) :-
    (   Cell = empty -> format('. ')
    ;   Cell = light_man -> format('l ')
    ;   Cell = dark_man -> format('d ')
    ;   Cell = light_king -> format('L ')
    ;   Cell = dark_king -> format('D ')
    ),
    render_row(Rest).