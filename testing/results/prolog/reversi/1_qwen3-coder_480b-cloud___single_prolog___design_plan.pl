:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 8x8 list of lists
% Cell values: empty, black, white
% state(Board, CurrentPlayer)

% Helper to update a cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Helper to read a cell
get_cell(Board, Row, Col, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

% Directions: up, down, left, right, and 4 diagonals
direction(-1, 0).  % up
direction(1, 0).   % down
direction(0, -1).  % left
direction(0, 1).   % right
direction(-1, -1). % up-left
direction(-1, 1).  % up-right
direction(1, -1).  % down-left
direction(1, 1).   % down-right

% Check if position is on board
in_bounds(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Initial state: 8x8 board with center pieces set
initial_state(state(Board, black)) :-
    % Create 8x8 empty board
    length(EmptyRow, 8),
    maplist(=(empty), EmptyRow),
    length(BoardRows, 8),
    maplist(=(EmptyRow), BoardRows),
    % Set center pieces
    set_cell(4, 4, BoardRows, white, B1),
    set_cell(4, 5, B1, black, B2),
    set_cell(5, 4, B2, black, B3),
    set_cell(5, 5, B3, white, Board).

% Current player
current_player(state(_, Player), Player).

% Find a line of opponent pieces followed by own piece
find_line(Board, Row, Col, DeltaRow, DeltaCol, Player, Line) :-
    find_line_helper(Board, Row, Col, DeltaRow, DeltaCol, Player, [], Line).

find_line_helper(Board, Row, Col, DeltaRow, DeltaCol, Player, Acc, Line) :-
    NewRow is Row + DeltaRow,
    NewCol is Col + DeltaCol,
    (   in_bounds(NewRow, NewCol) ->
        get_cell(Board, NewRow, NewCol, Cell),
        (   Cell = empty ->
            fail  % Line ends with empty cell
        ;   Cell = Player ->
            (   Acc = [] ->
                fail  % No opponent pieces to flip
            ;   reverse(Acc, Line)  % Valid line found
            )
        ;   % Opponent piece, continue
            find_line_helper(Board, NewRow, NewCol, DeltaRow, DeltaCol, Player, [NewRow-NewCol|Acc], Line)
        )
    ;   fail  % Out of bounds
    ).

% Check if a placement is legal
is_legal_placement(Board, Row, Col, Player) :-
    get_cell(Board, Row, Col, empty),  % Must be empty
    direction(DeltaRow, DeltaCol),
    find_line(Board, Row, Col, DeltaRow, DeltaCol, Player, _Line),
    !.  % At least one valid direction

% Check if player has any legal moves
has_legal_move(Board, Player) :-
    between(1, 8, Row),
    between(1, 8, Col),
    is_legal_placement(Board, Row, Col, Player),
    !.

% Legal moves
legal_move(State, move(place, Row, Col)) :-
    State = state(Board, Player),
    is_legal_placement(Board, Row, Col, Player).

legal_move(State, move(pass)) :-
    State = state(Board, Player),
    \+ has_legal_move(Board, Player).

% Apply move
apply_move(State, move(place, Row, Col), NewState) :-
    State = state(Board, Player),
    is_legal_placement(Board, Row, Col, Player),
    % Place the piece
    set_cell(Row, Col, Board, Player, BoardWithPiece),
    % Find all lines to flip
    findall(Line,
            (   direction(DeltaRow, DeltaCol),
                find_line(BoardWithPiece, Row, Col, DeltaRow, DeltaCol, Player, Line)
            ),
            Lines),
    % Flatten lines into list of positions
    flatten(Lines, Positions),
    % Flip all pieces
    flip_pieces(BoardWithPiece, Positions, Player, NewBoard),
    % Switch player
    (Player = black -> NextPlayer = white ; NextPlayer = black),
    NewState = state(NewBoard, NextPlayer).

apply_move(State, move(pass), NewState) :-
    State = state(Board, Player),
    \+ has_legal_move(Board, Player),
    (Player = black -> NextPlayer = white ; NextPlayer = black),
    NewState = state(Board, NextPlayer).

% Flip pieces
flip_pieces(Board, [], _Player, Board).
flip_pieces(Board, [Row-Col|Rest], Player, NewBoard) :-
    set_cell(Row, Col, Board, Player, UpdatedBoard),
    flip_pieces(UpdatedBoard, Rest, Player, NewBoard).

% Game over
game_over(state(Board, _), Winner) :-
    \+ has_legal_move(Board, black),
    \+ has_legal_move(Board, white),
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (   BlackCount > WhiteCount ->
        Winner = black
    ;   WhiteCount > BlackCount ->
        Winner = white
    ;   Winner = draw
    ).

% Count pieces
count_pieces(Board, Player, Count) :-
    flatten(Board, Cells),
    include(=(Player), Cells, PlayerCells),
    length(PlayerCells, Count).

% Render state
render_state(state(Board, Player)) :-
    format('Current player: ~w~n', [Player]),
    format('  1 2 3 4 5 6 7 8~n'),
    render_board_rows(Board, 1).

render_board_rows([], _).
render_board_rows([Row|Rows], N) :-
    format('~w ', [N]),
    render_board_row(Row),
    nl,
    N1 is N + 1,
    render_board_rows(Rows, N1).

render_board_row([]).
render_board_row([Cell|Cells]) :-
    (   Cell = empty ->
        format('. ')
    ;   format('~w ', [Cell])
    ),
    render_board_row(Cells).