:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Board, Row, Col, Value, NewBoard) :-
    nth1(Row, Board, OldRow, RestRows),
    set_nth1(Col, OldRow, Value, NewRow),
    nth1(Row, NewBoard, NewRow, RestRows).

initial_state(state([
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,white,black,empty,empty,empty],
    [empty,empty,empty,black,white,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty]
], black)).

current_player(state(_, Player), Player).

% Legal move generator for Reversi
legal_move(State, Move) :-
    State = state(Board, Player),
    (   has_legal_placement(Board, Player)
    ->  Move = move(place, Row, Col),
        between(1, 8, Row),
        between(1, 8, Col),
        get_cell(Board, Row, Col, empty),
        outflanks_in_any_direction(Board, Row, Col, Player)
    ;   Move = move(pass)
    ).

% Check if there exists any legal placement for Player
has_legal_placement(Board, Player) :-
    between(1, 8, Row),
    between(1, 8, Col),
    get_cell(Board, Row, Col, empty),
    outflanks_in_any_direction(Board, Row, Col, Player),
    !.

% Check if placing at (Row, Col) outflanks opponent in any direction
outflanks_in_any_direction(Board, Row, Col, Player) :-
    direction(DR, DC),
    outflanks(Board, Row, Col, Player, DR, DC),
    !.

% Generate all 8 directions
direction(-1, -1).  % Up-left
direction(-1, 0).   % Up
direction(-1, 1).   % Up-right
direction(0, -1).   % Left
direction(0, 1).    % Right
direction(1, -1).   % Down-left
direction(1, 0).    % Down
direction(1, 1).    % Down-right

% Check if placing at (Row, Col) outflanks opponent pieces in direction (DR, DC)
outflanks(Board, Row, Col, Player, DR, DC) :-
    % First step must be onto opponent piece
    NR1 is Row + DR,
    NC1 is Col + DC,
    in_bounds(NR1, NC1),
    get_cell(Board, NR1, NC1, Opponent),
    opponent(Player, Opponent),
    % Continue in direction while finding opponent pieces
    find_line(Board, NR1, NC1, DR, DC, Player, Opponent, 1).

% Find a line of opponent pieces followed by own piece
find_line(Board, R, C, DR, DC, Player, Opponent, Count) :-
    NR is R + DR,
    NC is C + DC,
    in_bounds(NR, NC),
    get_cell(Board, NR, NC, Cell),
    (   Cell = Player
    ->  Count > 0  % Must have found at least one opponent piece
    ;   Cell = Opponent
    ->  NewCount is Count + 1,
        find_line(Board, NR, NC, DR, DC, Player, Opponent, NewCount)
    ).

% Check if coordinates are within board bounds
in_bounds(R, C) :-
    between(1, 8, R),
    between(1, 8, C).

% Get the value of a cell
get_cell(Board, Row, Col, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

% Define opponent relationship
opponent(black, white).
opponent(white, black).

% Apply a move to the game state
apply_move(State, Move, NewState) :-
    State = state(Board, Player),
    (   Move = move(place, Row, Col)
    ->  % Verify the placement is legal
        get_cell(Board, Row, Col, empty),
        outflanks_in_any_direction(Board, Row, Col, Player),
        % Place the piece
        set_cell(Board, Row, Col, Player, BoardWithPiece),
        % Flip outflanked pieces in all directions
        flip_all_directions(BoardWithPiece, Row, Col, Player, FlippedBoard),
        % Switch player
        opponent(Player, NextPlayer),
        NewState = state(FlippedBoard, NextPlayer)
    ;   Move = move(pass)
    ->  % Verify there are no legal placements
        \+ has_legal_placement(Board, Player),
        % Switch player
        opponent(Player, NextPlayer),
        NewState = state(Board, NextPlayer)
    ).

% Flip pieces in all directions where outflanking occurs
flip_all_directions(Board, Row, Col, Player, NewBoard) :-
    findall((DR, DC), 
            (direction(DR, DC), outflanks(Board, Row, Col, Player, DR, DC)), 
            OutflankingDirections),
    flip_in_directions(Board, Row, Col, Player, OutflankingDirections, NewBoard).

% Flip pieces in a list of directions
flip_in_directions(Board, _, _, _, [], Board).
flip_in_directions(Board, Row, Col, Player, [(DR, DC)|Rest], NewBoard) :-
    flip_pieces(Board, Row, Col, Player, DR, DC, IntermediateBoard),
    flip_in_directions(IntermediateBoard, Row, Col, Player, Rest, NewBoard).

% Flip pieces in one direction until reaching a piece of the current player
flip_pieces(Board, Row, Col, Player, DR, DC, NewBoard) :-
    NR is Row + DR,
    NC is Col + DC,
    in_bounds(NR, NC),
    get_cell(Board, NR, NC, Cell),
    (   Cell = Player
    ->  % Reached own piece, stop flipping
        NewBoard = Board
    ;   Cell \= empty
    ->  % Found opponent piece, flip it
        set_cell(Board, NR, NC, Player, UpdatedBoard),
        flip_pieces(UpdatedBoard, NR, NC, Player, DR, DC, NewBoard)
    ;   % Found empty cell, should not happen in a valid outflanking direction
        NewBoard = Board
    ).

% Check if the game is over and determine the winner
game_over(State, Winner) :-
    State = state(Board, CurrentPlayer),
    % Check if neither player has a legal move
    \+ has_legal_placement(Board, CurrentPlayer),
    opponent(CurrentPlayer, Opponent),
    \+ has_legal_placement(Board, Opponent),
    % Count pieces for each player
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    % Determine winner based on piece count
    (   BlackCount > WhiteCount
    ->  Winner = black
    ;   WhiteCount > BlackCount
    ->  Winner = white
    ;   Winner = draw
    ).

% Count the number of pieces a player has on the board
count_pieces(Board, Player, Count) :-
    flatten(Board, Cells),
    include(=(Player), Cells, PlayerCells),
    length(PlayerCells, Count).

% Render the game state
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
    (   Cell = empty ->
        write(' .')
    ;   Cell = black ->
        write(' b')
    ;   Cell = white ->
        write(' w')
    ),
    render_row_cells(Rest).