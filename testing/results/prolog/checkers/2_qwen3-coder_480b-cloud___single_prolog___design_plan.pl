:- use_module(library(lists)).
:- use_module(library(apply)).

% state(Board, CurrentPlayer)
% Board is a list of 8 rows, each row is a list of 8 cells
% Each cell is one of: empty, light_man, dark_man, light_king, dark_king
% CurrentPlayer is either light or dark

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

% Helper to get a piece at a given position
get_piece(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Helper to set a piece at a given position
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Helper to remove a piece at a given position
remove_piece(Board, Row, Col, NewBoard) :-
    set_cell(Row, Col, Board, empty, NewBoard).

% Check if a piece is a king
is_king(light_king).
is_king(dark_king).

% Check if a piece is a man
is_man(light_man).
is_man(dark_man).

% Get opponent player
opponent(light, dark).
opponent(dark, light).

% Get forward direction for a player
forward_direction(dark, 1).
forward_direction(light, -1).

% Check if a position is valid
valid_position(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Check if a move is a capture
is_capture_move(FromRow, FromCol, ToRow, ToCol) :-
    DiffRow is abs(ToRow - FromRow),
    DiffCol is abs(ToCol - FromCol),
    DiffRow =:= 2,
    DiffCol =:= 2.

% Find all possible captures for a piece
can_capture(state(Board, Player), Row, Col, Captures) :-
    get_piece(Board, Row, Col, Piece),
    (Piece = Player -> Type = man ; 
     (Piece = light_man -> (Player = light -> Type = man ; Type = opponent_man) ;
      (Piece = dark_man -> (Player = dark -> Type = man ; Type = opponent_man) ;
       (Piece = light_king -> (Player = light -> Type = king ; Type = opponent_king) ;
        (Piece = dark_king -> (Player = dark -> Type = king ; Type = opponent_king)))))),
    findall(move(Row, Col, ToRow, ToCol),
            (valid_position(ToRow, ToCol),
             is_capture_move(Row, Col, ToRow, ToCol),
             MiddleRow is (Row + ToRow) // 2,
             MiddleCol is (Col + ToCol) // 2,
             get_piece(Board, MiddleRow, MiddleCol, MiddlePiece),
             MiddlePiece \= empty,
             opponent(Player, Opponent),
             (MiddlePiece = Opponent ; 
              (MiddlePiece = light_man, Opponent = light) ;
              (MiddlePiece = dark_man, Opponent = dark) ;
              (MiddlePiece = light_king, Opponent = light) ;
              (MiddlePiece = dark_king, Opponent = dark)),
             get_piece(Board, ToRow, ToCol, TargetPiece),
             TargetPiece = empty,
             (Type = man ->
                 (Player = dark -> ToRow > Row ;
                  Player = light -> ToRow < Row)
             ; true)
            ),
            Captures).

% Check if player has any legal moves
has_legal_moves(State, Player, HasMoves) :-
    State = state(Board, _),
    findall((Row, Col), 
            (between(1, 8, Row),
             between(1, 8, Col),
             get_piece(Board, Row, Col, Piece),
             (Piece = Player ;
              (Piece = light_man, Player = light) ;
              (Piece = dark_man, Player = dark) ;
              (Piece = light_king, Player = light) ;
              (Piece = dark_king, Player = dark))),
            Positions),
    (Positions = [] -> HasMoves = false ;
     (forall(member((Row, Col), Positions),
             (can_capture(State, Row, Col, Captures),
              Captures = [])) ->
         findall(move(Row, Col, ToRow, ToCol),
                 (member((Row, Col), Positions),
                  get_piece(Board, Row, Col, Piece),
                  valid_position(ToRow, ToCol),
                  get_piece(Board, ToRow, ToCol, TargetPiece),
                  TargetPiece = empty,
                  DiffRow is abs(ToRow - Row),
                  DiffCol is abs(ToCol - Col),
                  DiffRow =:= 1,
                  DiffCol =:= 1,
                  (is_man(Piece) ->
                      (Player = dark -> ToRow > Row ;
                       Player = light -> ToRow < Row)
                  ; true)
                 ),
                 Moves),
         (Moves = [] -> HasMoves = false ; HasMoves = true)
     ; HasMoves = true)).

% Promote a piece if it reaches the promotion row
promote_piece(light_man, 1, light_king).
promote_piece(dark_man, 8, dark_king).
promote_piece(Piece, _, Piece).

% Find all pieces of a player
find_all_pieces(Board, Player, Positions) :-
    findall((Row, Col),
            (between(1, 8, Row),
             between(1, 8, Col),
             get_piece(Board, Row, Col, Piece),
             (Piece = Player ;
              (Piece = light_man, Player = light) ;
              (Piece = dark_man, Player = dark) ;
              (Piece = light_king, Player = light) ;
              (Piece = dark_king, Player = dark))),
            Positions).

% Check if there are any capture moves available for a player
has_capture_moves(State, Player, HasCapture) :-
    State = state(Board, _),
    find_all_pieces(Board, Player, Positions),
    (forall(member((Row, Col), Positions),
            (can_capture(State, Row, Col, Captures),
             Captures = [])) ->
        HasCapture = false
    ; HasCapture = true).

% Legal move generator
legal_move(State, Move) :-
    State = state(Board, Player),
    % First check if there are any capture moves
    has_capture_moves(State, Player, HasCapture),
    % Generate all possible moves
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    get_piece(Board, FromRow, FromCol, Piece),
    (Piece = Player ;
     (Piece = light_man, Player = light) ;
     (Piece = dark_man, Player = dark) ;
     (Piece = light_king, Player = light) ;
     (Piece = dark_king, Player = dark)),
    % Try simple moves if no captures
    (HasCapture = false ->
        between(1, 8, ToRow),
        between(1, 8, ToCol),
        get_piece(Board, ToRow, ToCol, TargetPiece),
        TargetPiece = empty,
        DiffRow is abs(ToRow - FromRow),
        DiffCol is abs(ToCol - FromCol),
        DiffRow =:= 1,
        DiffCol =:= 1,
        (is_man(Piece) ->
            (Player = dark -> ToRow > FromRow ;
             Player = light -> ToRow < FromRow)
        ; true),
        Move = move(FromRow, FromCol, ToRow, ToCol)
    ; % Try capture moves
        can_capture(State, FromRow, FromCol, Captures),
        member(Move, Captures)
    ).

% Apply a move
apply_move(State, Move, NewState) :-
    State = state(Board, Player),
    Move = move(FromRow, FromCol, ToRow, ToCol),
    
    % Check if move is legal
    legal_move(State, Move),
    
    % Get the piece being moved
    get_piece(Board, FromRow, FromCol, Piece),
    
    % Remove piece from original position
    remove_piece(Board, FromRow, FromCol, Board1),
    
    % Check if this is a capture move
    (is_capture_move(FromRow, FromCol, ToRow, ToCol) ->
        % Remove the captured piece
        MiddleRow is (FromRow + ToRow) // 2,
        MiddleCol is (FromCol + ToCol) // 2,
        remove_piece(Board1, MiddleRow, MiddleCol, Board2)
    ; Board2 = Board1),
    
    % Place piece at new position
    promote_piece(Piece, ToRow, NewPiece),
    set_cell(ToRow, ToCol, Board2, NewPiece, NewBoard),
    
    % Check if further captures are possible
    (is_capture_move(FromRow, FromCol, ToRow, ToCol) ->
        can_capture(state(NewBoard, Player), ToRow, ToCol, FurtherCaptures),
        (FurtherCaptures = [] ->
            opponent(Player, NextPlayer),
            NewState = state(NewBoard, NextPlayer)
        ; NewState = state(NewBoard, Player))
    ; opponent(Player, NextPlayer),
      NewState = state(NewBoard, NextPlayer)).

% Game over conditions
game_over(State, Winner) :-
    State = state(Board, Player),
    % Check if opponent has no pieces
    opponent(Player, Opponent),
    find_all_pieces(Board, Opponent, OpponentPieces),
    (OpponentPieces = [] ->
        Winner = Player
    ; % Check if opponent has no legal moves
        has_legal_moves(State, Opponent, HasMoves),
        HasMoves = false ->
        Winner = Player
    ; % Check for draw condition
        has_capture_moves(State, Player, PlayerHasCapture),
        has_capture_moves(State, Opponent, OpponentHasCapture),
        PlayerHasCapture = false,
        OpponentHasCapture = false ->
        Winner = draw
    ).

% Render state
render_state(state(Board, Player)) :-
    format('Current player: ~w~n', [Player]),
    format('  1 2 3 4 5 6 7 8~n'),
    foldl(render_row, Board, 1, _).

render_row(Row, Index, NextIndex) :-
    format('~w ', [Index]),
    maplist(render_cell, Row),
    nl,
    NextIndex is Index + 1.

render_cell(empty) :- format('. ').
render_cell(light_man) :- format('o ').
render_cell(dark_man) :- format('x ').
render_cell(light_king) :- format('O ').
render_cell(dark_king) :- format('X ').