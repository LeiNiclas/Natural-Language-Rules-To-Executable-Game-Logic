:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Board, CurrentPlayer)
% Board = [[...], [...], ...] - 8x8 list of piece atoms
% CurrentPlayer = dark | light

initial_state(state(
    [
        [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
        [dark_man, empty, dark_man, empty, dark_man, empty, dark_man, empty],
        [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [light_man, empty, light_man, empty, light_man, empty, light_man, empty],
        [empty, light_man, empty, light_man, empty, light_man, empty, light_man],
        [light_man, empty, light_man, empty, light_man, empty, light_man, empty]
    ],
    dark
)).

current_player(state(_, P), P).

% Helper to get a piece at a specific position
get_piece(Board, Row, Col, Piece) :-
    valid_position(Row, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Helper to check if position is valid
valid_position(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Helper to check if a piece belongs to a player
is_player_piece(dark_man, dark).
is_player_piece(dark_king, dark).
is_player_piece(light_man, light).
is_player_piece(light_king, light).

% Helper to check if a piece belongs to the opponent
is_opponent_piece(dark_man, light).
is_opponent_piece(dark_king, light).
is_opponent_piece(light_man, dark).
is_opponent_piece(light_king, dark).

% Helper to check if a piece is a king
is_king(dark_king).
is_king(light_king).

% Helper to check if a move is forward for men
is_forward_move(FromRow, ToRow, dark) :- ToRow > FromRow.
is_forward_move(FromRow, ToRow, light) :- ToRow < FromRow.

% Helper to calculate the position jumped over
calculate_jump_over(FromRow, FromCol, ToRow, ToCol, JumpRow, JumpCol) :-
    JumpRow is (FromRow + ToRow) // 2,
    JumpCol is (FromCol + ToCol) // 2.

% Helper to set a cell in the board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Find all legal moves for a player
find_all_moves(state(Board, Player), Player, Moves) :-
    findall(move(FromRow, FromCol, ToRow, ToCol),
            (between(1, 8, FromRow),
             between(1, 8, FromCol),
             get_piece(Board, FromRow, FromCol, Piece),
             is_player_piece(Piece, Player),
             between(1, 8, ToRow),
             between(1, 8, ToCol),
             legal_move_internal(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol))),
            Moves).

% Find all capture moves for a player
find_capture_moves(state(Board, Player), Player, Moves) :-
    findall(move(FromRow, FromCol, ToRow, ToCol),
            (between(1, 8, FromRow),
             between(1, 8, FromCol),
             get_piece(Board, FromRow, FromCol, Piece),
             is_player_piece(Piece, Player),
             between(1, 8, ToRow),
             between(1, 8, ToCol),
             legal_move_internal(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)),
             abs(ToRow - FromRow) =:= 2),
            Moves).

% Check if a piece can make another jump
can_jump_again(Board, Row, Col, Player) :-
    get_piece(Board, Row, Col, Piece),
    is_player_piece(Piece, Player),
    % Try all possible jump directions
    (   is_king(Piece) ->
        Directions = [(-2,-2), (-2,2), (2,-2), (2,2)]
    ;   (Player = dark ->
            Directions = [(2,-2), (2,2)]
        ;   Directions = [(-2,-2), (-2,2)]
        )
    ),
    member((DR, DC), Directions),
    ToRow is Row + DR,
    ToCol is Col + DC,
    valid_position(ToRow, ToCol),
    get_piece(Board, ToRow, ToCol, empty),
    calculate_jump_over(Row, Col, ToRow, ToCol, JumpRow, JumpCol),
    get_piece(Board, JumpRow, JumpCol, JumpedPiece),
    is_opponent_piece(JumpedPiece, Player).

% Count pieces for a player
count_pieces(Board, Player, Count) :-
    findall(_, 
            (between(1, 8, Row),
             between(1, 8, Col),
             get_piece(Board, Row, Col, Piece),
             is_player_piece(Piece, Player)),
            Pieces),
    length(Pieces, Count).

% Check if player has legal moves
has_legal_moves(State, Player) :-
    find_all_moves(State, Player, Moves),
    Moves \= [].

% Internal helper to check if a move is legal
legal_move_internal(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)) :-
    % Check if positions are valid
    valid_position(FromRow, FromCol),
    valid_position(ToRow, ToCol),
    
    % Check if there's a piece belonging to the player at the source
    get_piece(Board, FromRow, FromCol, Piece),
    is_player_piece(Piece, Player),
    
    % Check if destination is empty
    get_piece(Board, ToRow, ToCol, empty),
    
    % Check if move is diagonal
    DR is abs(ToRow - FromRow),
    DC is abs(ToCol - FromCol),
    DR = DC,
    
    % Check move type (simple or jump)
    (   DR =:= 1 ->
        % Simple move: check direction for men
        (   is_king(Piece) ->
            true
        ;   is_forward_move(FromRow, ToRow, Player)
        )
    ;   DR =:= 2 ->
        % Jump move: check if intermediate square has opponent piece
        calculate_jump_over(FromRow, FromCol, ToRow, ToCol, JumpRow, JumpCol),
        get_piece(Board, JumpRow, JumpCol, JumpedPiece),
        is_opponent_piece(JumpedPiece, Player)
    ).

% Main legal_move predicate
legal_move(State, Move) :-
    State = state(Board, Player),
    legal_move_internal(State, Move),
    
    % Check if there are capture moves available
    find_capture_moves(State, Player, CaptureMoves),
    (   CaptureMoves = [] ->
        true  % No captures, simple move is allowed
    ;   % Captures exist, move must be a capture
        Move = move(FromRow, FromCol, ToRow, ToCol),
        abs(ToRow - FromRow) =:= 2
    ).

% Apply a move
apply_move(State, Move, NewState) :-
    State = state(Board, Player),
    Move = move(FromRow, FromCol, ToRow, ToCol),
    
    % Get the piece being moved
    get_piece(Board, FromRow, FromCol, Piece),
    
    % Check if it's a jump move
    DR is abs(ToRow - FromRow),
    (   DR =:= 2 ->
        % It's a jump, remove the jumped piece
        calculate_jump_over(FromRow, FromCol, ToRow, ToCol, JumpRow, JumpCol),
        set_cell(JumpRow, JumpCol, Board, empty, BoardAfterJump)
    ;   BoardAfterJump = Board
    ),
    
    % Move the piece
    set_cell(FromRow, FromCol, BoardAfterJump, empty, BoardAfterRemoval),
    set_cell(ToRow, ToCol, BoardAfterRemoval, Piece, BoardAfterMove),
    
    % Check for promotion
    (   (Player = dark, ToRow =:= 8, Piece = dark_man) ->
        set_cell(ToRow, ToCol, BoardAfterMove, dark_king, BoardAfterPromotion)
    ;   (Player = light, ToRow =:= 1, Piece = light_man) ->
        set_cell(ToRow, ToCol, BoardAfterMove, light_king, BoardAfterPromotion)
    ;   BoardAfterPromotion = BoardAfterMove
    ),
    
    % Check if another jump is possible
    (   DR =:= 2, can_jump_again(BoardAfterPromotion, ToRow, ToCol, Player) ->
        NewState = state(BoardAfterPromotion, Player)
    ;   % Switch player
        (Player = dark -> NextPlayer = light ; NextPlayer = dark),
        NewState = state(BoardAfterPromotion, NextPlayer)
    ).

% Check if game is over
game_over(state(Board, _), Winner) :-
    % Check if a player has no pieces
    count_pieces(Board, dark, DarkCount),
    count_pieces(Board, light, LightCount),
    (   DarkCount =:= 0 ->
        Winner = light
    ;   LightCount =:= 0 ->
        Winner = dark
    ;   % Check if a player has no legal moves
        \+ has_legal_moves(state(Board, dark)) ->
        Winner = light
    ;   \+ has_legal_moves(state(Board, light)) ->
        Winner = dark
    ).

% Check for draw condition
game_over(state(Board, _), draw) :-
    % Neither player has any jump moves available
    findall(_, (between(1, 8, Row), between(1, 8, Col), 
                get_piece(Board, Row, Col, Piece),
                (is_player_piece(Piece, dark) ; is_player_piece(Piece, light)),
                can_jump_again(Board, Row, Col, dark)), DarkJumps),
    findall(_, (between(1, 8, Row), between(1, 8, Col), 
                get_piece(Board, Row, Col, Piece),
                (is_player_piece(Piece, dark) ; is_player_piece(Piece, light)),
                can_jump_again(Board, Row, Col, light)), LightJumps),
    DarkJumps = [],
    LightJumps = [].

% Render the state
render_state(state(Board, Player)) :-
    format('Current player: ~w~n', [Player]),
    format('  1 2 3 4 5 6 7 8~n'),
    render_board_rows(Board, 1).

render_board_rows([], _).
render_board_rows([Row|Rest], RowNum) :-
    format('~w ', [RowNum]),
    render_board_row(Row),
    nl,
    NextRowNum is RowNum + 1,
    render_board_rows(Rest, NextRowNum).

render_board_row([]).
render_board_row([Piece|Rest]) :-
    (   Piece = empty ->
        format('. ')
    ;   Piece = dark_man ->
        format('d ')
    ;   Piece = dark_king ->
        format('D ')
    ;   Piece = light_man ->
        format('l ')
    ;   Piece = light_king ->
        format('L ')
    ),
    render_board_row(Rest).