:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 8x8 list of lists. Rows 1-8 (top to bottom), Cols 1-8 (left to right).
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

initial_state(state(Board, dark)) :- initial_board(Board).

current_player(state(_, Player), Player).

% Get piece at position
get_piece(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Check if a position is on the board
on_board(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Check if a piece belongs to a player
piece_belongs_to_player(light_man, light).
piece_belongs_to_player(light_king, light).
piece_belongs_to_player(dark_man, dark).
piece_belongs_to_player(dark_king, dark).

% Check if a piece is a king
is_king(light_king).
is_king(dark_king).

% Check if a piece is a man
is_man(light_man).
is_man(dark_man).

% Check if a move is a simple diagonal move
is_simple_move(FromRow, FromCol, ToRow, ToCol) :-
    DiffRow is abs(ToRow - FromRow),
    DiffCol is abs(ToCol - FromCol),
    DiffRow =:= 1,
    DiffCol =:= 1.

% Check if a move is a forward move for a man
is_forward_move(FromRow, ToRow, light) :- ToRow < FromRow.
is_forward_move(FromRow, ToRow, dark) :- ToRow > FromRow.

% Check if a move is a jump
is_jump(FromRow, FromCol, ToRow, ToCol) :-
    DiffRow is abs(ToRow - FromRow),
    DiffCol is abs(ToCol - FromCol),
    DiffRow =:= 2,
    DiffCol =:= 2.

% Get intermediate square for a jump
intermediate_square(FromRow, FromCol, ToRow, ToCol, IntRow, IntCol) :-
    IntRow is (FromRow + ToRow) // 2,
    IntCol is (FromCol + ToCol) // 2.

% Check if a piece is an opponent
is_opponent(light, dark).
is_opponent(dark, light).
is_opponent(light_man, dark).
is_opponent(light_man, dark_man).
is_opponent(light_man, dark_king).
is_opponent(dark_man, light).
is_opponent(dark_man, light_man).
is_opponent(dark_man, light_king).
is_opponent(light_king, dark).
is_opponent(light_king, dark_man).
is_opponent(light_king, dark_king).
is_opponent(dark_king, light).
is_opponent(dark_king, light_man).
is_opponent(dark_king, light_king).

% Check if a piece can move (simple or jump)
can_move(Board, Player, FromRow, FromCol, ToRow, ToCol) :-
    get_piece(Board, FromRow, FromCol, Piece),
    piece_belongs_to_player(Piece, Player),
    on_board(ToRow, ToCol),
    get_piece(Board, ToRow, ToCol, empty),
    (   is_simple_move(FromRow, FromCol, ToRow, ToCol)
    ->  (   is_king(Piece)
        ->  true
        ;   is_forward_move(FromRow, ToRow, Player)
        )
    ;   is_jump(FromRow, FromCol, ToRow, ToCol)
    ->  intermediate_square(FromRow, FromCol, ToRow, ToCol, IntRow, IntCol),
        get_piece(Board, IntRow, IntCol, IntPiece),
        is_opponent(IntPiece, Player)
    ).

% Check if a player has any jump moves
has_jump_moves(Board, Player) :-
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    piece_belongs_to_player(Piece, Player),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    is_jump(FromRow, FromCol, ToRow, ToCol),
    intermediate_square(FromRow, FromCol, ToRow, ToCol, IntRow, IntCol),
    get_piece(Board, IntRow, IntCol, IntPiece),
    is_opponent(IntPiece, Player),
    get_piece(Board, ToRow, ToCol, empty).

% Generate all legal moves
legal_move(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)) :-
    % If player has jump moves, only generate jump moves
    (   has_jump_moves(Board, Player)
    ->  is_jump(FromRow, FromCol, ToRow, ToCol)
    ;   true
    ),
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    piece_belongs_to_player(Piece, Player),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    can_move(Board, Player, FromRow, FromCol, ToRow, ToCol).

% Apply a simple move
apply_simple_move(Board, FromRow, FromCol, ToRow, ToCol, NewBoard) :-
    get_piece(Board, FromRow, FromCol, Piece),
    set_cell(FromRow, FromCol, Board, empty, TempBoard),
    % Promote to king if reached promotion row
    (   (Piece = dark_man, ToRow =:= 8)
    ->  NewPiece = dark_king
    ;   (Piece = light_man, ToRow =:= 1)
    ->  NewPiece = light_king
    ;   NewPiece = Piece
    ),
    set_cell(ToRow, ToCol, TempBoard, NewPiece, NewBoard).

% Apply a jump move
apply_jump_move(Board, FromRow, FromCol, ToRow, ToCol, NewBoard) :-
    get_piece(Board, FromRow, FromCol, Piece),
    intermediate_square(FromRow, FromCol, ToRow, ToCol, IntRow, IntCol),
    set_cell(FromRow, FromCol, Board, empty, TempBoard1),
    set_cell(IntRow, IntCol, TempBoard1, empty, TempBoard2),
    % Promote to king if reached promotion row
    (   (Piece = dark_man, ToRow =:= 8)
    ->  NewPiece = dark_king
    ;   (Piece = light_man, ToRow =:= 1)
    ->  NewPiece = light_king
    ;   NewPiece = Piece
    ),
    set_cell(ToRow, ToCol, TempBoard2, NewPiece, NewBoard).

% Check if a piece can make further jumps
can_jump_again(Board, Player, Row, Col) :-
    get_piece(Board, Row, Col, Piece),
    piece_belongs_to_player(Piece, Player),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    is_jump(Row, Col, ToRow, ToCol),
    intermediate_square(Row, Col, ToRow, ToCol, IntRow, IntCol),
    get_piece(Board, IntRow, IntCol, IntPiece),
    is_opponent(IntPiece, Player),
    get_piece(Board, ToRow, ToCol, empty).

% Apply move
apply_move(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol), NewState) :-
    can_move(Board, Player, FromRow, FromCol, ToRow, ToCol),
    (   is_jump(FromRow, FromCol, ToRow, ToCol)
    ->  apply_jump_move(Board, FromRow, FromCol, ToRow, ToCol, NewBoard)
    ;   apply_simple_move(Board, FromRow, FromCol, ToRow, ToCol, NewBoard)
    ),
    % Determine next player
    (   is_jump(FromRow, FromCol, ToRow, ToCol),
        (   can_jump_again(NewBoard, Player, ToRow, ToCol)
        ->  NextPlayer = Player  % Continue jumping
        ;   (Player = light -> NextPlayer = dark ; NextPlayer = light)
        )
    ->  true
    ;   (Player = light -> NextPlayer = dark ; NextPlayer = light)
    ),
    NewState = state(NewBoard, NextPlayer).

% Count pieces for a player
count_pieces(Board, Player, Count) :-
    findall(1,
            (between(1, 8, Row),
             between(1, 8, Col),
             get_piece(Board, Row, Col, Piece),
             piece_belongs_to_player(Piece, Player)),
            Pieces),
    length(Pieces, Count).

% Check if a player has any legal moves
has_legal_moves(Board, Player) :-
    legal_move(state(Board, Player), _), !.

% Game over conditions
game_over(state(Board, _), Winner) :-
    % Check win conditions
    count_pieces(Board, light, LightCount),
    count_pieces(Board, dark, DarkCount),
    (   LightCount =:= 0
    ->  Winner = dark
    ;   DarkCount =:= 0
    ->  Winner = light
    ;   \+ has_legal_moves(Board, light)
    ->  Winner = dark
    ;   \+ has_legal_moves(Board, dark)
    ->  Winner = light
    ),
    !.
game_over(state(Board, _), draw) :-
    % Check draw condition
    \+ has_jump_moves(Board, light),
    \+ has_jump_moves(Board, dark),
    !.

% Render state
render_state(state(Board, Player)) :-
    format('Current player: ~w~n', [Player]),
    format('  1 2 3 4 5 6 7 8~n'),
    render_board_rows(Board, 1).

render_board_rows([], _).
render_board_rows([Row|Rows], RowNum) :-
    format('~w ', [RowNum]),
    render_row(Row),
    nl,
    RowNum1 is RowNum + 1,
    render_board_rows(Rows, RowNum1).

render_row([]).
render_row([Piece|Pieces]) :-
    (   Piece = empty
    ->  format('. ')
    ;   Piece = light_man
    ->  format('l ')
    ;   Piece = dark_man
    ->  format('d ')
    ;   Piece = light_king
    ->  format('L ')
    ;   Piece = dark_king
    ->  format('D ')
    ),
    render_row(Pieces).