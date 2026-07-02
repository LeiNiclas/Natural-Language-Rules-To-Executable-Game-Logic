:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 8x8 list of lists
% Atoms: empty, black, white
% Rows 1-8 (top to bottom), Cols 1-8 (left to right)

% Helper to set a cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state: 8x8 board with center pieces set
initial_state(state(Board, black)) :-
    % Create 8x8 empty board
    length(EmptyRow, 8),
    maplist(=(empty), EmptyRow),
    length(BoardRows, 8),
    maplist(=(EmptyRow), BoardRows),
    % Set initial pieces
    set_cell(4, 4, BoardRows, white, B1),
    set_cell(4, 5, B1, black, B2),
    set_cell(5, 4, B2, black, B3),
    set_cell(5, 5, B3, white, Board).

% Current player in state
current_player(state(_, Player), Player).

% Generate all 8 directions
direction(-1, -1). direction(-1, 0). direction(-1, 1).
direction(0, -1).                  direction(0, 1).
direction(1, -1).  direction(1, 0).  direction(1, 1).

% Check if position is within bounds
in_bounds(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Get cell value at position
get_cell(Board, Row, Col, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

% Find a line of opponent pieces ending in player's piece
find_line(Board, Row, Col, DeltaRow, DeltaCol, Player, [(Row,Col)|Line]) :-
    NextRow is Row + DeltaRow,
    NextCol is Col + DeltaCol,
    in_bounds(NextRow, NextCol),
    get_cell(Board, NextRow, NextCol, Opponent),
    Opponent \= empty,
    Opponent \= Player,
    find_line_continuation(Board, NextRow, NextCol, DeltaRow, DeltaCol, Player, Line).

find_line_continuation(Board, Row, Col, DeltaRow, DeltaCol, Player, [(Row,Col)|Rest]) :-
    NextRow is Row + DeltaRow,
    NextCol is Col + DeltaCol,
    in_bounds(NextRow, NextCol),
    get_cell(Board, NextRow, NextCol, Value),
    (Value = Player ->
        Rest = []
    ;
        Value = empty ->
        fail
    ;
        find_line_continuation(Board, NextRow, NextCol, DeltaRow, DeltaCol, Player, Rest)
    ).

% Flip all positions in a line
flip_line(Board, [], _, Board).
flip_line(Board, [(Row,Col)|Rest], Player, NewBoard) :-
    set_cell(Row, Col, Board, Player, TempBoard),
    flip_line(TempBoard, Rest, Player, NewBoard).

% Check if player has any legal place moves
has_legal_place_moves(Board, Player) :-
    between(1, 8, Row),
    between(1, 8, Col),
    legal_place_move(Board, Player, Row, Col),
    !.

% Check if a place move is legal
legal_place_move(Board, Player, Row, Col) :-
    get_cell(Board, Row, Col, empty),
    direction(DeltaRow, DeltaCol),
    find_line(Board, Row, Col, DeltaRow, DeltaCol, Player, _),
    !.

% Legal move generator
legal_move(State, Move) :-
    State = state(Board, Player),
    (   has_legal_place_moves(Board, Player) ->
        Move = move(place, Row, Col),
        legal_place_move(Board, Player, Row, Col)
    ;   Move = move(pass)
    ).

% Apply move to state
apply_move(state(Board, Player), move(place, Row, Col), state(NewBoard, NextPlayer)) :-
    get_cell(Board, Row, Col, empty),
    % Collect all lines to flip
    findall(Line,
            (direction(DeltaRow, DeltaCol),
             find_line(Board, Row, Col, DeltaRow, DeltaCol, Player, Line)),
            Lines),
    Lines \= [],
    % Place the piece
    set_cell(Row, Col, Board, Player, BoardWithPiece),
    % Flip all lines
    foldl(flip_line(Player), Lines, BoardWithPiece, FlippedBoard),
    % Switch player
    (Player = black -> NextPlayer = white ; NextPlayer = black),
    NewBoard = FlippedBoard.

apply_move(state(Board, Player), move(pass), state(Board, NextPlayer)) :-
    (Player = black -> NextPlayer = white ; NextPlayer = black).

flip_line(_, [], Board, Board).
flip_line(Player, [(_,_)|_], Board, NewBoard) :-
    flip_line(Board, [(_,_)|_], Player, NewBoard).

% Game over conditions
game_over(state(Board, _), Winner) :-
    % Check if game is over (no legal moves for either player)
    \+ has_legal_place_moves(Board, black),
    \+ has_legal_place_moves(Board, white),
    % Count pieces
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; WhiteCount > BlackCount ->
        Winner = white
    ; Winner = draw).

% Count pieces for a player
count_pieces(Board, Player, Count) :-
    flatten(Board, Cells),
    include(=(Player), Cells, PlayerCells),
    length(PlayerCells, Count).

% Render state
render_state(state(Board, Player)) :-
    format('  1 2 3 4 5 6 7 8~n'),
    render_board_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

render_board_rows([], _).
render_board_rows([Row|Rows], N) :-
    format('~w ', [N]),
    render_row_cells(Row),
    nl,
    N1 is N + 1,
    render_board_rows(Rows, N1).

render_row_cells([]).
render_row_cells([Cell|Cells]) :-
    (Cell = empty ->
        format('. ')
    ; Cell = black ->
        format('B ')
    ; Cell = white ->
        format('W ')
    ),
    render_row_cells(Cells).