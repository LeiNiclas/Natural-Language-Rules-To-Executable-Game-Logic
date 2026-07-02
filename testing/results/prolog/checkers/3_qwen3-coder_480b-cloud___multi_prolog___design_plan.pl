:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Board, Row, Col, Value, NewBoard) :-
    nth1(Row, Board, OldRow, RestRows),
    set_nth1(Col, OldRow, Value, NewRow),
    nth1(Row, NewBoard, NewRow, RestRows).

% state(Board, CurrentPlayer)
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

current_player(state(_, Player), Player).

% Helper predicates
get_piece(Board, Row, Col, Piece) :-
    valid_position(Row, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).
get_piece(_, _, _, empty).

valid_position(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

is_player_piece(light_man, light).
is_player_piece(light_king, light).
is_player_piece(dark_man, dark).
is_player_piece(dark_king, dark).

is_opponent_piece(Piece, Player) :-
    is_player_piece(Piece, Opponent),
    Opponent \= Player.

is_forward_move(FromRow, ToRow, light) :- ToRow < FromRow.
is_forward_move(FromRow, ToRow, dark) :- ToRow > FromRow.

get_intermediate_square(FromRow, FromCol, ToRow, ToCol, MidRow, MidCol) :-
    MidRow is (FromRow + ToRow) // 2,
    MidCol is (FromCol + ToCol) // 2.

% Legal move predicate
legal_move(State, move(FromRow, FromCol, ToRow, ToCol)) :-
    State = state(Board, CurrentPlayer),
    valid_position(FromRow, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    is_player_piece(Piece, CurrentPlayer),
    
    valid_position(ToRow, ToCol),
    get_piece(Board, ToRow, ToCol, empty),
    
    DiffRow is ToRow - FromRow,
    DiffCol is ToCol - FromCol,
    abs(DiffRow, AbsDiffRow),
    abs(DiffCol, AbsDiffCol),
    AbsDiffRow =:= AbsDiffCol,
    
    (   AbsDiffRow =:= 1
    ->  (   Piece = light_man
        ->  is_forward_move(FromRow, ToRow, light)
        ;   Piece = dark_man
        ->  is_forward_move(FromRow, ToRow, dark)
        ;   true
        )
    ;   AbsDiffRow =:= 2
    ->  get_intermediate_square(FromRow, FromCol, ToRow, ToCol, MidRow, MidCol),
        get_piece(Board, MidRow, MidCol, MidPiece),
        is_opponent_piece(MidPiece, CurrentPlayer)
    ),
    
    % Check if any capture moves exist
    (   has_capture_moves(State)
    ->  AbsDiffRow =:= 2
    ;   true
    ).

has_capture_moves(state(Board, Player)) :-
    valid_position(FromRow, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    is_player_piece(Piece, Player),
    valid_position(ToRow, ToCol),
    get_piece(Board, ToRow, ToCol, empty),
    DiffRow is ToRow - FromRow,
    DiffCol is ToCol - FromCol,
    abs(DiffRow, 2),
    abs(DiffCol, 2),
    get_intermediate_square(FromRow, FromCol, ToRow, ToCol, MidRow, MidCol),
    get_piece(Board, MidRow, MidCol, MidPiece),
    is_opponent_piece(MidPiece, Player),
    !.

% Apply move predicate
apply_move(State, Move, NewState) :-
    State = state(Board, CurrentPlayer),
    Move = move(FromRow, FromCol, ToRow, ToCol),
    
    % Verify move is legal
    legal_move(State, Move),
    
    % Get the piece being moved
    get_piece(Board, FromRow, FromCol, Piece),
    
    % Remove piece from original position
    set_cell(Board, FromRow, FromCol, empty, Board1),
    
    % Handle capture
    (   abs(ToRow - FromRow) =:= 2
    ->  get_intermediate_square(FromRow, FromCol, ToRow, ToCol, MidRow, MidCol),
        set_cell(Board1, MidRow, MidCol, empty, Board2)
    ;   Board2 = Board1
    ),
    
    % Handle promotion
    (   (Piece = dark_man, ToRow =:= 8)
    ->  NewPiece = dark_king
    ;   (Piece = light_man, ToRow =:= 1)
    ->  NewPiece = light_king
    ;   NewPiece = Piece
    ),
    
    % Place piece in new position
    set_cell(Board2, ToRow, ToCol, NewPiece, Board3),
    
    % Determine next player
    (   abs(ToRow - FromRow) =:= 2,
        has_continuation_jumps(state(Board3, CurrentPlayer), ToRow, ToCol)
    ->  NextPlayer = CurrentPlayer
    ;   (CurrentPlayer = dark -> NextPlayer = light ; NextPlayer = dark)
    ),
    
    NewState = state(Board3, NextPlayer).

has_continuation_jumps(State, Row, Col) :-
    State = state(Board, Player),
    get_piece(Board, Row, Col, Piece),
    is_player_piece(Piece, Player),
    valid_position(ToRow, ToCol),
    get_piece(Board, ToRow, ToCol, empty),
    DiffRow is ToRow - Row,
    DiffCol is ToCol - Col,
    abs(DiffRow, 2),
    abs(DiffCol, 2),
    get_intermediate_square(Row, Col, ToRow, ToCol, MidRow, MidCol),
    get_piece(Board, MidRow, MidCol, MidPiece),
    is_opponent_piece(MidPiece, Player).

% Game over predicate
game_over(State, Winner) :-
    State = state(Board, CurrentPlayer),
    % Check if current player has no pieces
    \+ (valid_position(Row, Col),
        get_piece(Board, Row, Col, Piece),
        is_player_piece(Piece, CurrentPlayer)),
    % Determine winner
    (CurrentPlayer = light -> Winner = dark ; Winner = light).

game_over(State, Winner) :-
    State = state(Board, CurrentPlayer),
    % Check if current player has pieces but no legal moves
    (valid_position(Row, Col),
     get_piece(Board, Row, Col, Piece),
     is_player_piece(Piece, CurrentPlayer)),
    \+ has_legal_moves(State),
    % Determine winner
    (CurrentPlayer = light -> Winner = dark ; Winner = light).

game_over(State, draw) :-
    State = state(Board, _),
    % Check if neither player has any jump moves
    \+ has_any_jump_moves(Board, light),
    \+ has_any_jump_moves(Board, dark).

% Helper predicates for game_over
has_legal_moves(State) :-
    State = state(Board, Player),
    valid_position(FromRow, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    is_player_piece(Piece, Player),
    valid_position(ToRow, ToCol),
    legal_move(State, move(FromRow, FromCol, ToRow, ToCol)),
    !.

has_any_jump_moves(Board, Player) :-
    valid_position(FromRow, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    is_player_piece(Piece, Player),
    valid_position(ToRow, ToCol),
    get_piece(Board, ToRow, ToCol, empty),
    DiffRow is ToRow - FromRow,
    DiffCol is ToCol - FromCol,
    abs(DiffRow, 2),
    abs(DiffCol, 2),
    get_intermediate_square(FromRow, FromCol, ToRow, ToCol, MidRow, MidCol),
    get_piece(Board, MidRow, MidCol, MidPiece),
    is_opponent_piece(MidPiece, Player),
    !.

% Render state predicate
render_state(state(Board, CurrentPlayer)) :-
    write('  1 2 3 4 5 6 7 8'), nl,
    render_board_rows(Board, 1),
    format('Current player: ~w~n', [CurrentPlayer]).

render_board_rows([], _).
render_board_rows([Row|Rows], RowNum) :-
    format('~w ', [RowNum]),
    render_board_row(Row),
    nl,
    RowNum1 is RowNum + 1,
    render_board_rows(Rows, RowNum1).

render_board_row([]).
render_board_row([Piece|Pieces]) :-
    (Piece = empty -> write('. ') ;
     Piece = light_man -> write('l ') ;
     Piece = dark_man -> write('d ') ;
     Piece = light_king -> write('L ') ;
     Piece = dark_king -> write('D ')),
    render_board_row(Pieces).