:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow, RestRows),
    set_nth1(Col, OldRow, Value, NewRow),
    nth1(Row, NewBoard, NewRow, RestRows).

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

% Legal move implementation
legal_move(State, move(FromRow, FromCol, ToRow, ToCol)) :-
    State = state(Board, CurrentPlayer),
    % Generate all possible positions
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    % Check if there's a piece of the current player at the position
    nth1(FromRow, Board, Row),
    nth1(FromCol, Row, Piece),
    player_piece(CurrentPlayer, Piece),
    
    % Generate possible destination positions
    % Simple moves (diagonal, 1 step)
    (
        % Simple forward move for men
        (
            (Piece = dark_man -> 
                ToRow is FromRow + 1;
             Piece = light_man -> 
                ToRow is FromRow - 1;
             % Kings can move in any diagonal direction
             Piece = dark_king -> 
                (ToRow is FromRow + 1; ToRow is FromRow - 1);
             Piece = light_king -> 
                (ToRow is FromRow + 1; ToRow is FromRow - 1)
            ),
            (ToCol is FromCol + 1; ToCol is FromCol - 1)
        );
        % Jump moves (diagonal, 2 steps)
        (
            (Piece = dark_man -> 
                ToRow is FromRow + 2;
             Piece = light_man -> 
                ToRow is FromRow - 2;
             Piece = dark_king -> 
                (ToRow is FromRow + 2; ToRow is FromRow - 2);
             Piece = light_king -> 
                (ToRow is FromRow + 2; ToRow is FromRow - 2)
            ),
            (ToCol is FromCol + 2; ToCol is FromCol - 2)
        )
    ),
    
    % Check board bounds
    ToRow >= 1, ToRow =< 8,
    ToCol >= 1, ToCol =< 8,
    
    % Check if destination is empty
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    
    % For jump moves, check that the intermediate square contains an opponent piece
    (
        abs(ToRow - FromRow) =:= 1 -> 
            true;
        abs(ToRow - FromRow) =:= 2 ->
            IntermediateRow is (FromRow + ToRow) // 2,
            IntermediateCol is (FromCol + ToCol) // 2,
            nth1(IntermediateRow, Board, IntermediateRowList),
            nth1(IntermediateCol, IntermediateRowList, IntermediatePiece),
            opponent_piece(CurrentPlayer, IntermediatePiece)
    ),
    
    % If any capture move exists, only capture moves are legal
    (
        capture_moves_exist(State) ->
            abs(ToRow - FromRow) =:= 2;
        true
    ).

% Check if a piece belongs to the current player
player_piece(light, light_man).
player_piece(light, light_king).
player_piece(dark, dark_man).
player_piece(dark, dark_king).

% Check if a piece belongs to the opponent
opponent_piece(light, dark_man).
opponent_piece(light, dark_king).
opponent_piece(dark, light_man).
opponent_piece(dark, light_king).

% Check if there are any capture moves available for the current player
capture_moves_exist(State) :-
    State = state(Board, CurrentPlayer),
    between(1, 8, FromRow),
    between(1, 8, FromCol),
    nth1(FromRow, Board, Row),
    nth1(FromCol, Row, Piece),
    player_piece(CurrentPlayer, Piece),
    
    % Check for possible jumps
    (
        (Piece = dark_man -> 
            ToRow is FromRow + 2;
         Piece = light_man -> 
            ToRow is FromRow - 2;
         Piece = dark_king -> 
            (ToRow is FromRow + 2; ToRow is FromRow - 2);
         Piece = light_king -> 
            (ToRow is FromRow + 2; ToRow is FromRow - 2)
        ),
        (ToCol is FromCol + 2; ToCol is FromCol - 2)
    ),
    
    % Check board bounds
    ToRow >= 1, ToRow =< 8,
    ToCol >= 1, ToCol =< 8,
    
    % Check if destination is empty
    nth1(ToRow, Board, ToRowList),
    nth1(ToCol, ToRowList, empty),
    
    % Check that the intermediate square contains an opponent piece
    IntermediateRow is (FromRow + ToRow) // 2,
    IntermediateCol is (FromCol + ToCol) // 2,
    nth1(IntermediateRow, Board, IntermediateRowList),
    nth1(IntermediateCol, IntermediateRowList, IntermediatePiece),
    opponent_piece(CurrentPlayer, IntermediatePiece), !.

% Apply a move to the state
apply_move(State, move(FromRow, FromCol, ToRow, ToCol), NewState) :-
    State = state(Board, CurrentPlayer),
    % Check if the move is legal
    legal_move(State, move(FromRow, FromCol, ToRow, ToCol)),
    
    % Get the piece being moved
    nth1(FromRow, Board, FromRowList),
    nth1(FromCol, FromRowList, Piece),
    
    % Check if this is a jump move
    (abs(ToRow - FromRow) =:= 2 ->
        % It's a jump, remove the captured piece
        IntermediateRow is (FromRow + ToRow) // 2,
        IntermediateCol is (FromCol + ToCol) // 2,
        set_cell(IntermediateRow, IntermediateCol, Board, empty, BoardAfterCapture),
        
        % Move the piece
        set_cell(FromRow, FromCol, BoardAfterCapture, empty, BoardAfterFrom),
        % Check for promotion
        (promote_piece(Piece, ToRow, NewPiece) ->
            set_cell(ToRow, ToCol, BoardAfterFrom, NewPiece, BoardAfterTo)
        ;
            set_cell(ToRow, ToCol, BoardAfterFrom, Piece, BoardAfterTo)
        ),
        
        % Check if the piece can make another jump
        (can_jump_again(ToRow, ToCol, BoardAfterTo, CurrentPlayer, Piece) ->
            % If it can, keep the same player
            NewState = state(BoardAfterTo, CurrentPlayer)
        ;
            % Otherwise, switch players
            switch_player(CurrentPlayer, NextPlayer),
            NewState = state(BoardAfterTo, NextPlayer)
        )
    ;
        % Simple move
        set_cell(FromRow, FromCol, Board, empty, BoardAfterFrom),
        % Check for promotion
        (promote_piece(Piece, ToRow, NewPiece) ->
            set_cell(ToRow, ToCol, BoardAfterFrom, NewPiece, BoardAfterTo)
        ;
            set_cell(ToRow, ToCol, BoardAfterFrom, Piece, BoardAfterTo)
        ),
        
        % Switch players
        switch_player(CurrentPlayer, NextPlayer),
        NewState = state(BoardAfterTo, NextPlayer)
    ).

% Check if a piece should be promoted
promote_piece(dark_man, 8, dark_king).
promote_piece(light_man, 1, light_king).
promote_piece(Piece, _, Piece).

% Switch player
switch_player(light, dark).
switch_player(dark, light).

% Check if a piece can make another jump
can_jump_again(Row, Col, Board, Player, Piece) :-
    % Check all possible jump directions
    (Piece = dark_man ->
        % Dark man can only move forward (down the board)
        Directions = [(2, 2), (2, -2)]
    ;
    Piece = light_man ->
        % Light man can only move forward (up the board)
        Directions = [(-2, 2), (-2, -2)]
    ;
    % Kings can move in any direction
    Piece = dark_king ->
        Directions = [(2, 2), (2, -2), (-2, 2), (-2, -2)]
    ;
    Piece = light_king ->
        Directions = [(2, 2), (2, -2), (-2, 2), (-2, -2)]
    ),
    
    member((DR, DC), Directions),
    NewRow is Row + DR,
    NewCol is Col + DC,
    NewRow >= 1, NewRow =< 8,
    NewCol >= 1, NewCol =< 8,
    
    % Check if destination is empty
    nth1(NewRow, Board, NewRowList),
    nth1(NewCol, NewRowList, empty),
    
    % Check that the intermediate square contains an opponent piece
    IntermediateRow is (Row + NewRow) // 2,
    IntermediateCol is (Col + NewCol) // 2,
    nth1(IntermediateRow, Board, IntermediateRowList),
    nth1(IntermediateCol, IntermediateRowList, IntermediatePiece),
    opponent_piece(Player, IntermediatePiece).

% Check if the game is over
game_over(State, Winner) :-
    State = state(Board, CurrentPlayer),
    % Count pieces for each player
    count_pieces(Board, light, LightPieces),
    count_pieces(Board, dark, DarkPieces),
    
    % Check win conditions
    (LightPieces = 0 ->
        Winner = dark
    ;
     DarkPieces = 0 ->
        Winner = light
    ;
     % Check if current player has any legal moves
     \+ has_legal_moves(State) ->
        (CurrentPlayer = light ->
            Winner = dark
        ;
            Winner = light
        )
    ;
     % Check draw condition: neither player has any jump moves
     \+ capture_moves_exist(state(Board, light)),
     \+ capture_moves_exist(state(Board, dark)) ->
        Winner = draw
    ).

% Count pieces of a specific player
count_pieces(Board, Player, Count) :-
    flatten(Board, Pieces),
    include(player_piece(Player), Pieces, PlayerPieces),
    length(PlayerPieces, Count).

% Check if a piece belongs to a player (for use with include/3)
player_piece(light, light_man).
player_piece(light, light_king).
player_piece(dark, dark_man).
player_piece(dark, dark_king).

% Check if the current player has any legal moves
has_legal_moves(State) :-
    % Try to find at least one legal move
    legal_move(State, _), !.

% Render the current state of the game
render_state(state(Board, CurrentPlayer)) :-
    write('  a b c d e f g h'), nl,
    render_board_rows(Board, 8),
    write('  a b c d e f g h'), nl,
    format('Current player: ~w~n', [CurrentPlayer]).

render_board_rows([], _).
render_board_rows([Row|Rest], RowNum) :-
    format('~w |', [RowNum]),
    render_row_cells(Row),
    nl,
    NextRowNum is RowNum - 1,
    render_board_rows(Rest, NextRowNum).

render_row_cells([]).
render_row_cells([Cell|Rest]) :-
    (Cell = empty -> write(' .')
    ;Cell = light_man -> write(' l')
    ;Cell = dark_man -> write(' d')
    ;Cell = light_king -> write(' L')
    ;Cell = dark_king -> write(' D')
    ),
    render_row_cells(Rest).