:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list 8x8
% state(Board, CurrentPlayer)
% Board = [[Row1], [Row2], ..., [Row8]]
% CurrentPlayer = black | white

% Helper to set a cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Helper to get a cell value
get_cell(Board, Row, Col, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

% Initial state: 8x8 board with center pieces set
initial_state(state(Board, black)) :-
    EmptyRow = [empty, empty, empty, empty, empty, empty, empty, empty],
    Board0 = [EmptyRow, EmptyRow, EmptyRow, EmptyRow,
              EmptyRow, EmptyRow, EmptyRow, EmptyRow],
    % Set center pieces
    set_cell(4, 4, Board0, white, Board1),
    set_cell(4, 5, Board1, black, Board2),
    set_cell(5, 4, Board2, black, Board3),
    set_cell(5, 5, Board3, white, Board).

% Current player
current_player(state(_, Player), Player).

% Directions: 8 directions (row_delta, col_delta)
direction(-1, -1). direction(-1, 0). direction(-1, 1).
direction(0, -1).                  direction(0, 1).
direction(1, -1).  direction(1, 0).  direction(1, 1).

% Check if placing at (Row,Col) outflanks opponent in direction (DirRow,DirCol)
outflanks(Board, Player, Row, Col, DirRow, DirCol) :-
    % Opponent color
    (Player = black -> Opponent = white ; Opponent = black),
    % Move one step in direction
    NextRow is Row + DirRow,
    NextCol is Col + DirCol,
    % Check if next cell is opponent
    get_cell(Board, NextRow, NextCol, NextValue),
    NextValue = Opponent,
    % Continue in direction until we find a player piece
    outflank_line(Board, Player, NextRow, NextCol, DirRow, DirCol).

% Check a line for outflanking
outflank_line(Board, Player, Row, Col, DirRow, DirCol) :-
    NextRow is Row + DirRow,
    NextCol is Col + DirCol,
    get_cell(Board, NextRow, NextCol, Value),
    (Value = Player ->
        true
    ;
        Value = empty ->
        fail
    ;
        % Opponent piece, continue
        outflank_line(Board, Player, NextRow, NextCol, DirRow, DirCol)
    ).

% Find all outflanked positions when placing at (Row,Col)
find_outflanked(Board, Player, Row, Col, OutflankedPositions) :-
    findall(pos(R,C),
            (direction(DR, DC),
             outflanks(Board, Player, Row, Col, DR, DC),
             collect_line(Board, Player, Row, Col, DR, DC, R, C)),
            OutflankedPositions).

% Collect positions in a line that would be flipped
collect_line(Board, Player, Row, Col, DirRow, DirCol, OutRow, OutCol) :-
    NextRow is Row + DirRow,
    NextCol is Col + DirCol,
    get_cell(Board, NextRow, NextCol, Value),
    (Value = Player ->
        fail  % Stop when we reach player's piece
    ;
        Value \= empty ->
        OutRow = NextRow,
        OutCol = NextCol
    ;
        fail
    ).

% Continue collecting in the same direction
collect_line(Board, Player, Row, Col, DirRow, DirCol, OutRow, OutCol) :-
    NextRow is Row + DirRow,
    NextCol is Col + DirCol,
    get_cell(Board, NextRow, NextCol, Value),
    Value \= Player,
    Value \= empty,
    collect_line(Board, Player, NextRow, NextCol, DirRow, DirCol, OutRow, OutCol).

% Check if player has any legal move
has_legal_move(Board, Player) :-
    between(1, 8, Row),
    between(1, 8, Col),
    legal_placement(Board, Player, Row, Col),
    !.

% Check if placement is legal
legal_placement(Board, Player, Row, Col) :-
    get_cell(Board, Row, Col, empty),
    direction(DR, DC),
    outflanks(Board, Player, Row, Col, DR, DC),
    !.

% Legal move generator
legal_move(State, Move) :-
    State = state(Board, Player),
    % Try to find a legal placement
    findall(move(place, R, C),
            legal_placement(Board, Player, R, C),
            Placements),
    (Placements = [] ->
        % No placements, must pass
        Move = move(pass)
    ;
        % At least one placement exists, choose one
        member(Move, Placements)
    ).

% Apply move
apply_move(state(Board, Player), move(place, Row, Col), state(NewBoard, NextPlayer)) :-
    legal_placement(Board, Player, Row, Col),
    update_board(Board, Player, Row, Col, NewBoard),
    (Player = black -> NextPlayer = white ; NextPlayer = black).

apply_move(state(Board, Player), move(pass), state(Board, NextPlayer)) :-
    % Verify no legal moves exist
    \+ has_legal_move(Board, Player),
    (Player = black -> NextPlayer = white ; NextPlayer = black).

% Update board: place piece and flip outflanked pieces
update_board(Board, Player, Row, Col, FinalBoard) :-
    % Place the piece
    set_cell(Row, Col, Board, Player, BoardWithPiece),
    % Find all outflanked positions
    find_outflanked(BoardWithPiece, Player, Row, Col, Outflanked),
    % Flip them
    flip_pieces(BoardWithPiece, Outflanked, Player, FinalBoard).

% Flip a list of pieces
flip_pieces(Board, [], _, Board).
flip_pieces(Board, [pos(R,C)|Rest], Player, FinalBoard) :-
    set_cell(R, C, Board, Player, NewBoard),
    flip_pieces(NewBoard, Rest, Player, FinalBoard).

% Count pieces for a player
count_pieces(Board, Player, Count) :-
    flatten(Board, Flat),
    include(=(Player), Flat, PlayerPieces),
    length(PlayerPieces, Count).

% Game over conditions
game_over(state(Board, _), Winner) :-
    % Check if board is full
    flatten(Board, Flat),
    \+ member(empty, Flat),
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; BlackCount < WhiteCount ->
        Winner = white
    ;
        Winner = draw
    ).

game_over(state(Board, Player), Winner) :-
    % Check if current player must pass
    \+ has_legal_move(Board, Player),
    % Check if opponent must also pass
    (Player = black -> Opponent = white ; Opponent = black),
    \+ has_legal_move(Board, Opponent),
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; BlackCount < WhiteCount ->
        Winner = white
    ;
        Winner = draw
    ).

% Render state
render_state(state(Board, Player)) :-
    format('  1 2 3 4 5 6 7 8~n'),
    render_board_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

render_board_rows([], _).
render_board_rows([Row|Rows], N) :-
    format('~w ', [N]),
    render_row(Row),
    nl,
    N1 is N + 1,
    render_board_rows(Rows, N1).

render_row([]).
render_row([Cell|Rest]) :-
    (Cell = empty ->
        format('. ')
    ; Cell = black ->
        format('B ')
    ;
        format('W ')
    ),
    render_row(Rest).