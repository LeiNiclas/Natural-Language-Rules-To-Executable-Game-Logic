:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Board, Row, Col, Value, NewBoard) :-
    nth1(Row, Board, OldRow, RestBoard),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(Board, black)) :-
    Board = [
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,white,black,empty,empty,empty],
        [empty,empty,empty,black,white,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty]
    ].

current_player(state(_, Player), Player).

% Directions for adjacent cells (8 directions)
direction(-1, -1).  % Up-left
direction(-1, 0).   % Up
direction(-1, 1).   % Up-right
direction(0, -1).   % Left
direction(0, 1).    % Right
direction(1, -1).   % Down-left
direction(1, 0).    % Down
direction(1, 1).    % Down-right

% Check if position is within board bounds
in_bounds(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Get the value of a cell
get_cell(Board, Row, Col, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

% Find pieces that would be flipped in a specific direction
find_flipped_pieces(Board, Player, Row, Col, DeltaRow, DeltaCol, Flipped) :-
    NextRow is Row + DeltaRow,
    NextCol is Col + DeltaCol,
    find_flipped_pieces_helper(Board, Player, NextRow, NextCol, DeltaRow, DeltaCol, [], Flipped).

% Helper to collect flipped pieces in one direction
find_flipped_pieces_helper(Board, Player, Row, Col, _, _, Acc, Flipped) :-
    \+ in_bounds(Row, Col),
    Flipped = [].
find_flipped_pieces_helper(Board, Player, Row, Col, DeltaRow, DeltaCol, Acc, Flipped) :-
    in_bounds(Row, Col),
    get_cell(Board, Row, Col, empty),
    Flipped = [].
find_flipped_pieces_helper(Board, Player, Row, Col, DeltaRow, DeltaCol, Acc, Flipped) :-
    in_bounds(Row, Col),
    get_cell(Board, Row, Col, Player),
    Flipped = Acc.
find_flipped_pieces_helper(Board, Player, Row, Col, DeltaRow, DeltaCol, Acc, Flipped) :-
    in_bounds(Row, Col),
    get_cell(Board, Row, Col, Opponent),
    Player \= Opponent,
    Opponent \= empty,
    NextRow is Row + DeltaRow,
    NextCol is Col + DeltaCol,
    find_flipped_pieces_helper(Board, Player, NextRow, NextCol, DeltaRow, DeltaCol, [(Row,Col)|Acc], Flipped).

% Check if placing a piece at (Row, Col) is legal
is_legal_placement(Board, Player, Row, Col) :-
    get_cell(Board, Row, Col, empty),
    direction(DeltaRow, DeltaCol),
    find_flipped_pieces(Board, Player, Row, Col, DeltaRow, DeltaCol, Flipped),
    Flipped \= [],
    !.

% Check if player has any legal moves
has_legal_move(Board, Player) :-
    between(1, 8, Row),
    between(1, 8, Col),
    is_legal_placement(Board, Player, Row, Col),
    !.

% Generate all legal moves for the current state
legal_move(state(Board, Player), move(place, Row, Col)) :-
    between(1, 8, Row),
    between(1, 8, Col),
    is_legal_placement(Board, Player, Row, Col).
legal_move(state(Board, Player), move(pass)) :-
    \+ has_legal_move(Board, Player).

% Apply a move to the state
apply_move(State, Move, NewState) :-
    State = state(Board, Player),
    Move = move(place, Row, Col),
    is_legal_placement(Board, Player, Row, Col),
    set_cell(Board, Row, Col, Player, BoardWithPiece),
    flip_pieces_in_all_directions(BoardWithPiece, Player, Row, Col, FlippedBoard),
    next_player(Player, NextPlayer),
    NewState = state(FlippedBoard, NextPlayer).

apply_move(State, Move, NewState) :-
    State = state(Board, Player),
    Move = move(pass),
    \+ has_legal_move(Board, Player),
    next_player(Player, NextPlayer),
    NewState = state(Board, NextPlayer).

% Flip pieces in all directions after placing a piece
flip_pieces_in_all_directions(Board, Player, Row, Col, NewBoard) :-
    findall((DeltaRow, DeltaCol), direction(DeltaRow, DeltaCol), Directions),
    flip_pieces_in_directions(Board, Player, Row, Col, Directions, NewBoard).

% Flip pieces in a list of directions
flip_pieces_in_directions(Board, _, _, _, [], Board).
flip_pieces_in_directions(Board, Player, Row, Col, [(DeltaRow, DeltaCol)|Rest], NewBoard) :-
    find_flipped_pieces(Board, Player, Row, Col, DeltaRow, DeltaCol, Flipped),
    flip_pieces(Board, Flipped, Player, Board1),
    flip_pieces_in_directions(Board1, Player, Row, Col, Rest, NewBoard).

% Flip a list of pieces on the board
flip_pieces(Board, [], _, Board).
flip_pieces(Board, [(Row, Col)|Rest], Player, NewBoard) :-
    set_cell(Board, Row, Col, Player, Board1),
    flip_pieces(Board1, Rest, Player, NewBoard).

% Switch to the next player
next_player(black, white).
next_player(white, black).

% Count the number of pieces for a player
count_pieces(Board, Player, Count) :-
    flatten(Board, Cells),
    include(=(Player), Cells, PlayerCells),
    length(PlayerCells, Count).

% Check if the game is over
game_over(state(Board, _), Winner) :-
    \+ has_legal_move(Board, black),
    \+ has_legal_move(Board, white),
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; WhiteCount > BlackCount ->
        Winner = white
    ; Winner = draw
    ).

% Render the game state
render_state(state(Board, CurrentPlayer)) :-
    write('  a b c d e f g h'), nl,
    render_board_rows(Board, 8),
    write('  a b c d e f g h'), nl,
    format('Current player: ~w~n', [CurrentPlayer]).

render_board_rows([], _).
render_board_rows([Row|Rest], RowNum) :-
    format('~w |', [RowNum]),
    render_board_row(Row),
    nl,
    RowNum1 is RowNum - 1,
    render_board_rows(Rest, RowNum1).

render_board_row([]).
render_board_row([Cell|Rest]) :-
    (Cell = empty -> write(' .') ; format(' ~w', [Cell])),
    render_board_row(Rest).